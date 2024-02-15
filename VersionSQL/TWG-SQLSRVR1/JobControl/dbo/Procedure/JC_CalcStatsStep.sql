/****** Object:  Procedure [dbo].[JC_CalcStatsStep]    Committed by VersionSQL https://www.versionsql.com ******/

Create PROCEDURE dbo.JC_CalcStatsStep @JobStepID int
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
		declare @JobID int;

		--exec JobControl..UpdateQueryFromJobParams @JobStepID

		--select @JobID = js.JobID, @SQLCmd = q.SQLCmd
		--	from JobControl..JobSteps js 
		--		join QueryEditor..Queries q on js.QueryCriteriaID = q.ID
		--	where js.StepID = @JobStepID;

		----Added 7/5/2018 - Mark W.
		--if @SQLCmd is null
		--	exec JobControl.dbo.JobStepLogInsert @JobStepID, 3,'*** QueryEditor..Queries.SQLCmd is null','SP JobControl..JC_QueryStep'

		--declare @StepTable varchar(50);
		--set @StepTable = 'JobControlWork..QueryStepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID));

		--declare @LogInfo varchar(200)
		--set @LogInfo = 'SP Result Location:' + @StepTable;
		--exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;

		--set @SQLCmd = replace(@SQLCmd,'--#INTO TABLE#', 'INTO ' + @StepTable);
		--print '@SQLcmd: ' + iif(@SQLCmd is null, 'NULL', @SQLCmd);
		--set @SQLDropCmd = 'IF OBJECT_ID(''' + @StepTable + ''', ''U'') IS not NULL drop TABLE ' + @StepTable + ' ';
	
		--print '@SQLDropCmd: ' + @SQLDropCmd;
		--exec(@SQLDropCmd);

		--print 'exec JobControl.dbo.JobStepLogInsert ' + convert(varchar(10), @JobStepID) + ', 1, ' + @SQLCmd + ', ''QuerySQLCMD''';
		--exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @SQLCmd, 'QuerySQLCMD'

		--print '@SQLcmd: ' + @SQLCmd;
		--exec(@SQLCmd);
		----Inserting a blank Log Info and count the no of entries in thr StepTable
		--exec JobControl.dbo.JobStepLogInsert @JobStepID, 1,'','StepRecordCount'

		--------------------------------------------------------------------------------------------------------------
		---- Modified this section 12-16-2018 - Mark W.
		--	--set @SQLCmdCount = 'Select Count(*) From ' + @StepTable
		--	--exec JobControl.dbo.JobStepLogInfoUpdate @JobStepID, 'StepRecordCount', @SQLCmdCount 
		--	--exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
		--	Declare @RowCount int;
		--	Exec JobControlWork.dbo.GetTableRowCount @StepTable, @RowCount output;
		--	Declare @cRowCount varchar(20) ;
		--	set @cRowCount = convert(varchar, @RowCount);
		--	exec JobControl.dbo.JobStepLogInfoUpdate @JobStepID, 'StepRecordCount', @cRowCount
		--	select @cRowCount=value from JobControl..Settings where Property='Maximum Query Results'
		--	if @RowCount>=convert(int, @cRowCount)
		--		-- More records were returned than anticipated.  Abort this job
		--		Begin
		--			Insert into JobStepLog(JobId, JobStepID, LogInformation, LogInfoType, LogInfoSource, LogStamp)
		--				values(@JobID, @JobStepID, 'Job Cancelled due to query exceeding maximum number of ' 
		--				+ convert(varchar, @cRowCount) + ' records',1,'JobControl.dbo.JC_QueryStep', getdate());
		--			Print 'exec JobControl.dbo.JobControlStepUpdate ' + convert(varchar, @JobStepID) + ', ''Fail''';
		--			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
		--		End
		--	else
		--		Begin
		--			Print 'exec JobControl.dbo.JobControlStepUpdate ' + convert(varchar, @JobStepID) + ', ''Complete''';
		--			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
		--		End
		-----------------------------------------------------------------------------------------------------------

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
