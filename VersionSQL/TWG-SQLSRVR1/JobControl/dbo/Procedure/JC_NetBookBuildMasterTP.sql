/****** Object:  Procedure [dbo].[JC_NetBookBuildMasterTP]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_NetBookBuildMasterTP @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

	Begin Try
		
		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

		delete JobControl..JobParameters where StepID = @JobStepID
		delete JobControl..JobInfo where StepID = @JobStepID

		declare @SourceTableName varchar(500)

		declare @SQLCmd Varchar(max)
		declare @JobID int, @JobTemplateID int, @CategoryID int;

		select @JobID = js.JobID
				, @JobTemplateID = JobTemplateID
				, @CategoryID = CategoryID
			from JobControl..JobSteps js
				join JobControl..Jobs j on j.JobID = js.JobID
			where StepID = @JobStepID

		select @SourceTableName = ParamValue
			from JobControl..JobParameters
			where StepID = JobControl.dbo.GetDependsJobStepID(@JobStepID)

		insert QualityStaging..Batches (Process, BatchDate, Owner, JobId)
								values ('TP', getdate(), replace(SYSTEM_USER,'TWG\',''), @JobID)
	
		declare @BatchID int

		select @BatchID = max(ID) from QualityStaging..Batches where JobId = @JobID

		delete QualityStaging..BuildMasterTransactions where BatchId = @BatchID


		set @SQLCmd = 'insert QualityStaging..BuildMasterTransactions (BatchId, recnumber, source
									, ccode, town
									, stnum, street, unit
									, book, page, docketref
									, date, signer
									, lender, lname
									, mortgage, mtgbook, mtgpage
								)

					 select @@BatchID@@ , d.[Record_#], case when d.[Record_Type] = ''Mortgage'' then ''Mtg'' else '''' end source
							, t.CCode, d.[Town]
							, d.[Street_#], d.[Street_Name], d.[Unit_#]
							, d.Book_#, d.Page_#, d.Doc_Reference#
							, d.Date_of_Creation, d.Name_of_Signer
							, d.Mtg1_Lender, d.Mtg1_Lender_Misc
							, d.Mtg1_Amount , d.Mtg1_Book, d.Mtg1_Page

						from @@SourceTable@@ d
							left outer join Lookups..Towns t on t.Code = d.[Town] '

		set @SQLCmd = replace(@SQLCmd,'@@SourceTable@@',@SourceTableName)
		set @SQLCmd = replace(@SQLCmd,'@@BatchID@@', ltrim(str(@BatchID)))
		print @SQLCmd
		exec(@SQLCmd)


		--delete QualityStaging..StndAddresses where JobStepID = @JobStepID

		--insert QualityStaging..StndAddresses (ParentID, TypeOperation, TownCode, village
		--									, StreetCore, StreetNumber, StreetNumberExtension, UnitType, UnitNumber
		--									, Zip, Plus4, CarrierRoute, Latitude, Longitude
		--									, CensusTract, CensusBlock
		--									, AddressType, ComplexName
		--									, JobStepID)

		--select ID, source, town, village
		--		, street, Stnum, stnumext, lotcode, unit
		--		, zipcode, plus4, carrier_rt, lat, lon
		--		, cnsstract, cnssblgr
		--		, 'A' AddressType, condoname
		--		, JobStepID

		--	from QualityStaging..BuildMasterTransactions
		--	where JobStepID = @JobStepID


		--delete QualityStaging..Transactions where JobStepID = @JobStepID

		--insert QualityStaging..Transactions (ParentID, TransactionType, 
		--										Book, Page, DocumentNum, FilingDate
		--										,OriginalBook, OriginalPage, OriginalDocumentNum, OriginalFilingDate
		--										, Skey
		--									, JobStepID)

		--	select bmt.ID, source
		--			, book, Page, Docketref, date
		--			, book, Page, Docketref, date
		--			, bmt.Id
		--			, JobStepID
		--		from QualityStaging..BuildMasterTransactions bmt
		--			left outer join Lookups..Towns t on t.Code = bmt.town
		--	where JobStepID = @JobStepID

		--insert QualityStaging..StagingHeaders (Skey, BatchID, RecordType, Postable, ChangeRec, DeleteRec) 
		--	select ID, @BatchID, TransactionType, 1, 1, 0
		--		from QualityStaging..Transactions
		--		where JobStepID = @JobStepID

		--update T set ParentId = H.ID
		--	from QualityStaging..Transactions T
		--		join QualityStaging..StagingHeaders H on H.Skey = T.ID and H.JobStepID = @JobStepID
		--	where t.JobStepID = @JobStepID


		delete t from QualityStaging..Transactions t
				join QualityStaging..StagingHeaders sh on sh.Id = t.ParentId and sh.BatchID = @BatchID

		delete sa from QualityStaging..StndAddresses sa
				join QualityStaging..StagingHeaders sh on sh.Id = sa.ParentId and sh.BatchID = @BatchID

		delete QualityStaging..StagingHeaders where BatchID = @BatchID

		insert QualityStaging..StagingHeaders (Skey, BatchID, RecordType, Postable, ChangeRec, DeleteRec) 
			select ID, @BatchID, source, 1, 1, 0
				from QualityStaging..BuildMasterTransactions
				where BatchID = @BatchID

Print 'Insert Transactions'

		insert QualityStaging..Transactions (ParentID, TransactionType, 
												Book, Page, DocumentNum, FilingDate
												,OriginalBook, OriginalPage, OriginalDocumentNum, OriginalFilingDate )

			select sh.Id, source
					, book, Page, Docketref, date
					, origbook, origpage, origdoc, origdate
				from QualityStaging..BuildMasterTransactions bmt
					join QualityStaging..StagingHeaders sh on sh.Skey = bmt.ID
					left outer join Lookups..Towns t on t.Code = bmt.town
			where sh.BatchID = @BatchID

Print 'Insert StndAddresses'

		insert QualityStaging..StndAddresses (ParentID, TypeOperation, TownCode, village
											, StreetCore, StreetNumber, StreetNumberExtension, UnitType, UnitNumber
											, Zip, Plus4, CarrierRoute, Latitude, Longitude
											, CensusTract, CensusBlock
											, AddressType, ComplexName)

			select sh.ID, source, town, village
					, street, Stnum, stnumext, lotcode, unit
					, bmt.zipcode, plus4, carrier_rt, lat, lon
					, cnsstract, cnssblgr
					, 'A' AddressType, condoname

				from QualityStaging..BuildMasterTransactions bmt
					join QualityStaging..StagingHeaders sh on sh.Skey = bmt.ID
					left outer join Lookups..Towns t on t.Code = bmt.town
				where sh.BatchID = @BatchID

Print 'Get HeaderRowCount'

		declare @RecCount int

		select @RecCount = count(*) from QualityStaging..StagingHeaders where BatchID = @BatchID

Print 'Update HeaderRowCount'

		update QualityStaging..Batches set HeaderRowCount = @RecCount
				where ID = @BatchID

Print 'Insert Log RecordCount'

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @RecCount , 'StepRecordCount'

		--insert JobInfo (JobID, StepID, InfoName, InfoValue) 
		--	select @JobID, @JobStepID, 'No Stats', 0

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

	end Try
	Begin Catch

		DECLARE @ErrorMessage NVARCHAR(4000);  
		DECLARE @ErrorSeverity INT;  
		DECLARE @ErrorState INT;  
		DECLARE @ErrorNumber INT;  
		DECLARE @ErrorLine INT;  

		SELECT   
			@ErrorMessage = ERROR_MESSAGE(),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorNumber = ERROR_NUMBER(),  
			@ErrorLine = ERROR_LINE(),  
			@ErrorState = ERROR_STATE();  

		declare @logEntry varchar(500)

		set @logEntry ='Error Number ' + cast(@ErrorNumber AS nvarchar(50))+ ', ' +
                         'Error Line '   + cast(@ErrorLine AS nvarchar(50)) + ', ' +
                         'Error Message : ''' + @ErrorMessage + ''''

		print @logEntry

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, @LogSourceName

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

		RAISERROR (@ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  
	End Catch



END
