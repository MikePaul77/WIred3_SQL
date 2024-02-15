/****** Object:  Procedure [dbo].[JC_MergeStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_MergeStep @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

		Begin Try

			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

			delete JobControl..JobParameters where StepID = @JobStepID
			delete JobControl..JobInfo where StepID = @JobStepID

			declare @MergeTableName varchar(500)
			declare @SQLCmd Varchar(max);
			declare @JobID int;

			select @JobID = JobID
				from JobControl..JobSteps
				where StepID = @JobStepID

			set @MergeTableName = 'JobControlWork..MergeStepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID));
			declare @TableCount int = 1

			set @SQLCmd = 'IF OBJECT_ID(''' + @MergeTableName + ''', ''U'') IS not NULL drop TABLE ' + @MergeTableName + ' '
			exec(@SQLCmd)

			 declare @SrcTableName varchar(200)

			 DECLARE curA CURSOR FOR
					select ParamValue
						from JobControl..JobParameters
						where StepID = JobControl.dbo.GetDependsJobStepID(@JobStepID)

			 OPEN curA

			 FETCH NEXT FROM curA into @SrcTableName 
			 WHILE (@@FETCH_STATUS <> -1)
			 BEGIN
					if @TableCount = 1
					begin
						set @SQLCmd = 'select * into ' + @MergeTableName + ' from ' + @SrcTableName
						print @SQLCmd
						exec(@SQLCmd)
					end
					else
					begin
						set @SQLCmd = 'insert ' + @MergeTableName + ' select * from ' + @SrcTableName
						print @SQLCmd
						exec(@SQLCmd)
					end
				  set @TableCount = @TableCount + 1
				  FETCH NEXT FROM curA into @SrcTableName 
			 END
			 CLOSE curA
			 DEALLOCATE curA

				exec JobControl.dbo.SetJobStepParam @JobStepID, 'Merged Table', @MergeTableName, @LogSourceName

			set @SQLCmd = 'insert JobInfo (JobID, StepID, InfoName, InfoValue) select ' + ltrim(str(@JobID)) + ', ' + ltrim(str(@JobStepID)) + ' , ''Total Records Merged'',count(*) from ' + @MergeTableName
			exec(@SQLCmd)

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
