/****** Object:  Procedure [dbo].[JC_AppendStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_AppendStep @JobStepID int
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
	declare @InLoop bit = 0
	declare @DeleteBeforeAppend bit = 0
	declare @sep varchar(10)
	declare @FieldMode varchar(10)

	select @DependsOnStepIDs = js.DependsOnStepIDs
			, @JobID = js.JobID
			, @StepType = jst.StepName
			, @InLoop = JobControl.dbo.InLoop(js.StepID)
			, @DeleteBeforeAppend = js.DeleteBeforeAppend
			, @FieldMode = coalesce(js.AppendFieldMode,'')
		from JobControl..JobSteps js
			join JobControl..JobStepTypes jst on js.StepTypeID = jst.StepTypeID
		where js.StepID = @JobStepID

	declare @StepTable varchar(50);
	set @StepTable = 'JobControlWork..' + @StepType + 'StepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID));

	if @InLoop = 0 or @DeleteBeforeAppend=1  -- Added the @DeleteBeforeAppend condition 9/1/2020 - Mark W.
	Begin
		set @SQLDropCmd = 'IF OBJECT_ID(''' + @StepTable + ''', ''U'') IS not NULL drop TABLE ' + @StepTable + ' ';
		print @SQLDropCmd;
		exec(@SQLDropCmd);
	End

	Begin Try

		if @JobID in (6460, 6459, 3867, 3866)
			exec JobControl.dbo.GroupCountProcessAppend @JobStepID

		set @SQLCmd = ''
		set @sep = char(10) + ''
		declare @AppendTable varchar(2000)       

		DECLARE curAppendStep CURSOR FOR
		select 'JobControlWork..' + jst.StepName + 'StepResults_J' + ltrim(str(@JobID)) + '_S' + IDs.Value
			from Support.FuncLib.SplitString(@DependsOnStepIDs,',') IDs
				join JobControl..JobSteps js on js.JobID = @JobID and js.StepID = IDs.Value and coalesce(js.Disabled,0) = 0
				join JobControl..JobStepTypes jst on js.StepTypeID = jst.StepTypeID

		OPEN curAppendStep

		 FETCH NEXT FROM curAppendStep into @AppendTable
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

		 		if @FieldMode = 'BKI'
					set @AppendTable = replace(@AppendTable,'StepResults','StepResultsBKI') 

				set @SQLCmd = @SQLCmd + @sep + ' select * from ' + @AppendTable
				
				set @sep = char(10) + 'union all'

			  FETCH NEXT FROM curAppendStep into @AppendTable
		 END
		 CLOSE curAppendStep
		 DEALLOCATE curAppendStep

		 set @SQLCmd = 'IF OBJECT_ID(''' + @StepTable + ''', ''U'') IS NULL
							select * into ' + @StepTable + ' from ( ' + char(10) + @SQLCmd + char(10)  + ' ) x
						else
							insert ' + @StepTable + ' select * from ( ' + char(10) + @SQLCmd + char(10)  + ' ) x '

		 --set @SQLCmd = 'select * into ' + @StepTable + ' from ( ' + char(10) + @SQLCmd + char(10)  + ' ) x '

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
