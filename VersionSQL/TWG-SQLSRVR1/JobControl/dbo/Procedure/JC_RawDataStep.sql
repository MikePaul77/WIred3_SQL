/****** Object:  Procedure [dbo].[JC_RawDataStep]    Committed by VersionSQL https://www.versionsql.com ******/

Create PROCEDURE dbo.JC_RawDataStep @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

	declare @SQLCmd Varchar(max);
	declare @SQLDropCmd Varchar(max);
	declare @SQLCmdCount Varchar(max);
	declare @DependsOnStepIDs varchar(100)
	declare @SourceTableName varchar(200)
	declare @StepType varchar(50)
	declare @JobID int

	select @DependsOnStepIDs = js.DependsOnStepIDs
			, @JobID = js.JobID
			, @StepType = jst.StepName
			, @SourceTableName = RawDataSourceTable
		from JobControl..JobSteps js
			join JobControl..JobStepTypes jst on js.StepTypeID = jst.StepTypeID
		where js.StepID = @JobStepID

	declare @StepTable varchar(50);
	set @StepTable = 'JobControlWork..' + @StepType + 'StepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID));

	set @SQLDropCmd = 'IF OBJECT_ID(''' + @StepTable + ''', ''U'') IS not NULL drop TABLE ' + @StepTable + ' ';
	print @SQLDropCmd;
	exec(@SQLDropCmd);

	Begin Try

		set @SQLCmd = 'select * into ' + @StepTable + ' from ' + @SourceTableName

		print @SQLCmd;
		exec(@SQLCmd);
		--Inserting a blank Log Info and count the no of entries in the StepTable

		declare @LogInfo varchar(500) = ''
		set @LogInfo = 'SP Result Location: ' + @StepTable;
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;

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
