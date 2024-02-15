/****** Object:  Procedure [dbo].[JC_RawXFormDataStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_RawXFormDataStep @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

	declare @SQLCmd Varchar(max);
	declare @SQLDropCmd Varchar(max);
	declare @SQLCmdCount Varchar(max);
	declare @DependsOnStepIDs varchar(100)
	declare @StepType varchar(50)
	declare @JobID int
	declare @StepOutTable varchar(500);
	declare @StepInTable varchar(500);

	select @DependsOnStepIDs = js.DependsOnStepIDs
			, @JobID = js.JobID
			, @StepType = jst.StepName
			, @StepOutTable = 'JobControlWork..' + @StepType + 'StepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID))
			, @StepInTable = 'JobControlWork..TransformStepRawCount_J' + ltrim(str(djs.JobID)) + '_S' + ltrim(str(djs.StepID))
		from JobControl..JobSteps js
			join JobControl..JobStepTypes jst on js.StepTypeID = jst.StepTypeID
			left outer join JobControl..JobSteps djs on js.JobID = djs.jobid
				and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(djs.StepID)) + ',%'
			left outer join JobStepTypes dst on djs.StepTypeID = dst.StepTypeID
		where js.StepID=@JobStepID
	Begin try

		set @SQLDropCmd = 'IF OBJECT_ID(''' + @StepOutTable + ''', ''U'') IS not NULL drop TABLE ' + @StepOutTable + ' ';
	
		print @SQLDropCmd;
		exec(@SQLDropCmd);

		set @SQLCmd = ''

		set @SQLCmd = 'select * into ' + @StepOutTable + ' from ' + char(10) + @StepInTable + char(10)  + '  '

		print @SQLCmd;
		exec(@SQLCmd);

		declare @LogInfo varchar(500) = ''
		set @LogInfo = 'SP Result Location: ' + @StepOutTable;
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1,'','StepRecordCount'
		Declare @RowCount int;
		Exec GetTableRowCount @StepOutTable, @RowCount output;
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
