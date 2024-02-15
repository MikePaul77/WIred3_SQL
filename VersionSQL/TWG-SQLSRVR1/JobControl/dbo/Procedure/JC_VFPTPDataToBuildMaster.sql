/****** Object:  Procedure [dbo].[JC_VFPTPDataToBuildMaster]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_VFPTPDataToBuildMaster @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	
	declare @LogSourceName varchar(100) = 'SP JobControl.JC_VFPTPDataToBuildMaster';
	declare @LogInfo varchar(500) = '';
	declare @goodparams bit = 1;

	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

-- ### Load all Job Control Parameters ### ===================================================================================
	declare @ImportJobStepID int = JobControl.dbo.GetJobStepParamInt(@JobStepID,'VFPImportedStepID'); 
	-- this is the StepID of the VFP Import and is needed becuse the data
	-- to be processed into BuildMaster is in VFP_TP_ImportData with this ID
	declare @VFPFileName varchar(50) = JobControl.dbo.GetJobStepParamString(@JobStepID, 'VFPFullFileName')
	declare @State varchar(10) = JobControl.dbo.GetJobStepParamString(@JobStepID, 'State')
	declare @IssueWeek varchar(50) = JobControl.dbo.GetJobStepParamString(@JobStepID, 'IssueWeek')

-- ### Test all Job Control Parameters ### ===================================================================================
	if @ImportJobStepID is null or @VFPFileName is null or @State is null or @IssueWeek is null
		set @goodparams = 0
	else
		begin
-- ### Log all Job Control Parameters ### ===================================================================================
			set @LogInfo = 'SP Param Get: ImportJobStepID = ' + convert(varchar(1),@ImportJobStepID);
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;
			set @LogInfo = 'SP Param Get: VFPFullFileName = ' + @VFPFileName;
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;
			set @LogInfo = 'SP Param Get: State = ' + @State;
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;
			set @LogInfo = 'SP Param Get: IssueWeek = ' + @IssueWeek;
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;
		end

	if @goodparams = 1
	begin
-- ### Start of working code ### ===================================================================================

	
	declare @JobID int;
	select @JobID = JobID
		from JobControl.dbo.JobSteps
		where StepID = @JobStepID;

	declare @BatchID int;
	select @BatchID = ID
		from QualityStaging.stg.Batches b
		where b.JobID = @JobID;

	if @BatchID is null
	begin
		
		set @VFPFileName = right(@VFPFileName,CHARINDEX('\',Reverse(@VFPFileName))-1)
		set @VFPFileName = replace(@VFPFileName,'.DBF','')

		insert QualityStaging.stg.Batches (BatchName, Process, State, IssueWeek, BatchDate, JobID)
			select @VFPFileName
					, 'TP'
					, @State
					, @IssueWeek
					, getdate()
					, @JobID

		set @BatchID = SCOPE_IDENTITY(); -- The New Batch ID			
	end;	

	declare @MaxStagingHeaderID int;
	select @MaxStagingHeaderID = case when max(id) is null  then 0 else max(id) end from  [QualityStaging].[stg].[StagingHeaders];

	delete QualityStaging.stg.BuildMasterTransactions where BatchID = ltrim(str(@BatchID));

	delete QualityStaging.stg.StagingHeaders where CleansingBatchID = @BatchID;

	With VFPTP as (select * from VFP_TP_ImportData where JC_JobStepID = @ImportJobStepID)
	insert QualityStaging.stg.BuildMasterTransactions (propid, source, siteid, tranid, miscid, credid, mapref, ccode, town, nostnum, street, stnum, stnumext, unit, lotcode, condoname, zipcode, plus4, cnsstract, cnssblgr, carrier_rt, owner1, phone, 
                         exactdate, stateuse, parcelid, pstreet, ostreet, fullname1, fullname2, buyer1, buyer2, buyerrel, seller1, seller2, sellerrel, date, price, validsale, saletype, deedtype, lender, lname, mortgage, interest, inttype, term, 
                         submtg, mtgcat, mtgassigne, extryear, extrweek, def1name, def2name, defrel, alias1, alias1code, plaintiff1, plaintiff2, sheratty, deposit, saledatetm, saleloc, origmortg, taxtype1, taxtype2, initdate, pubdate, pub, 
                         respdate, misctype, book, page, docketref, sellname, error, batchnum, filename, recnum, modidate, moditype, moditble, posted, posttime, matched, addrstats, szipped, ozipped, named, phoned, dedupeflag, 
                         revlend, revfd, taxed, adcpstreet, adcostreet, adcnames, adcdesc, incinrpt, addrstato, addrstatr, relage, adcresownr, oor_date, maprefed, taxbillnum, oldvalue, usesource, rcode, needresrch, useddate, addrrev, 
                         praddrsame, nomiid, nomsrce, saddrlevel, oaddrlevel, mtgdid, chngdate, intadj, mtgbook, mtgpage, mtgdocketr, indname, auccode, pfpubdate, aucstcode, aucstdate, saledtnew, attyphone, min, origid, origname, 
                         brokerid, brokern, fhava, trndid, signdate, signer, mtgaddid, doctype, origbook, origpage, origdoc, origdate, asnrlname, asnrlender, origmtg, archiveid, ownrid, assrid, bldgid, complevl, inactvfl, owner2, ownrel, 
                         resowner, salesrce, lstsldate, lstslpr, lstslvalid, lstsltype, lstddtype, lstbook, lstpage, lstdocref, lstmtgdate, lstmtg, lstldr, lstmtgcat, submtgflg, assdvaltot, lstinttype, assdvallnd, lstchgdate, assdvalbld, lstinterst, 
                         fy, lstintadj, taxamt, taxyear, taxdist, zoning, numbldgs, lotsize, lsunits, dpstatdate, dpstatus, lstnomdate, lstnombook, lstnompage, lstnomdocr, prefcode, sitesrce, dpinid, fspubdate, reodate, pubnumpf, 
                         pubnumfs, initdateln, pubfs, pubpf, ardpid, mersvalid, mersind, brr1id, brr2id, dspodate, contractdt, asnrsecid, asnesecid, asnrtrstee, asnetrstee, reclname, rtype, netfile, dsacctn, loannumber, asnepoolnm, 
                         mtgdsid, village, mailaddr, noimage, recnumber, mapbllot, repid, srcnetfile, assrsid, bpmtid, permitn, cost, cname, cntmailddr, permtype, pnotes, applicant, permowner, permsft, cphone, cslic, hicreg, cmailcity, 
                         cmailstate, cmailzip, lstsaleid, lstmtgid, secmtgid, lstnomiid, lat, lon
						 
						 , BatchId
						 , Skey)
	select propid, source, siteid, tranid, miscid, credid, mapref, ccode, town, nostnum, street, stnum, stnumext, unit, lotcode, condoname, zipcode, plus4, cnsstract, cnssblgr, carrier_rt, owner1, phone, 
                         exactdate, stateuse, parcelid, pstreet, ostreet, fullname1, fullname2, buyer1, buyer2, buyerrel, seller1, seller2, sellerrel, date, price, validsale, saletype, deedtype, lender, lname, mortgage, interest, inttype, term, 
                         submtg, mtgcat, mtgassigne, extryear, extrweek, def1name, def2name, defrel, alias1, alias1code, plaintiff1, plaintiff2, sheratty, deposit, saledatetm, saleloc, origmortg, taxtype1, taxtype2, initdate, pubdate, pub, 
                         respdate, misctype, book, page, docketref, sellname, error, batchnum, filename, recnum, modidate, moditype, moditble, posted, posttime, matched, addrstats, szipped, ozipped, named, phoned, dedupeflag, 
                         revlend, revfd, taxed, adcpstreet, adcostreet, adcnames, adcdesc, incinrpt, addrstato, addrstatr, relage, adcresownr, oor_date, maprefed, taxbillnum, oldvalue, usesource, rcode, needresrch, useddate, addrrev, 
                         praddrsame, nomiid, nomsrce, saddrlevel, oaddrlevel, mtgdid, chngdate, intadj, mtgbook, mtgpage, mtgdocketr, indname, auccode, pfpubdate, aucstcode, aucstdate, saledtnew, attyphone, min, origid, origname, 
                         brokerid, brokern, fhava, trndid, signdate, signer, mtgaddid, doctype, origbook, origpage, origdoc, origdate, asnrlname, asnrlender, origmtg, archiveid, ownrid, assrid, bldgid, complevl, inactvfl, owner2, ownrel, 
                         resowner, salesrce, lstsldate, lstslpr, lstslvalid, lstsltype, lstddtype, lstbook, lstpage, lstdocref, lstmtgdate, lstmtg, lstldr, lstmtgcat, submtgflg, assdvaltot, lstinttype, assdvallnd, lstchgdate, assdvalbld, lstinterst, 
                         fy, lstintadj, taxamt, taxyear, taxdist, zoning, numbldgs, lotsize, lsunits, dpstatdate, dpstatus, lstnomdate, lstnombook, lstnompage, lstnomdocr, prefcode, sitesrce, dpinid, fspubdate, reodate, pubnumpf, 
                         pubnumfs, initdateln, pubfs, pubpf, ardpid, mersvalid, mersind, brr1id, brr2id, dspodate, contractdt, asnrsecid, asnesecid, asnrtrstee, asnetrstee, reclname, rtype, netfile, dsacctn, loannumber, asnepoolnm, 
                         mtgdsid, village, mailaddr, noimage, recnumber, mapbllot, repid, srcnetfile, assrsid, bpmtid, permitn, cost, cname, cntmailddr, permtype, pnotes, applicant, permowner, permsft, cphone, cslic, hicreg, cmailcity, 
                         cmailstate, cmailzip, lstsaleid, lstmtgid, secmtgid, lstnomiid, lat, lon
						 
						 
						 , @BatchID
						 , @MaxStagingHeaderID + ROW_NUMBER() OVER(order by propid)
		from VFPTP;


	insert QualityStaging.stg.StagingHeaders (
				CleansingBatchID, Skey, FileName, VFP_RecNum, Netbook_RecNumber, VFP_PropID
				, ProcessType
				, RecordType
			)
	SELECT @BatchID, Skey, FileName, recnum, recnumber, propid
		, 'TP' ProcessType
		, case when source = 'C' and misctype in ('11','13','VB') then 'Bkrp'
				when source = 'C' and misctype in ('JF','P5','P6','P7','P8','CF','P2','P3','P1','F2','F3','P4','F4','FA','LP','PF','SS','FS') then 'Pref'
				when source = 'C' and misctype in ('ST','PP','EX','JD','LA','MT','SJ','FT','RE') then 'Lien'
				when source = 'S' then 'Sale'
				when source = 'M' then 'Mtg'
				when source = 'E' then 'Bpmt'
				when source = 'C' and misctype = 'DH' then 'DH'
				when source = 'D' and rtype = 'A' then 'Asgn'
				when source = 'D' and rtype = 'D' then 'Dsch'
			else 'Unkn' end RecordType

		  FROM QualityStaging.stg.BuildMasterTransactions bmt
		  where moditype <> 'D' ;


	update QualityStaging.stg.BuildMasterTransactions
		set origmortg = JobControl.dbo.VFPImportedDate_Cleanup(origmortg),
				initdate = JobControl.dbo.VFPImportedDate_Cleanup(initdate),
				pubdate = JobControl.dbo.VFPImportedDate_Cleanup(pubdate),
				respdate = JobControl.dbo.VFPImportedDate_Cleanup(respdate),
				modidate = JobControl.dbo.VFPImportedDate_Cleanup(modidate),
				posttime = JobControl.dbo.VFPImportedDate_Cleanup(posttime),
				oor_date = JobControl.dbo.VFPImportedDate_Cleanup(oor_date),
				useddate = JobControl.dbo.VFPImportedDate_Cleanup(useddate),
				chngdate = JobControl.dbo.VFPImportedDate_Cleanup(chngdate),
				pfpubdate = JobControl.dbo.VFPImportedDate_Cleanup(pfpubdate),
				saledtnew = JobControl.dbo.VFPImportedDate_Cleanup(saledtnew),
				signdate = JobControl.dbo.VFPImportedDate_Cleanup(signdate),
				lstsldate = JobControl.dbo.VFPImportedDate_Cleanup(lstsldate),
				lstmtgdate = JobControl.dbo.VFPImportedDate_Cleanup(lstmtgdate),
				lstchgdate = JobControl.dbo.VFPImportedDate_Cleanup(lstchgdate),
				dpstatdate = JobControl.dbo.VFPImportedDate_Cleanup(dpstatdate),
				lstnomdate = JobControl.dbo.VFPImportedDate_Cleanup(lstnomdate),
				reodate = JobControl.dbo.VFPImportedDate_Cleanup(reodate),
				fspubdate = JobControl.dbo.VFPImportedDate_Cleanup(fspubdate),
				initdateln = JobControl.dbo.VFPImportedDate_Cleanup(initdateln),
				dspodate = JobControl.dbo.VFPImportedDate_Cleanup(dspodate),
				contractdt = JobControl.dbo.VFPImportedDate_Cleanup(contractdt),
				aucstdate = JobControl.dbo.VFPImportedDate_Cleanup(aucstdate),
				[date] = JobControl.dbo.VFPImportedDate_Cleanup([date]),
				origdate = JobControl.dbo.VFPImportedDate_Cleanup(origdate)
		where BatchId = ltrim(str(@BatchID))

	-- Start Of Load StagingTP
		IF OBJECT_ID('tempdb..#bmt') IS NOT NULL DROP TABLE #bmt

		select case when propid =  ''   then NULL else CAST(propid AS float ) end AS propid,
				case when source =  ''   then NULL else CAST(source AS nvarchar(255) ) end AS source,
				case when Skey =  ''   then NULL else CAST(Skey AS int ) end AS Skey,
				case when siteid =  ''   then NULL else CAST(siteid AS float ) end AS siteid,
				case when tranid =  ''   then NULL else CAST(tranid AS float ) end AS tranid,
				case when miscid =  ''   then NULL else CAST(miscid AS float ) end AS miscid,
				case when credid =  ''   then NULL else CAST(credid AS float ) end AS credid,
				case when mapref =  ''   then NULL else CAST(mapref AS nvarchar(255) ) end AS mapref,
				case when ccode =  ''   then NULL else CAST(ccode AS nvarchar(255) ) end AS ccode,
				case when town =  ''   then NULL else CAST(town AS nvarchar(255) ) end AS town,
				case when nostnum =  ''   then NULL else CAST(nostnum AS bit ) end AS nostnum,
				case when street =  ''   then NULL else CAST(street AS nvarchar(255) ) end AS street,
				case when stnum =  ''   then NULL else CAST(stnum AS float ) end AS stnum,
				case when stnumext =  ''   then NULL else CAST(stnumext AS nvarchar(255) ) end AS stnumext,
				case when unit =  ''   then NULL else CAST(unit AS nvarchar(255) ) end AS unit,
				case when lotcode =  ''   then NULL else CAST(lotcode AS nvarchar(255) ) end AS lotcode,
				case when condoname =  ''   then NULL else CAST(condoname AS nvarchar(255) ) end AS condoname,
				case when zipcode =  ''   then NULL else CAST(zipcode AS nvarchar(255) ) end AS zipcode,
				case when plus4 =  ''   then NULL else CAST(plus4 AS nvarchar(255) ) end AS plus4,
				case when cnsstract =  ''   then NULL else CAST(cnsstract AS nvarchar(255) ) end AS cnsstract,
				case when cnssblgr =  ''   then NULL else CAST(cnssblgr AS nvarchar(255) ) end AS cnssblgr,
				case when carrier_rt =  ''   then NULL else CAST(carrier_rt AS nvarchar(255) ) end AS carrier_rt,
				case when owner1 =  ''   then NULL else CAST(owner1 AS nvarchar(255) ) end AS owner1,
				case when phone =  ''   then NULL else CAST(phone AS nvarchar(255) ) end AS phone,
				case when exactdate =  ''   then NULL else CAST(exactdate AS bit ) end AS exactdate,
				case when stateuse =  ''   then NULL else CAST(stateuse AS nvarchar(255) ) end AS stateuse,
				case when parcelid =  ''   then NULL else CAST(parcelid AS nvarchar(255) ) end AS parcelid,
				case when pstreet =  ''   then NULL else CAST(pstreet AS nvarchar(255) ) end AS pstreet,
				case when ostreet =  ''   then NULL else CAST(ostreet AS nvarchar(255) ) end AS ostreet,
				case when fullname1 =  ''   then NULL else CAST(fullname1 AS nvarchar(255) ) end AS fullname1,
				case when fullname2 =  ''   then NULL else CAST(fullname2 AS nvarchar(255) ) end AS fullname2,
				case when buyer1 =  ''   then NULL else CAST(buyer1 AS nvarchar(255) ) end AS buyer1,
				case when buyer2 =  ''   then NULL else CAST(buyer2 AS nvarchar(255) ) end AS buyer2,
				case when buyerrel =  ''   then NULL else CAST(buyerrel AS nvarchar(255) ) end AS buyerrel,
				case when seller1 =  ''   then NULL else CAST(seller1 AS nvarchar(255) ) end AS seller1,
				case when seller2 =  ''   then NULL else CAST(seller2 AS nvarchar(255) ) end AS seller2,
				case when sellerrel =  ''   then NULL else CAST(sellerrel AS nvarchar(255) ) end AS sellerrel,
				case when date =  ''   then NULL else CAST(date AS datetime ) end AS date,
				case when price =  ''   then NULL else CAST(price AS float ) end AS price,
				case when validsale =  ''   then NULL else CAST(validsale AS nvarchar(255) ) end AS validsale,
				case when saletype =  ''   then NULL else CAST(saletype AS nvarchar(255) ) end AS saletype,
				case when deedtype =  ''   then NULL else CAST(deedtype AS nvarchar(255) ) end AS deedtype,
				case when lender =  ''   then NULL else CAST(lender AS nvarchar(255) ) end AS lender,
				case when lname =  ''   then NULL else CAST(lname AS nvarchar(255) ) end AS lname,
				case when mortgage =  ''   then NULL else CAST(mortgage AS float ) end AS mortgage,
				case when interest =  ''   then NULL else CAST(interest AS float ) end AS interest,
				case when inttype =  ''   then NULL else CAST(inttype AS nvarchar(255) ) end AS inttype,
				case when term =  ''   then NULL else CAST(term AS float ) end AS term,
				case when submtg =  ''   then NULL else CAST(submtg AS nvarchar(255) ) end AS submtg,
				case when mtgcat =  ''   then NULL else CAST(mtgcat AS nvarchar(255) ) end AS mtgcat,
				case when mtgassigne =  ''   then NULL else CAST(mtgassigne AS nvarchar(255) ) end AS mtgassigne,
				case when extryear =  ''   then NULL else CAST(extryear AS nvarchar(255) ) end AS extryear,
				case when extrweek =  ''   then NULL else CAST(extrweek AS nvarchar(255) ) end AS extrweek,
				case when def1name =  ''   then NULL else CAST(def1name AS nvarchar(255) ) end AS def1name,
				case when def2name =  ''   then NULL else CAST(def2name AS nvarchar(255) ) end AS def2name,
				case when defrel =  ''   then NULL else CAST(defrel AS nvarchar(255) ) end AS defrel,
				case when alias1 =  ''   then NULL else CAST(alias1 AS nvarchar(255) ) end AS alias1,
				case when alias1code =  ''   then NULL else CAST(alias1code AS nvarchar(255) ) end AS alias1code,
				case when plaintiff1 =  ''   then NULL else CAST(plaintiff1 AS nvarchar(255) ) end AS plaintiff1,
				case when plaintiff2 =  ''   then NULL else CAST(plaintiff2 AS nvarchar(255) ) end AS plaintiff2,
				case when sheratty =  ''   then NULL else CAST(sheratty AS nvarchar(255) ) end AS sheratty,
				case when deposit =  ''   then NULL else CAST(deposit AS float ) end AS deposit,
				case when saledatetm =  ''   then NULL else CAST(saledatetm AS nvarchar(255) ) end AS saledatetm,
				case when saleloc =  ''   then NULL else CAST(saleloc AS nvarchar(255) ) end AS saleloc,
				case when origmortg =  ''   then NULL else CAST(origmortg AS nvarchar(255) ) end AS origmortg,
				case when taxtype1 =  ''   then NULL else CAST(taxtype1 AS nvarchar(255) ) end AS taxtype1,
				case when taxtype2 =  ''   then NULL else CAST(taxtype2 AS nvarchar(255) ) end AS taxtype2,
				case when initdate =  ''   then NULL else CAST(initdate AS nvarchar(255) ) end AS initdate,
				case when pubdate =  ''   then NULL else CAST(pubdate AS nvarchar(255) ) end AS pubdate,
				case when pub =  ''   then NULL else CAST(pub AS nvarchar(255) ) end AS pub,
				case when respdate =  ''   then NULL else CAST(respdate AS nvarchar(255) ) end AS respdate,
				case when misctype =  ''   then NULL else CAST(misctype AS nvarchar(255) ) end AS misctype,
				case when book =  ''   then NULL else CAST(book AS float ) end AS book,
				case when page =  ''   then NULL else CAST(page AS float ) end AS page,
				case when docketref =  ''   then NULL else CAST(docketref AS nvarchar(255) ) end AS docketref,
				case when sellname =  ''   then NULL else CAST(sellname AS nvarchar(255) ) end AS sellname,
				case when error =  ''   then NULL else CAST(error AS float ) end AS error,
				case when batchnum =  ''   then NULL else CAST(batchnum AS float ) end AS batchnum,
				case when filename =  ''   then NULL else CAST(filename AS nvarchar(255) ) end AS filename,
				case when recnum =  ''   then NULL else CAST(recnum AS float ) end AS recnum,
				case when modidate =  ''   then NULL else CAST(modidate AS datetime ) end AS modidate,
				case when moditype =  ''   then NULL else CAST(moditype AS nvarchar(255) ) end AS moditype,
				case when moditble =  ''   then NULL else CAST(moditble AS nvarchar(255) ) end AS moditble,
				case when posted =  ''   then NULL else CAST(posted AS bit ) end AS posted,
				case when posttime =  ''   then NULL else CAST(posttime AS nvarchar(255) ) end AS posttime,
				case when matched =  ''   then NULL else CAST(matched AS nvarchar(255) ) end AS matched,
				case when addrstats =  ''   then NULL else CAST(addrstats AS nvarchar(255) ) end AS addrstats,
				case when szipped =  ''   then NULL else CAST(szipped AS nvarchar(255) ) end AS szipped,
				case when ozipped =  ''   then NULL else CAST(ozipped AS nvarchar(255) ) end AS ozipped,
				case when named =  ''   then NULL else CAST(named AS nvarchar(255) ) end AS named,
				case when phoned =  ''   then NULL else CAST(phoned AS nvarchar(255) ) end AS phoned,
				case when dedupeflag =  ''   then NULL else CAST(dedupeflag AS nvarchar(255) ) end AS dedupeflag,
				case when revlend =  ''   then NULL else CAST(revlend AS nvarchar(255) ) end AS revlend,
				case when revfd =  ''   then NULL else CAST(revfd AS nvarchar(255) ) end AS revfd,
				case when taxed =  ''   then NULL else CAST(taxed AS nvarchar(255) ) end AS taxed,
				case when adcpstreet =  ''   then NULL else CAST(adcpstreet AS bit ) end AS adcpstreet,
				case when adcostreet =  ''   then NULL else CAST(adcostreet AS bit ) end AS adcostreet,
				case when adcnames =  ''   then NULL else CAST(adcnames AS bit ) end AS adcnames,
				case when adcdesc =  ''   then NULL else CAST(adcdesc AS bit ) end AS adcdesc,
				case when incinrpt =  ''   then NULL else CAST(incinrpt AS bit ) end AS incinrpt,
				case when addrstato =  ''   then NULL else CAST(addrstato AS nvarchar(255) ) end AS addrstato,
				case when addrstatr =  ''   then NULL else CAST(addrstatr AS nvarchar(255) ) end AS addrstatr,
				case when relage =  ''   then NULL else CAST(relage AS nvarchar(255) ) end AS relage,
				case when adcresownr =  ''   then NULL else CAST(adcresownr AS bit ) end AS adcresownr,
				case when oor_date =  ''   then NULL else CAST(oor_date AS nvarchar(255) ) end AS oor_date,
				case when maprefed =  ''   then NULL else CAST(maprefed AS nvarchar(255) ) end AS maprefed,
				case when taxbillnum =  ''   then NULL else CAST(taxbillnum AS nvarchar(255) ) end AS taxbillnum,
				case when oldvalue =  ''   then NULL else CAST(oldvalue AS nvarchar(255) ) end AS oldvalue,
				case when usesource =  ''   then NULL else CAST(usesource AS nvarchar(255) ) end AS usesource,
				case when rcode =  ''   then NULL else CAST(rcode AS nvarchar(255) ) end AS rcode,
				case when needresrch =  ''   then NULL else CAST(needresrch AS bit ) end AS needresrch,
				case when useddate =  ''   then NULL else CAST(useddate AS nvarchar(255) ) end AS useddate,
				case when addrrev =  ''   then NULL else CAST(addrrev AS nvarchar(255) ) end AS addrrev,
				case when praddrsame =  ''   then NULL else CAST(praddrsame AS nvarchar(255) ) end AS praddrsame,
				case when nomiid =  ''   then NULL else CAST(nomiid AS float ) end AS nomiid,
				case when nomsrce =  ''   then NULL else CAST(nomsrce AS nvarchar(255) ) end AS nomsrce,
				case when saddrlevel =  ''   then NULL else CAST(saddrlevel AS nvarchar(255) ) end AS saddrlevel,
				case when oaddrlevel =  ''   then NULL else CAST(oaddrlevel AS nvarchar(255) ) end AS oaddrlevel,
				case when mtgdid =  ''   then NULL else CAST(mtgdid AS float ) end AS mtgdid,
				case when chngdate =  ''   then NULL else CAST(chngdate AS nvarchar(255) ) end AS chngdate,
				case when intadj =  ''   then NULL else CAST(intadj AS float ) end AS intadj,
				case when mtgbook =  ''   then NULL else CAST(mtgbook AS float ) end AS mtgbook,
				case when mtgpage =  ''   then NULL else CAST(mtgpage AS float ) end AS mtgpage,
				case when mtgdocketr =  ''   then NULL else CAST(mtgdocketr AS nvarchar(255) ) end AS mtgdocketr,
				case when indname =  ''   then NULL else CAST(indname AS nvarchar(255) ) end AS indname,
				case when auccode =  ''   then NULL else CAST(auccode AS nvarchar(255) ) end AS auccode,
				case when pfpubdate =  ''   then NULL else CAST(pfpubdate AS nvarchar(255) ) end AS pfpubdate,
				case when aucstcode =  ''   then NULL else CAST(aucstcode AS nvarchar(255) ) end AS aucstcode,
				case when aucstdate =  ''   then NULL else CAST(aucstdate AS nvarchar(255) ) end AS aucstdate,
				case when saledtnew =  ''   then NULL else CAST(saledtnew AS nvarchar(255) ) end AS saledtnew,
				case when attyphone =  ''   then NULL else CAST(attyphone AS nvarchar(255) ) end AS attyphone,
				case when min =  ''   then NULL else CAST(min AS nvarchar(255) ) end AS min,
				case when origid =  ''   then NULL else CAST(origid AS nvarchar(255) ) end AS origid,
				case when origname =  ''   then NULL else CAST(origname AS nvarchar(255) ) end AS origname,
				case when brokerid =  ''   then NULL else CAST(brokerid AS nvarchar(255) ) end AS brokerid,
				case when brokern =  ''   then NULL else CAST(brokern AS nvarchar(255) ) end AS brokern,
				case when fhava =  ''   then NULL else CAST(fhava AS nvarchar(255) ) end AS fhava,
				case when trndid =  ''   then NULL else CAST(trndid AS float ) end AS trndid,
				case when signdate =  ''   then NULL else CAST(signdate AS datetime ) end AS signdate,
				case when signer =  ''   then NULL else CAST(signer AS nvarchar(255) ) end AS signer,
				case when mtgaddid =  ''   then NULL else CAST(mtgaddid AS float ) end AS mtgaddid,
				case when doctype =  ''   then NULL else CAST(doctype AS nvarchar(255) ) end AS doctype,
				case when origbook =  ''   then NULL else CAST(origbook AS float ) end AS origbook,
				case when origpage =  ''   then NULL else CAST(origpage AS float ) end AS origpage,
				case when origdoc =  ''   then NULL else CAST(origdoc AS nvarchar(255) ) end AS origdoc,
				case when origdate =  ''   then NULL else CAST(origdate AS nvarchar(255) ) end AS origdate,
				case when asnrlname =  ''   then NULL else CAST(asnrlname AS nvarchar(255) ) end AS asnrlname,
				case when asnrlender =  ''   then NULL else CAST(asnrlender AS nvarchar(255) ) end AS asnrlender,
				case when origmtg =  ''   then NULL else CAST(origmtg AS float ) end AS origmtg,
				case when archiveid =  ''   then NULL else CAST(archiveid AS float ) end AS archiveid,
				case when ownrid =  ''   then NULL else CAST(ownrid AS float ) end AS ownrid,
				case when assrid =  ''   then NULL else CAST(assrid AS float ) end AS assrid,
				case when bldgid =  ''   then NULL else CAST(bldgid AS float ) end AS bldgid,
				case when complevl =  ''   then NULL else CAST(complevl AS nvarchar(255) ) end AS complevl,
				case when inactvfl =  ''   then NULL else CAST(inactvfl AS nvarchar(255) ) end AS inactvfl,
				case when owner2 =  ''   then NULL else CAST(owner2 AS nvarchar(255) ) end AS owner2,
				case when ownrel =  ''   then NULL else CAST(ownrel AS nvarchar(255) ) end AS ownrel,
				case when resowner =  ''   then NULL else CAST(resowner AS nvarchar(255) ) end AS resowner,
				case when salesrce =  ''   then NULL else CAST(salesrce AS nvarchar(255) ) end AS salesrce,
				case when lstsldate =  ''   then NULL else CAST(lstsldate AS nvarchar(255) ) end AS lstsldate,
				case when lstslpr =  ''   then NULL else CAST(lstslpr AS float ) end AS lstslpr,
				case when lstslvalid =  ''   then NULL else CAST(lstslvalid AS nvarchar(255) ) end AS lstslvalid,
				case when lstsltype =  ''   then NULL else CAST(lstsltype AS nvarchar(255) ) end AS lstsltype,
				case when lstddtype =  ''   then NULL else CAST(lstddtype AS nvarchar(255) ) end AS lstddtype,
				case when lstbook =  ''   then NULL else CAST(lstbook AS float ) end AS lstbook,
				case when lstpage =  ''   then NULL else CAST(lstpage AS float ) end AS lstpage,
				case when lstdocref =  ''   then NULL else CAST(lstdocref AS nvarchar(255) ) end AS lstdocref,
				case when lstmtgdate =  ''   then NULL else CAST(lstmtgdate AS nvarchar(255) ) end AS lstmtgdate,
				case when lstmtg =  ''   then NULL else CAST(lstmtg AS float ) end AS lstmtg,
				case when lstldr =  ''   then NULL else CAST(lstldr AS nvarchar(255) ) end AS lstldr,
				case when lstmtgcat =  ''   then NULL else CAST(lstmtgcat AS nvarchar(255) ) end AS lstmtgcat,
				case when submtgflg =  ''   then NULL else CAST(submtgflg AS nvarchar(255) ) end AS submtgflg,
				case when assdvaltot =  ''   then NULL else CAST(assdvaltot AS float ) end AS assdvaltot,
				case when lstinttype =  ''   then NULL else CAST(lstinttype AS nvarchar(255) ) end AS lstinttype,
				case when assdvallnd =  ''   then NULL else CAST(assdvallnd AS float ) end AS assdvallnd,
				case when lstchgdate =  ''   then NULL else CAST(lstchgdate AS nvarchar(255) ) end AS lstchgdate,
				case when assdvalbld =  ''   then NULL else CAST(assdvalbld AS float ) end AS assdvalbld,
				case when lstinterst =  ''   then NULL else CAST(lstinterst AS float ) end AS lstinterst,
				case when fy =  ''   then NULL else CAST(fy AS nvarchar(255) ) end AS fy,
				case when lstintadj =  ''   then NULL else CAST(lstintadj AS float ) end AS lstintadj,
				case when taxamt =  ''   then NULL else CAST(taxamt AS float ) end AS taxamt,
				case when taxyear =  ''   then NULL else CAST(taxyear AS nvarchar(255) ) end AS taxyear,
				case when taxdist =  ''   then NULL else CAST(taxdist AS nvarchar(255) ) end AS taxdist,
				case when zoning =  ''   then NULL else CAST(zoning AS nvarchar(255) ) end AS zoning,
				case when numbldgs =  ''   then NULL else CAST(numbldgs AS float ) end AS numbldgs,
				case when lotsize =  ''   then NULL else CAST(lotsize AS float ) end AS lotsize,
				case when lsunits =  ''   then NULL else CAST(lsunits AS nvarchar(255) ) end AS lsunits,
				case when dpstatdate =  ''   then NULL else CAST(dpstatdate AS nvarchar(255) ) end AS dpstatdate,
				case when dpstatus =  ''   then NULL else CAST(dpstatus AS nvarchar(255) ) end AS dpstatus,
				case when lstnomdate =  ''   then NULL else CAST(lstnomdate AS nvarchar(255) ) end AS lstnomdate,
				case when lstnombook =  ''   then NULL else CAST(lstnombook AS float ) end AS lstnombook,
				case when lstnompage =  ''   then NULL else CAST(lstnompage AS float ) end AS lstnompage,
				case when lstnomdocr =  ''   then NULL else CAST(lstnomdocr AS nvarchar(255) ) end AS lstnomdocr,
				case when prefcode =  ''   then NULL else CAST(prefcode AS nvarchar(255) ) end AS prefcode,
				case when sitesrce =  ''   then NULL else CAST(sitesrce AS nvarchar(255) ) end AS sitesrce,
				case when dpinid =  ''   then NULL else CAST(dpinid AS float ) end AS dpinid,
				case when fspubdate =  ''   then NULL else CAST(fspubdate AS nvarchar(255) ) end AS fspubdate,
				case when reodate =  ''   then NULL else CAST(reodate AS nvarchar(255) ) end AS reodate,
				case when pubnumpf =  ''   then NULL else CAST(pubnumpf AS float ) end AS pubnumpf,
				case when pubnumfs =  ''   then NULL else CAST(pubnumfs AS float ) end AS pubnumfs,
				case when initdateln =  ''   then NULL else CAST(initdateln AS nvarchar(255) ) end AS initdateln,
				case when pubfs =  ''   then NULL else CAST(pubfs AS nvarchar(255) ) end AS pubfs,
				case when pubpf =  ''   then NULL else CAST(pubpf AS nvarchar(255) ) end AS pubpf,
				case when ardpid =  ''   then NULL else CAST(ardpid AS float ) end AS ardpid,
				case when mersvalid =  ''   then NULL else CAST(mersvalid AS nvarchar(255) ) end AS mersvalid,
				case when mersind =  ''   then NULL else CAST(mersind AS nvarchar(255) ) end AS mersind,
				case when brr1id =  ''   then NULL else CAST(brr1id AS nvarchar(255) ) end AS brr1id,
				case when brr2id =  ''   then NULL else CAST(brr2id AS nvarchar(255) ) end AS brr2id,
				case when dspodate =  ''   then NULL else CAST(dspodate AS nvarchar(255) ) end AS dspodate,
				case when contractdt =  ''   then NULL else CAST(contractdt AS nvarchar(255) ) end AS contractdt,
				case when asnrsecid =  ''   then NULL else CAST(asnrsecid AS float ) end AS asnrsecid,
				case when asnesecid =  ''   then NULL else CAST(asnesecid AS float ) end AS asnesecid,
				case when asnrtrstee =  ''   then NULL else CAST(asnrtrstee AS nvarchar(255) ) end AS asnrtrstee,
				case when asnetrstee =  ''   then NULL else CAST(asnetrstee AS nvarchar(255) ) end AS asnetrstee,
				case when reclname =  ''   then NULL else CAST(reclname AS nvarchar(255) ) end AS reclname,
				case when rtype =  ''   then NULL else CAST(rtype AS nvarchar(255) ) end AS rtype,
				case when netfile =  ''   then NULL else CAST(netfile AS nvarchar(255) ) end AS netfile,
				case when dsacctn =  ''   then NULL else CAST(dsacctn AS nvarchar(255) ) end AS dsacctn,
				case when loannumber =  ''   then NULL else CAST(loannumber AS nvarchar(255) ) end AS loannumber,
				case when asnepoolnm =  ''   then NULL else CAST(asnepoolnm AS nvarchar(255) ) end AS asnepoolnm,
				case when mtgdsid =  ''   then NULL else CAST(mtgdsid AS float ) end AS mtgdsid,
				case when village =  ''   then NULL else CAST(village AS nvarchar(255) ) end AS village,
				case when mailaddr =  ''   then NULL else CAST(mailaddr AS nvarchar(255) ) end AS mailaddr,
				case when noimage =  ''   then NULL else CAST(noimage AS bit ) end AS noimage,
				case when recnumber =  ''   then NULL else CAST(recnumber AS nvarchar(255) ) end AS recnumber,
				case when mapbllot =  ''   then NULL else CAST(mapbllot AS nvarchar(255) ) end AS mapbllot,
				case when repid =  ''   then NULL else CAST(repid AS nvarchar(255) ) end AS repid,
				case when srcnetfile =  ''   then NULL else CAST(srcnetfile AS nvarchar(255) ) end AS srcnetfile,
				case when assrsid =  ''   then NULL else CAST(assrsid AS float ) end AS assrsid,
				case when bpmtid =  ''   then NULL else CAST(bpmtid AS float ) end AS bpmtid,
				case when permitn =  ''   then NULL else CAST(permitn AS nvarchar(255) ) end AS permitn,
				case when cost =  ''   then NULL else CAST(cost AS float ) end AS cost,
				case when cname =  ''   then NULL else CAST(cname AS nvarchar(255) ) end AS cname,
				case when cntmailddr =  ''   then NULL else CAST(cntmailddr AS nvarchar(255) ) end AS cntmailddr,
				case when permtype =  ''   then NULL else CAST(permtype AS nvarchar(255) ) end AS permtype,
				case when pnotes =  ''   then NULL else CAST(pnotes AS nvarchar(255) ) end AS pnotes,
				case when applicant =  ''   then NULL else CAST(applicant AS nvarchar(255) ) end AS applicant,
				case when permowner =  ''   then NULL else CAST(permowner AS nvarchar(255) ) end AS permowner,
				case when permsft =  ''   then NULL else CAST(permsft AS float ) end AS permsft,
				case when cphone =  ''   then NULL else CAST(cphone AS nvarchar(255) ) end AS cphone,
				case when cslic =  ''   then NULL else CAST(cslic AS nvarchar(255) ) end AS cslic,
				case when hicreg =  ''   then NULL else CAST(hicreg AS nvarchar(255) ) end AS hicreg,
				case when cmailcity =  ''   then NULL else CAST(cmailcity AS nvarchar(25) ) end AS cmailcity,
				case when cmailstate =  ''   then NULL else CAST(cmailstate AS nvarchar(2) ) end AS cmailstate,
				case when cmailzip =  ''   then NULL else CAST(cmailzip AS nvarchar(6) ) end AS cmailzip,
				case when lstsaleid =  ''   then NULL else CAST(lstsaleid AS float ) end AS lstsaleid,
				case when lstmtgid =  ''   then NULL else CAST(lstmtgid AS float ) end AS lstmtgid,
				case when secmtgid =  ''   then NULL else CAST(secmtgid AS float ) end AS secmtgid,
				case when lstnomiid =  ''   then NULL else CAST(lstnomiid AS float ) end AS lstnomiid,
				case when lat =  ''   then NULL else CAST(lat AS float ) end AS lat,
				case when lon =  ''   then NULL else CAST(lon AS float ) end AS lon,
				case when BatchId =  ''   then NULL else CAST(BatchId AS nvarchar(50) ) end AS BatchId
				, convert(int, null) ParentID 

				, convert(int, case when mtgcat = 'D' then 1 else null end) LoanModification
				, convert(int, case when mtgcat = 'S' then 1 else null end) SubordinatedMtg
				, convert(int, case when mtgcat = 'B' then 1 else null end) BalloonMtg
				, convert(int, case when mtgcat = 'V' then 1 else null end) VAMtg
				, convert(int, case when mtgcat = 'F' then 1 else null end) FHAMtg
				, convert(int, case when mtgcat = 'G' then 1 else null end) GovtMtg
				, convert(int, case when mtgcat = 'C' then 1 else null end) CommercialMtg
				, convert(int, case when mtgcat = 'E' then 1 else null end) HomeEquityMtg
				, convert(int, case when mtgcat = 'H' then 1 else null end) HELOCMtg
				, convert(int, case when mtgcat = 'R' then 1 else null end) ReverseMtg
				, convert(int, case when mtgcat = 'I' then 1 else null end) ConsolidationMtg
				, convert(int, case when mtgcat = 'A' then 1 else null end) BridgeMtg


				, convert(varchar(10), case when source = 'C' and misctype in ('11','13','VB') then 'Bkrp'
					  when source = 'C' and misctype in ('JF','P5','P6','P7','P8','CF','P2','P3','P1'
														,'F2','F3','P4','F4','FA','LP','PF','SS','FS') then 'Pref'
					  when source = 'C' and misctype in ('ST','PP','EX','JD','LA','MT','SJ','FT') then 'Lien'
					  when source = 'S' and misctype in ('M') then 'Mtg'
					  when source = 'E' then 'Bpmt'
					  when source = 'C' and misctype = 'DH' then 'DH'
					  when source = 'C' and rtype = 'A' then 'Asgn'
					  when source = 'C' and rtype = 'D' then 'Dsch'
					  else 'Unkn' end) RecType

				, convert(bit,case when validsale = 'N' then 0
						when validsale = 'S' then 1 else NULL end) IsvalidSaleBinary

			into #bmt
		from QualityStaging.stg.BuildMasterTransactions bmt
		where BatchId = ltrim(str(@BatchID))

		update bmt set ParentID = sh.ID
			from #bmt bmt
				left outer join QualityStaging.stg.StagingHeaders sh on sh.SKey = bmt.SKey

		--Prop Records
			insert QualityStaging.stg.Addresses (ParentID, TypeOperation, TownCode, village
												, StreetCore, StreetNumber, StreetNumberExtension, UnitType, UnitNumber
												, Zip, Plus4, CarrierRoute, Latitude, Longitude
												, CensusTract, CensusBlock
												, AddressType, ComplexName
												, SKey)

			select ParentID, source, town, village
					, street, Stnum, stnumext, lotcode, unit
					, zipcode, plus4, carrier_rt, lat, lon
					, cnsstract, cnssblgr
					, 'A' AddressType, condoname
					, SKey
				from #bmt

		--Contr
			insert QualityStaging.stg.Addresses (ParentID, TypeOperation
												, SourceAddress, City, UnitType, Zip
												, State, AddressType, SKey)
			select ParentID, source
					, cntmailddr, cmailcity, lotcode, convert(nvarchar(6), cmailzip) [Copy of cmailzip]
					, cmailstate, 'C' AddressType, SKey
				from #bmt bmt
				where bmt.cntmailddr <> '' and cntmailddr <> 'FALSE' and bmt.source = 'E'


		--Plaintiff1
			insert QualityStaging.stg.Names (ParentId, SourceName, Role, SKey, NameRecordedOrder)
			select ParentID, plaintiff1, 'P' Role, SKey, 1 recorded 
				from #bmt bmt
				where plaintiff1 <> ''

			insert QualityStaging.stg.Names (ParentId, SourceName, Role, SKeyRelation, NameRecordedOrder)
			select ParentID, plaintiff2, 'P' Role, SKey, 2 recorded 
				from #bmt bmt
				where plaintiff1 <> '' and plaintiff2 <> ''


		--def1
			insert QualityStaging.stg.Names (ParentId, SourceName, Role, SKey, NameRecordedOrder, Relationship)
			select ParentID, def1name, 'D' Role, SKey, 1 recorded, defrel 
				from #bmt bmt
				where def1name <> ''

			insert QualityStaging.stg.Names (ParentId, SourceName, Role, SKeyRelation, NameRecordedOrder, Relationship)
			select ParentID, def2name, 'D' Role, SKey, 2 recorded, defrel 
				from #bmt bmt
				where def1name <> '' and def2name <> ''

		--seller1
			insert QualityStaging.stg.Names (ParentId, SourceName, Role, SKey, NameRecordedOrder, Relationship)
			select ParentID, seller1, 'S' Role, SKey, 1 recorded, sellerrel 
				from #bmt bmt
				where seller1 <> ''

			insert QualityStaging.stg.Names (ParentId, SourceName, Role, SKeyRelation, NameRecordedOrder, Relationship)
			select ParentID, seller2, 'S' Role, SKey, 2 recorded, sellerrel 
				from #bmt bmt
				where seller1 <> '' and seller2 <> ''

			--seller1 & buyer1
					insert QualityStaging.stg.Names (ParentId, SourceName, Role, SKey, NameRecordedOrder, Relationship)
					select ParentID, buyer1, 'B' Role, SKey, 1 recorded, buyerrel 
						from #bmt bmt
						where seller1 <> '' and buyer1 <> ''

					insert QualityStaging.stg.Names (ParentId, SourceName, Role, SKey, NameRecordedOrder, Relationship)
					select ParentID, buyer2, 'B' Role, SKey, 2 recorded, buyerrel 
						from #bmt bmt
						where seller1 <> '' and buyer1 <> '' and buyer2 <> ''

		--Buyer1
			insert QualityStaging.stg.Names (ParentId, SourceName, Role, SKeyRelation, NameRecordedOrder, Relationship)
			select ParentID, buyer1, 'B' Role, SKey, 1 recorded, defrel 
				from #bmt bmt
				where buyer1 <> ''

			insert QualityStaging.stg.Names (ParentId, SourceName, Role, SKeyRelation, NameRecordedOrder, Relationship)
			select ParentID, buyer2, 'B' Role, SKey, 2 recorded, buyerrel 
				from #bmt bmt
				where buyer1 <> '' and buyer2 <> ''

		--Contractor

			insert QualityStaging.stg.Names (ParentId, SourceName, Role, SKey, NameRecordedOrder)
			select ParentID, cname, 'C' Role, SKey, 1 recorded 
				from #bmt bmt
				where cname <> ''


		--Buyer Records
				IF OBJECT_ID('tempdb..#bmt_Buyers') IS NOT NULL DROP TABLE #bmt_Buyers

					select bmt.*
						into #bmt_Buyers
						from #bmt bmt
						where bmt.mailaddr <> '' and bmt.source <> 'E'

				--Buyer contractor?  MP Says contractor but think it should be contact
					-- MP Looks like never will have records since bmt_Buyers Source <> 'E'
					--		but this requires Source = 'E'
					insert QualityStaging.stg.Addresses (ParentID, TypeOperation
														, SourceAddress, City, Zip
														, State, AddressType, SKey)
					select ParentID, source
							, cntmailddr, cmailcity, convert(nvarchar(6), cmailzip) [Copy of cmailzip]
							, cmailstate, 'C' AddressType, SKey

						from #bmt_Buyers byrs
						where cntmailddr <> '' and cntmailddr <> 'FALSE' and source = 'E'
			
				-- Buyer B
					insert QualityStaging.stg.Addresses (ParentID, TypeOperation
														, SourceAddress, City, UnitType, Zip
														, State, AddressType, SKey)
					select ParentID, source
							, mailaddr, cmailcity, lotcode, convert(nvarchar(6), cmailzip) [Copy of cmailzip]
							, cmailstate, 'B' AddressType, SKey

						from #bmt_Buyers byrs
						where cntmailddr <> '' and cntmailddr <> 'FALSE' and source = 'E'
				
				-- Buyer P&B
						insert QualityStaging.stg.Addresses (ParentID, TypeOperation, TownCode, village
															, StreetCore, StreetNumber, StreetNumberExtension, UnitType, UnitNumber
															, Zip, Plus4
															, CensusTract, CensusBlock
															, AddressType, ComplexName
															, SKey)

						select ParentID, source, town, village
								, street, Stnum, stnumext, lotcode, unit
								, zipcode, plus4
								, cnsstract, cnssblgr
								, 'P' AddressType, condoname
								, SKey

						from #bmt_Buyers byrs
						where cntmailddr <> '' and cntmailddr <> 'FALSE' and source = 'E'

				IF OBJECT_ID('tempdb..#bmt_Buyers') IS NOT NULL DROP TABLE #bmt_Buyers

		-- Sales
			-- Sales without MTG
				insert QualityStaging.stg.Transactions(ParentID, Type, ProcessYear, ProcessWeek
														, FilingDate, Book, Page, DocumentNum
														, PublisherId, PublishDate, AttorneyPhone, Deposit
														, SignDate, StateUse, PermitParcelId, IsValidSale
														, TaxType1, TaxType2, NoImageAvailableFlag, Sourcefile
														, Skey, DeedType, SalePrice, SignerSource, SaleType)
					select ParentID, Source, extryear, extrweek
							,[date], book, page, docketref
							, pub, pubdate, attyphone, deposit
							, signdate, stateuse, parcelid, IsvalidSaleBinary
							, taxtype1, taxtype2, noimage, netfile
							, Skey, deedtype, price, signer,saletype
						from #bmt bmt
						where source = 'S'

			-- Sales in MTG
				insert QualityStaging.stg.Transactions(ParentID, Type, ProcessYear, ProcessWeek
														, FilingDate, Book, Page, DocumentNum
														, AssigneeSECId, AssigneeTrustee, AssigneePoolNum, ReceiverLenderName
														, AssignorSECId, AssignorTrustee, OriginalFilingDate, OriginalBook, OriginalPage

														, OriginalDocumentNum, LoanNumber, PreForeclosureTypeID
														, PublisherId, PublishDate, AttorneyPhone, Deposit
														, AuctionDateTime, AuctionDateTimeNew, AuctionStatusId, AuctionStatusDate, AuctioneerId, OriginalMtgDate
														, MtgPayoffDate, MersNumber, SignDate, PurchaseMoneyMortgage

														, MtgTerm, Interest , InterestChangeDate, InterestAdjustment, IndexName, MortgageBrokerName
														, MtgOriginatorCode, MtgOriginatorName, LoanModification, SubordinatedMtg
														, BalloonMtg, VAMtg, FHAMtg, FHAVANumber, GovtMtg, CommercialMtg
														, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg, BridgeMtg

														, MiscLenderName, StateUse, PermitParcelId, ApplicantName, PermitOwnerName
														, IsValidSale, TaxType1, TaxType2, NoImageAvailableFlag, ModificationDate
														, MtgAmount, Sourcefile, DeedType, LenderCode, SignerSource
														, SaleType, InterestTypeCode, SkeyRelationship, MortgageBrokerCode)

					select ParentID, 'M', extryear, extrweek
							,[date], mtgbook, mtgpage, mtgdocketr
							, asnesecid, asnetrstee, asnepoolnm, reclname
							, asnrsecid, asnrtrstee, origdate, origbook, origpage

							, origdoc, loannumber, misctype
							, pub, pubdate, attyphone, deposit
							, saledatetm, saledtnew, aucstcode, aucstdate, auccode, origmortg
							, dspodate, [min], signdate, convert(bit,1) PurchaseMoneyMortgage

							, term, interest, chngdate, intadj, indname, brokern
							, origid, origname, LoanModification, SubordinatedMtg
							, BalloonMtg, VAMtg, FHAMtg, fhava, GovtMtg, CommercialMtg
							, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg, BridgeMtg

							, lname, stateuse, parcelid, applicant, permowner
							, IsvalidSaleBinary, taxtype1, taxtype2, noimage, modidate
							, mortgage, netfile, deedtype, lender, signer
							, saletype, inttype, Skey, brokerid
							
						from #bmt bmt
						where source = 'S'
							and mortgage <> 0

		-- Rest
			-- Bankupcy
				insert QualityStaging.stg.Transactions(ParentID, Type, ProcessYear, ProcessWeek
														, FilingDate, Book, Page, DocumentNum, Chapter
														, AssigneeSECId, AssigneeTrustee, AssigneePoolNum, ReceiverLenderName, AssignorMiscLenderName
														, AssignorSECId, AssignorTrustee, OriginalFilingDate, OriginalBook, OriginalPage
														, OriginalDocumentNum, LoanNumber
														
														, PublisherId, PublishDate, AttorneyPhone, Deposit
														, AuctionDateTime, AuctionDateTimeNew, AuctionStatusId, AuctionStatusDate
														, AuctioneerId, OriginalMtgDate, MtgPayoffDate, MersNumber
														, MtgTerm, Interest, InterestChangeDate, InterestAdjustment

														, IndexName, MortgageBrokerId, MortgageBrokerName, MtgOriginatorCode
														, MtgOriginatorName, LoanModification, SubordinatedMtg, BalloonMtg
														, VAMtg, FHAMtg, FHAVANumber, GovtMtg, CommercialMtg
														, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

														, BridgeMtg, MiscLenderName, StateUse, PermitParcelId
														, ApplicantName, PermitOwnerName, IsValidSale
														, TaxType1, TaxType2, NoImageAvailableFlag, ModificationDate
														, MtgAmount, Sourcefile, Skey, DeedType

														, AssigneeLenderCode, AssignorLenderCode, LenderCode, SalePrice
														, TransactionType, SignerSource, SaleType, InterestTypeCode)

					select ParentID, Source, extryear, extrweek
							, [date], book, page, docketref, bc.Code
							, asnesecid, asnetrstee, asnepoolnm, reclname, asnrlname
							, asnrsecid, asnrtrstee, origdate, origbook, origpage
							, origdoc, loannumber

							, pub, pubdate, attyphone, deposit
							, saledatetm, saledtnew, aucstcode, aucstdate
							, auccode, origmortg, dspodate, [min]
							, term, interest, chngdate, intadj
							
							, indname, brokerid, brokern, origid
							, origname, LoanModification, SubordinatedMtg, BalloonMtg
							, VAMtg, FHAMtg, fhava, GovtMtg, CommercialMtg
							, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

							, BridgeMtg, lname, stateuse, parcelid
							, applicant, permowner, IsvalidSaleBinary
							, taxtype1, taxtype2, noimage, modidate
							, mortgage, netfile, Skey, deedtype

							, mtgassigne, asnrlender, lender, price
							, misctype, signer, saletype, inttype

						from #bmt bmt
							left outer join Lookups.dbo.BankruptcyChapters bc on bc.VFPcode = bmt.misctype
						where source = 'C' and misctype in ('11', '13', 'VB')
			-- DH
				insert QualityStaging.stg.Transactions(ParentID, Type, ProcessYear, ProcessWeek
														, FilingDate, Book, Page, DocumentNum
														, SignDate, MiscLenderName, StateUse, IsValidSale
														, NoImageAvailableFlag, ModificationDate, Sourcefile, Skey
														
														, LenderCode, SalePrice, TransactionType, SignerSource
														, SaleType, DischargeContractDate)

					select ParentID, Source, extryear, extrweek
							, [date], book, page, docketref
							, signdate, lname, stateuse, IsvalidSaleBinary
							, noimage, modidate, netfile, Skey
							
							, lender, price, misctype, signer
							, saletype, contractdt

						from #bmt bmt
						where source = 'C' and misctype = 'DH'
			-- Mortgages
				insert QualityStaging.stg.Transactions(ParentID, Type, ProcessYear, ProcessWeek
														, FilingDate, Book, Page, DocumentNum
														, AssigneeSECId, AssigneeTrustee, AssigneePoolNum, ReceiverLenderName
														, AssignorSECId, AssignorTrustee, OriginalFilingDate, OriginalBook, OriginalPage
														, OriginalDocumentNum, LoanNumber, PreForeclosureTypeID
														
														, PublisherId, PublishDate, AttorneyPhone, Deposit
														, AuctionDateTime, AuctionDateTimeNew, AuctionStatusId, AuctionStatusDate
														, AuctioneerId, OriginalMtgDate, MtgPayoffDate, MersNumber
														, MtgTerm, Interest, InterestChangeDate, InterestAdjustment

														, IndexName, MortgageBrokerName, MtgOriginatorCode
														, MtgOriginatorName, LoanModification, SubordinatedMtg, BalloonMtg
														, VAMtg, FHAMtg, FHAVANumber, GovtMtg, CommercialMtg
														, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

														, BridgeMtg, MiscLenderName, StateUse, PermitParcelId
														, ApplicantName, PermitOwnerName, IsValidSale
														, TaxType1, TaxType2, NoImageAvailableFlag, ModificationDate
														, MtgAmount, Sourcefile, Skey, DeedType

														, LenderCode, SalePrice, SaleType, InterestTypeCode, MortgageBrokerCode)

					select ParentID, Source, extryear, extrweek
							, [date], book, page, docketref
							, asnesecid, asnetrstee, asnepoolnm, reclname
							, asnrsecid, asnrtrstee, origdate, origbook, origpage
							, origdoc, loannumber, misctype

							, pub, pubdate, attyphone, deposit
							, saledatetm, saledtnew, aucstcode, aucstdate
							, auccode, origmortg, dspodate, [min]
							, term, interest, chngdate, intadj
							
							, indname, brokern, origid
							, origname, LoanModification, SubordinatedMtg, BalloonMtg
							, VAMtg, FHAMtg, fhava, GovtMtg, CommercialMtg
							, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

							, BridgeMtg, lname, stateuse, parcelid
							, applicant, permowner, IsvalidSaleBinary
							, taxtype1, taxtype2, noimage, modidate
							, mortgage, netfile, Skey, deedtype

							, lender, price, saletype, inttype, brokerid

						from #bmt bmt
						where source = 'M'
			-- PF with Lawyer
				insert QualityStaging.stg.Transactions(ParentID, Type, ProcessYear, ProcessWeek
														, FilingDate, Book, Page, DocumentNum
														, AssigneeSECId, AssigneeTrustee, AssigneePoolNum, ReceiverLenderName, AssignorMiscLenderName
														, AssignorSECId, AssignorTrustee, OriginalFilingDate, OriginalBook, OriginalPage
														, OriginalDocumentNum, LoanNumber
														
														, PublishDate, AttorneyPhone, Deposit
														, AuctionDateTime, AuctionDateTimeNew, AuctionStatusId, AuctionStatusDate
														, AuctioneerId, OriginalMtgDate, MtgPayoffDate, MersNumber, SignDate
														, MtgTerm, Interest, InterestChangeDate, InterestAdjustment

														, IndexName, MortgageBrokerId, MortgageBrokerName, MtgOriginatorCode
														, MtgOriginatorName, LoanModification, SubordinatedMtg, BalloonMtg
														, VAMtg, FHAMtg, FHAVANumber, GovtMtg, CommercialMtg
														, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

														, BridgeMtg, MiscLenderName, StateUse, PermitParcelId
														, ApplicantName, PermitOwnerName, IsValidSale
														, TaxType1, TaxType2, NoImageAvailableFlag, ModificationDate
														, MtgAmount, Sourcefile, Skey, DeedType

														, AssigneeLenderCode, AssignorLenderCode, LenderCode, SalePrice
														, TransactionType, SignerSource, SaleType, InterestTypeCode, PublisherCode)

					select ParentID, Source, extryear, extrweek
							, [date], book, page, docketref
							, asnesecid, asnetrstee, asnepoolnm, reclname, asnrlname
							, asnrsecid, asnrtrstee, origdate, origbook, origpage
							, origdoc, loannumber

							, pubdate, attyphone, deposit
							, saledatetm, saledtnew, aucstcode, aucstdate
							, auccode, origmortg, dspodate, [min], signdate
							, term, interest, chngdate, intadj
							
							, indname, brokerid, brokern, origid
							, origname, LoanModification, SubordinatedMtg, BalloonMtg
							, VAMtg, FHAMtg, fhava, GovtMtg, CommercialMtg
							, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

							, BridgeMtg, lname, stateuse, parcelid
							, applicant, permowner, IsvalidSaleBinary
							, taxtype1, taxtype2, noimage, modidate
							, mortgage, netfile, Skey, deedtype

							, mtgassigne, asnrlender, lender, price
							, misctype, signer, saletype, inttype, pub

						from #bmt bmt
						where source = 'C' and misctype in ('P2', 'P3', 'P1', 'F2', 'F3', 'P4', 'F4', 'SS')
			-- PF without Lawyer
				insert QualityStaging.stg.Transactions(ParentID, Type, ProcessYear, ProcessWeek
														, FilingDate, Book, Page, DocumentNum
														, AssigneeSECId, AssigneeTrustee, AssigneePoolNum, ReceiverLenderName, AssignorMiscLenderName
														, AssignorSECId, AssignorTrustee, OriginalFilingDate, OriginalBook, OriginalPage
														, OriginalDocumentNum, LoanNumber
														
														, PublishDate, AttorneyPhone, Deposit
														, AuctionDateTime, AuctionDateTimeNew, AuctionStatusId, AuctionStatusDate
														, AuctioneerId, OriginalMtgDate, MtgPayoffDate, MersNumber, SignDate
														, MtgTerm, Interest, InterestChangeDate, InterestAdjustment

														, IndexName, MortgageBrokerId, MortgageBrokerName, MtgOriginatorCode
														, MtgOriginatorName, LoanModification, SubordinatedMtg, BalloonMtg
														, VAMtg, FHAMtg, FHAVANumber, GovtMtg, CommercialMtg
														, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

														, BridgeMtg, MiscLenderName, StateUse, PermitParcelId
														, ApplicantName, PermitOwnerName, IsValidSale
														, TaxType1, TaxType2, NoImageAvailableFlag, ModificationDate
														, MtgAmount, Sourcefile, Skey, DeedType

														, AssigneeLenderCode, AssignorLenderCode, LenderCode, SalePrice
														, TransactionType, SignerSource, SaleType, InterestTypeCode, PublisherCode)

					select ParentID, Source, extryear, extrweek
							, [date], book, page, docketref
							, asnesecid, asnetrstee, asnepoolnm, reclname, asnrlname
							, asnrsecid, asnrtrstee, origdate, origbook, origpage
							, origdoc, loannumber

							, pubdate, attyphone, deposit
							, saledatetm, saledtnew, aucstcode, aucstdate
							, auccode, origmortg, dspodate, [min], signdate
							, term, interest, chngdate, intadj
							
							, indname, brokerid, brokern, origid
							, origname, LoanModification, SubordinatedMtg, BalloonMtg
							, VAMtg, FHAMtg, fhava, GovtMtg, CommercialMtg
							, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

							, BridgeMtg, lname, stateuse, parcelid
							, applicant, permowner, IsvalidSaleBinary
							, taxtype1, taxtype2, noimage, modidate
							, mortgage, netfile, Skey, deedtype

							, mtgassigne, asnrlender, lender, price
							, misctype, signer, saletype, inttype, pub

						from #bmt bmt
						where source = 'C' and misctype in ('JF', 'P5', 'P6', 'P7', 'P8', 'CF', 'F4', 'FA', 'LP', 'PF', 'FS')
			-- Bmpt
				insert QualityStaging.stg.Transactions(ParentID, Type, ProcessYear, ProcessWeek
														, FilingDate, Book, Page, DocumentNum
														, PublisherCode, PublishDate, SignDate
														, StateUse, PermitParcelId, PermitNum, PermitTypeID

														, Valuation, PermitFee, WorkSquareFootage
														, ApplicantName, PermitOwnerName, NoImageAvailableFlag, ModificationDate
														, MtgAmount, Sourcefile, Skey, DeedType
														, TransactionType, SignerSource, SaleType, PermitNotes)

					select ParentID, Source, extryear, extrweek
							, [date], book, page, docketref
							, pub, pubdate, signdate
							, stateuse, parcelid, permitn, permtype

							, price, cost, permsft 
							, applicant, permowner, noimage, modidate
							, mortgage, netfile, Skey, deedtype
							, misctype, signer, saletype, pnotes

						from #bmt bmt
						where source = 'E'
			-- Lien
				insert QualityStaging.stg.Transactions(ParentID, Type, ProcessYear, ProcessWeek
														, FilingDate, Book, Page, DocumentNum
														, AssigneeSECId, AssigneeTrustee, AssigneePoolNum, ReceiverLenderName, AssignorMiscLenderName
														, AssignorSECId, AssignorTrustee, OriginalFilingDate, OriginalBook, OriginalPage
														, OriginalDocumentNum, LoanNumber
														
														, PublisherId, PublishDate, AttorneyPhone, Deposit
														, AuctionDateTime, AuctionDateTimeNew, AuctionStatusId, AuctionStatusDate
														, AuctioneerId, OriginalMtgDate, MtgPayoffDate, MersNumber, SignDate
														, MtgTerm, Interest, InterestChangeDate, InterestAdjustment

														, IndexName, MortgageBrokerId, MortgageBrokerName, MtgOriginatorCode
														, MtgOriginatorName, LoanModification, SubordinatedMtg, BalloonMtg
														, VAMtg, FHAMtg, FHAVANumber, GovtMtg, CommercialMtg
														, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

														, BridgeMtg, MiscLenderName, StateUse, PermitParcelId
														, ApplicantName, PermitOwnerName, IsValidSale
														, TaxType1, TaxType2, NoImageAvailableFlag, ModificationDate
														, MtgAmount, Sourcefile, Skey, DeedType

														, AssigneeLenderCode, AssignorLenderCode, LenderCode
														, TransactionType, SignerSource, SaleType, InterestTypeCode, DischargeContractDate)

					select ParentID, Source, extryear, extrweek
							, [date], book, page, docketref
							, asnesecid, asnetrstee, asnepoolnm, reclname, asnrlname
							, asnrsecid, asnrtrstee, origdate, origbook, origpage
							, origdoc, loannumber

							, pub, pubdate, attyphone, deposit
							, saledatetm, saledtnew, aucstcode, aucstdate
							, auccode, origmortg, dspodate, [min], signdate
							, term, interest, chngdate, intadj
							
							, indname, brokerid, brokern, origid
							, origname, LoanModification, SubordinatedMtg, BalloonMtg
							, VAMtg, FHAMtg, fhava, GovtMtg, CommercialMtg
							, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

							, BridgeMtg, lname, stateuse, parcelid
							, applicant, permowner, IsvalidSaleBinary
							, taxtype1, taxtype2, noimage, modidate
							, mortgage, netfile, Skey, deedtype

							, mtgassigne, asnrlender, lender
							, misctype, signer, saletype, inttype, contractdt

						from #bmt bmt
						where source = 'C' and misctype in ('ST', 'PP', 'EX', 'JD', 'LA', 'MT', 'SJ', 'FT', 'RE')
			-- Assignmnents
				insert QualityStaging.stg.Transactions(ParentID, Type, ProcessYear, ProcessWeek
														, FilingDate, Book, Page, DocumentNum
														, AssigneeSECId, AssigneeTrustee, AssigneePoolNum, ReceiverLenderName, AssignorMiscLenderName
														, AssignorSECId, AssignorTrustee, OriginalFilingDate, OriginalBook, OriginalPage
														, OriginalDocumentNum, LoanNumber
														
														, PublisherId, PublishDate, AttorneyPhone, Deposit
														, AuctionDateTime, AuctionDateTimeNew, AuctionStatusId, AuctionStatusDate
														, AuctioneerId, OriginalMtgDate, MtgPayoffDate, MersNumber, SignDate
														, MtgTerm, Interest, InterestChangeDate, InterestAdjustment

														, IndexName, MortgageBrokerId, MortgageBrokerName, MtgOriginatorCode
														, MtgOriginatorName, LoanModification, SubordinatedMtg, BalloonMtg
														, VAMtg, FHAMtg, FHAVANumber, GovtMtg, CommercialMtg
														, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

														, BridgeMtg, StateUse, PermitParcelId
														, ApplicantName, PermitOwnerName, IsValidSale
														, TaxType1, TaxType2, NoImageAvailableFlag, ModificationDate
														, MtgAmount, Sourcefile, Skey, DeedType

														, AssigneeLenderCode, AssignorLenderCode, SalePrice
														, TransactionType, SignerSource, SaleType, InterestTypeCode
														, AssigneeMiscLenderName, DischargeContractDate)

					select ParentID, Source, extryear, extrweek
							, [date], book, page, docketref
							, asnesecid, asnetrstee, asnepoolnm, reclname, asnrlname
							, asnrsecid, asnrtrstee, origdate, origbook, origpage
							, origdoc, loannumber

							, pub, pubdate, attyphone, deposit
							, saledatetm, saledtnew, aucstcode, aucstdate
							, auccode, origmortg, dspodate, [min], signdate
							, term, interest, chngdate, intadj
							
							, indname, brokerid, brokern, origid
							, origname, LoanModification, SubordinatedMtg, BalloonMtg
							, VAMtg, FHAMtg, fhava, GovtMtg, CommercialMtg
							, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

							, BridgeMtg, stateuse, parcelid
							, applicant, permowner, IsvalidSaleBinary
							, taxtype1, taxtype2, noimage, modidate
							, mortgage, netfile, Skey, deedtype

							, lender, asnrlender, price
							, misctype, signer, saletype, inttype
							, lname, contractdt

						from #bmt bmt
						where source = 'D' and rtype = 'A'
			-- Discharges
				insert QualityStaging.stg.Transactions(ParentID, Type, ProcessYear, ProcessWeek
														, FilingDate, Book, Page, DocumentNum
														, AssigneeSECId, AssigneeTrustee, AssigneePoolNum, ReceiverLenderName
														, AssignorSECId, AssignorTrustee, OriginalFilingDate, OriginalBook, OriginalPage
														, OriginalDocumentNum, LoanNumber
														
														, PublisherId, PublishDate, AttorneyPhone, Deposit
														, AuctionDateTime, AuctionDateTimeNew, AuctionStatusId, AuctionStatusDate
														, AuctioneerId, OriginalMtgDate, MtgPayoffDate, MersNumber, SignDate
														, MtgTerm, Interest, InterestChangeDate, InterestAdjustment

														, IndexName, MortgageBrokerId, MortgageBrokerName, MtgOriginatorCode
														, MtgOriginatorName, LoanModification, SubordinatedMtg, BalloonMtg
														, VAMtg, FHAMtg, FHAVANumber, GovtMtg, CommercialMtg
														, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

														, BridgeMtg, StateUse, PermitParcelId
														, ApplicantName, PermitOwnerName, IsValidSale
														, TaxType1, TaxType2, NoImageAvailableFlag, ModificationDate
														, MtgAmount, Sourcefile, Skey, DeedType

														, AssigneeLenderCode, SalePrice
														, TransactionType, SignerSource, SaleType, InterestTypeCode
														, DischargeContractDate, DischargeMiscLenderName)

					select ParentID, Source, extryear, extrweek
							, [date], book, page, docketref
							, asnesecid, asnetrstee, asnepoolnm, reclname
							, asnrsecid, asnrtrstee, origdate, origbook, origpage
							, origdoc, loannumber

							, pub, pubdate, attyphone, deposit
							, saledatetm, saledtnew, aucstcode, aucstdate
							, auccode, origmortg, dspodate, [min], signdate
							, term, interest, chngdate, intadj
							
							, indname, brokerid, brokern, origid
							, origname, LoanModification, SubordinatedMtg, BalloonMtg
							, VAMtg, FHAMtg, fhava, GovtMtg, CommercialMtg
							, HomeEquityMtg, HELOCMtg, ReverseMtg, ConsolidationMtg

							, BridgeMtg, stateuse, parcelid
							, applicant, permowner, IsvalidSaleBinary
							, taxtype1, taxtype2, noimage, modidate
							, mortgage, netfile, Skey, deedtype

							, lender, price
							, misctype, signer, saletype, inttype
							, contractdt, lname

						from #bmt bmt
						where source = 'D' and rtype = 'D'

		-- drop table #bmt
		IF OBJECT_ID('tempdb..#bmt') IS NOT NULL DROP TABLE #bmt
	-- End Of Load StagingTP

	-- Modd Signer Data
		update QualityStaging.stg.transactions
					set signername = (select left(sub.part_value,100) 
											from WG_Management..fn_GetStringExpressionParts(trd.SignerSource,'!',1,1) sub)
					, SignerTitle = (select left(sub.part_value,50) 
											from WG_Management..fn_GetStringExpressionParts(trd.SignerSource,'!',1,2) sub)
					, SignerOrganization = (select left(sub.part_value,50) 
												from WG_Management..fn_GetStringExpressionParts(trd.SignerSource,'!',1,3) sub)
					from QualityStaging.stg.transactions trd 
						inner join QualityStaging.stg.StagingHeaders stg on trd.ParentId = stg.id 
						inner join QualityStaging.stg.Batches bch on bch.id = stg.CleansingBatchID
					where bch.ID = @BatchID 

	-- Update ZZZ
		update QualityStaging.stg.Addresses
				set streetcore = NULL 
				from QualityStaging.stg.Addresses a
					inner join QualityStaging.stg.StagingHeaders h on h.id = a.ParentId
					inner join QualityStaging.stg.batches b on h.CleansingBatchID = b.id and b.ID = @BatchID 
				where streetcore = 'ZZZ'

	-- County and Registry
		update QualityStaging.stg.Addresses
				set RegistryId = twns.RegistryId,
					CountyId = twns.CountyId,
					STATE = twns.state
				from QualityStaging.stg.Addresses stga 
					inner join Lookups..Towns twns on stga.towncode = twns.code
					inner join QualityStaging.stg.StagingHeaders  stgh on stgh.id = stga.ParentId
					inner join QualityStaging.stg.batches b on stgh.cleansingbatchid = b.id
				where b.ID = @BatchID

	-- Load StagingHeaders
		insert QualityStaging.stg.StagingHeaders (CleansingBatchID, MovedToResearch, CycleProcess, Postable
													, PostedDate, ProcessType, Deleted, Skey, RecordType
													, FileName, Notes, VFP_RecNum, Netbook_RecNumber
													, ClonedFrom, Posted, VFP_PropID )

			select h.CleansingBatchID, h.MovedToResearch, h.CycleProcess, h.Postable
					, h.PostedDate, h.ProcessType, h.Deleted, h.Skey, 'Mtg' RecordType
					, h.FileName, h.Notes, h.VFP_RecNum, h.Netbook_RecNumber
					, h.ClonedFrom, h.Posted, h.VFP_PropID
				from QualityStaging.stg.Transactions t
					inner join QualityStaging.stg.StagingHeaders h on t.ParentId = h.id 
				where t.PurchaseMoneyMortgage = 1
					and CleansingBatchID = @BatchID

	-- Update headers MTG

		update qualitystaging.stg.transactions
			set parentid = h.id  
			from qualitystaging.stg.StagingHeaders h
				inner join qualitystaging.stg.transactions t on h.skey = t.SkeyRelationship 
			where RecordType = 'Mtg' and CleansingBatchID = @BatchID

		update qualitystaging.stg.StagingHeaders
			set skey = h.id  
			from qualitystaging.stg.StagingHeaders h
				inner join qualitystaging.stg.transactions t on h.skey = t.SkeyRelationship 
			where RecordType = 'Mtg' and CleansingBatchID = @BatchID

		update qualitystaging.stg.transactions
			set skey = h.skey  
			from qualitystaging.stg.StagingHeaders h
				inner join qualitystaging.stg.transactions t on h.id = t.ParentId and SkeyRelationship is not null
			where RecordType = 'Mtg' and CleansingBatchID = @BatchID

	-- Update Salesid and MtgId
		-- SSIS Package call this SP with the BatchName in BatchID 
		-- exec qualitystaging.stg.TpImportUpdateSalesIDandMtgID ?
		-- Moved code from SP into here and commented out join to batches
		-- Added to where clause h.CleansingBatchID = @BatchID in place
		
			update t
				set SalesId = t2.id
				from qualitystaging.stg.Transactions t
					inner join qualitystaging.stg.Transactions t2 on t.SkeyRelationship = t2.Skey 
					inner join qualitystaging.stg.StagingHeaders h on t.ParentId = h.id
					inner join qualitystaging.stg.StagingHeaders h2 on t2.ParentId = h2.id
					--inner join qualitystaging.stg.Batches b on h.CleansingBatchID = b.id and b.BatchName = @batchname
				where h.CleansingBatchID = @BatchID
					and t.PurchaseMoneyMortgage = 1

			update t2
				set Mtgid = t.id
				from qualitystaging.stg.Transactions t2
					inner join qualitystaging.stg.Transactions t on t.SkeyRelationship = t2.Skey and t.PurchaseMoneyMortgage = 1
					inner join qualitystaging.stg.StagingHeaders h on t.ParentId = h.id 
					inner join qualitystaging.stg.StagingHeaders h2 on t2.ParentId = h2.id
					--inner join qualitystaging.stg.Batches b on h.CleansingBatchID = b.id and b.BatchName = @batchname
				where h.CleansingBatchID = @BatchID

-- Create New Addresses and Names for MTg Split and relink them
	
		-- Created New SP with same code but passes BatchID instead of Name
		--EXEC [stg].[SplitMtgAddNamesAndAddresses] ?
		EXEC qualitystaging.stg.SplitMtgAddNamesAndAddresses_wID @BatchID

-- Add rowcount to Batches

		update b
			set HeaderRowCount = c.cant
			from qualitystaging.stg.Batches b
				inner join (select count(1) as cant,  CleansingBatchID
								from qualitystaging.stg.StagingHeaders h
									--inner join qualitystaging.stg.Batches bch on bch.id = h.CleansingBatchID
									--where bch.BatchName = @batchname
								where h.CleansingBatchID = @BatchID
								group by CleansingBatchID) c on b.id = c.CleansingBatchID


-- Transaction TYpes

		update t
			set PreForeclosureTypeID = tt.id
			from qualitystaging.stg.transactions t
				inner join lookups..TransactionTypes tt on t.TransactionType = tt.code 
				inner join qualitystaging.stg.StagingHeaders h on t.ParentId = h.id and h.CleansingBatchID = @BatchID
				--inner join qualitystaging.stg.Batches bch on bch.id = h.CleansingBatchID and bch.BatchName = @batchname
			where recordtype = 'Pref'
	
		update t
			set LienTypeId = tt.id
			from qualitystaging.stg.transactions t
				inner join lookups..TransactionTypes tt on t.TransactionType = tt.code 
				inner join qualitystaging.stg.StagingHeaders h on t.ParentId = h.id and h.CleansingBatchID = @BatchID
				--inner join qualitystaging.stg.Batches bch on bch.id = h.CleansingBatchID and bch.BatchName = @batchname
			where  recordtype = 'Lien'



-- ### End of working code ### ===================================================================================

	end
	else
		begin
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, 'Missing Parameters in JobParameters', @LogSourceName;
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
			THROW 77777, 'Missing Parameters in JobParameters', 1;
		end


	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

END
