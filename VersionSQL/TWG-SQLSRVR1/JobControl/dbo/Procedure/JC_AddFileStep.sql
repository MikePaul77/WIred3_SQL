/****** Object:  Procedure [dbo].[JC_AddFileStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_AddFileStep @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

	Begin Try
	
		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

		declare @SQLCmd Varchar(max);
		declare @SQLCmdCount Varchar(max);
		declare @SQLCmdLog Varchar(max);
		declare @SQLDropCmd Varchar(max);
		declare @JobID int, @NewDocID int;

		create Table #TmpDocs (DocumentID int null)
		insert #TmpDocs (DocumentID)
			exec GetAttachableFiles @JobStepID, 'AddedFiles'

		Select @NewDocID=DocumentID from #TmpDocs;
		--Print 'NewDocID:';
		--Print @NewDocID;

		if @NewDocID is null
			Begin
				--exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, 'File not found.', 'JC_AddFileStep';
				--exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

				-- MikeP 4/3/2023 Should not fail if no files
				--RAISERROR ('File not found.', 16, 1);  -- Trigger the catch section
				exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, 'No selected / matching files to attach', 'JC_AddFileStep'
			End
		else
			Begin
				-- Only add the file once for the current JobLogID.
				-- If it has been run before, skip over adding another DocumentMaster record.
				--Declare @vDocID int, @jlID int;

				--select @JobID=js.JobID, @vDocID=td.DocumentID, @jlID=dm2.JobLogID 
				--	from JobControl..JobSteps js
				--		join #TmpDocs td on 1=1
				--		left join DocumentLibrary..DocumentMaster dm2 on td.DocumentID=dm2.DocumentID
				--	where js.StepID = @JobStepID

				--if not exists(	Select JobID 
				--				from DocumentLibrary..DocumentMaster 
				--					where JobID=@JobID and JobStepID=@JobStepID and VirtualDocumentID=@vDocID and JobLogID=@jlID)
					
				--insert DocumentLibrary..DocumentMaster (JobID, JobStepID, CreateDate, VirtualDocumentID, JobLogID)
				--	values(@JobID, @JobStepID, GetDate(), @vDocID, @jlID);


				insert DocumentLibrary..DocumentMaster (JobID, JobStepID, CreateDate, VirtualDocumentID, JobLogID)
				select js.JobID, @JobStepID, getdate(), td.DocumentID, jl.CurJobLogID 
					from JobControl..JobSteps js
						join #TmpDocs td on 1=1
						left join DocumentLibrary..DocumentMaster dm2 on td.DocumentID=dm2.DocumentID
						left join (select JobID, max(ID) CurJobLogID 
										from JobControl..JobLog Group by JobID) jl on jl.JobID = js.JobID
					where js.StepID = @JobStepID


				-- This is the original code before we checked for duplication.
				--insert DocumentLibrary..DocumentMaster (JobID, JobStepID, CreateDate, VirtualDocumentID, JobLogID)
				--select js.JobID, js.StepID, GETDATE(), td.DocumentID, dm2.JobLogID 
				--	from JobControl..JobSteps js
				--		join #TmpDocs td on 1=1
				--		left join DocumentLibrary..DocumentMaster dm2 on td.DocumentID=dm2.DocumentID
				--	where js.StepID = @JobStepID

			End

			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

	end Try

	begin catch
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
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, 'JC_AddFileStep'
		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

		RAISERROR (@ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  
	end catch
END

--Commented out 1-28-2020 - Mark W.
--BEGIN
--	SET NOCOUNT ON;

--	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

--	Begin Try
	
--		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

--		declare @SQLCmd Varchar(max);
--		declare @SQLCmdCount Varchar(max);
--		declare @SQLCmdLog Varchar(max);
--		declare @SQLDropCmd Varchar(max);
--		declare @JobID int;

--		create Table #TmpDocs (DocumentID int null)
--		insert #TmpDocs (DocumentID)
--			exec GetAttachableFiles @JobStepID, 'AddedFiles'

--		insert DocumentLibrary..DocumentMaster (JobID, JobStepID, CreateDate, VirtualDocumentID)
--		select js.JobID, js.StepID, GETDATE(), td.DocumentID 
--			from JobControl..JobSteps js
--				join #TmpDocs td on 1=1
--			where js.StepID = @JobStepID

--		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

--	end Try

--	begin catch

--		DECLARE @ErrorMessage NVARCHAR(4000);  
--		DECLARE @ErrorSeverity INT;  
--		DECLARE @ErrorState INT;  
--		DECLARE @ErrorNumber INT;  
--		DECLARE @ErrorLine INT;  

--		SELECT   
--			@ErrorMessage = ERROR_MESSAGE(),  
--			@ErrorSeverity = ERROR_SEVERITY(),  
--			@ErrorNumber = ERROR_NUMBER(),  
--			@ErrorLine = ERROR_LINE(),  
--			@ErrorState = ERROR_STATE();  

--		declare @logEntry varchar(500)

--		set @logEntry ='Error Number ' + cast(@ErrorNumber AS nvarchar(50))+ ', ' +
--                         'Error Line '   + cast(@ErrorLine AS nvarchar(50)) + ', ' +
--                         'Error Message : ''' + @ErrorMessage + ''''

--		print @logEntry

--		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, @LogSourceName

--		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

--		RAISERROR (@ErrorMessage, -- Message text.  
--            @ErrorSeverity, -- Severity.  
--            @ErrorState -- State.  
--            );  

--	end catch
--END
