/****** Object:  Procedure [dbo].[JC_FCFiles]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_FCFiles @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

	declare @StepType varchar(50)
	declare @JobID int
	declare @FileWatcherID int
	declare @SQLDropCmd Varchar(max);
	declare @SQLCmd Varchar(max);
	declare @StepTable varchar(500);

	select @JobID = js.JobID
			, @FileWatcherID = coalesce(js.FileWatcherID,0)
			, @StepTable = 'JobControlWork..' + jst.StepName + 'StepResults_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
		from JobControl..JobSteps js
			join JobControl..JobStepTypes jst on js.StepTypeID = jst.StepTypeID
		where js.StepID = @JobStepID

	set @SQLDropCmd = 'IF OBJECT_ID(''' + @StepTable + ''', ''U'') IS not NULL drop TABLE ' + @StepTable + ' ';
	print @SQLDropCmd;
	exec(@SQLDropCmd);

	declare @LogInfo varchar(500) = ''
	set @LogInfo = 'SP Result Location: ' + @StepTable;
	exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;

	Begin Try

		set @SQLCmd = 'select f.FileID, FileName, s.filewatcherpath + ''\'' + FileControl.dbo.WatcherWorkFileName(FileID) WorkFileName 
							into ' + @StepTable + '
							from FileControl..Files f
								join Support..Servers s on s.SQLName=@@SERVERNAME
							where WatcherLocID = ' + ltrim(str(@FileWatcherID)) + '
								and Approved = 1
								and ProcessedStamp is null '
		print @SQLCmd;
		exec(@SQLCmd);

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1,'','StepRecordCount'
		Declare @RowCount int;
		Exec GetTableRowCount @StepTable, @RowCount output;
		Declare @cRowCount varchar(20) ;
		set @cRowCount = convert(varchar, @RowCount);
		exec JobControl.dbo.JobStepLogInfoUpdate @JobStepID, 'StepRecordCount', @cRowCount

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

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, @LogSourceName

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

		RAISERROR (@ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  

	end catch


END
