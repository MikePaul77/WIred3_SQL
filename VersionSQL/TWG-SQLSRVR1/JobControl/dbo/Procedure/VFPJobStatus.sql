/****** Object:  Procedure [dbo].[VFPJobStatus]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobStatus
AS
BEGIN
	SET NOCOUNT ON;

	SELECT vj.jobID VFPJobID, vj.jobtype VFPJobType, vj.jobdescrip VFPJobName
			, co.orderid VFPOrderID
			--, co.orderdesc
			--, co.ordactst, oas.Description OrderActStatus
			--, co.orderstat, os.[desc] OrderStatus

			, case when j.UpdatedStamp > '1/1/2022' then j.JobID else null end SQLJobID
			, case when j.UpdatedStamp > '1/1/2022' then j.JobName else null end SQLJobName
			, case when j.UpdatedStamp > '1/1/2022' then coalesce(j.Developer,'') else null end Developer
			, case when j.UpdatedStamp > '1/1/2022' then convert(varchar(20),j.CreatedStamp,101) else null end SQLCreated
			, case when j.UpdatedStamp > '1/1/2022' then convert(varchar(20),j.UpdatedStamp,101) else null end SQLLastUpdated
			--, j.InProduction

	  FROM [SandBox].[dbo].[VFPOrdWork_jobs] vj
		left outer join JobControl..Jobs j on ',' + replace(j.VFPJobIDs,' ','') + ',' like '%,' + vj.jobID + ',%' and coalesce(j.disabled,0) = 0 and coalesce(j.deleted,0) = 0 and j.VFPJobIDs > ''
		--left outer join (select JobID, Max(StartedStamp) StartedStamp from JobControl..JobSteps js group by JobID) js on js.JobID = j.JobID
		left outer join (select cro.CurrOrderID, oj.JObID
							from Sandbox..VFPOrdWork_CurrOrder cro 
								join (select oj.OrderID, oj.jobID
													from Sandbox..VFPOrdWork_orderjobs oj 
														join Sandbox..VFPOrdWork_jobs j on j.jobID = oj.jobID and j.status not in ('Q','S')
													where j.JobType not like '%\_' ESCAPE '\') oj on oj.orderID = cro.orderID
						) oj on oj.jobid = vj.jobid
		left outer join Sandbox..VFPOrdWork_custorders co on co.orderid = oj.CurrOrderID
		--left outer join OrderControl..OrderStatus oas on oas.Code = co.ordactst
		--left outer join DataLoad..Jobs_ordstatus os ON os.status = co.orderstat

	  where try_convert(date,dtcomplete) > dateadd(dd,-30,getdate())
		and jobtype not in ('TRXNPD','TRXNVT','TRXNPR','FRTOWN','CNV1','TNWLIV','REMTCH','DEDUPE','CNVNET','DEDUPM','MAPCNG','PCLPR','SALERE','SEXDEL','TRRSCH','TRXSNY','TAXCAL','ACCADT','ACCINV','ACCREC','ACCRPD'  --internal
							,'GWCCRE','GWMCRE','GWRCRE','ACCEXP','ACCRPP'   -- More internal
							, 'STATNS' -- Not Needed anymore Stats, trendlines, Trandline Galley?
							,'CMRCQT','CMRIMT','MMR')  -- In New Modules
		and vj.jobID not in (237821,237966,237967,237814,237989,237820,237815,237817,237991,237515,238091,237771,238193,237994,227967,66765,239893,239891)  -- Not Needed Per Sam & Bill
			and vj.jobdescrip not like 'ZZZ - In SQL%' 
			and coalesce(j.InProduction,0) = 0
	order by 2,3

END
