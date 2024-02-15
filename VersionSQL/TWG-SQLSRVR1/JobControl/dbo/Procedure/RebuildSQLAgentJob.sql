/****** Object:  Procedure [dbo].[RebuildSQLAgentJob]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 03/02/2019
-- Description:	Recreates a SQL Agent Job
-- =============================================
CREATE PROCEDURE dbo.RebuildSQLAgentJob
	@JobID int
AS
BEGIN

	IF EXISTS(select Job_ID FROM msdb.dbo.sysjobs sj join JobControl..Jobs j on j.SQLJobID = sj.job_id where j.JobID = @JobID)
		Begin
			Declare @ExistingID varchar(50);
			select @ExistingID=Job_ID FROM msdb.dbo.sysjobs sj join JobControl..Jobs j on j.SQLJobID = sj.job_id where j.JobID = @JobID
			Delete from msdb.dbo.sysjobs where Job_ID=@ExistingID
			Delete from msdb.dbo.sysjobsteps where Job_ID=@ExistingID
		END

	BEGIN
		Declare @JobCatName varchar(255), 
			@JobName varchar(255), 
			@NewJobName varchar(255), 
			@SQLJobCatID int, 
			@SQL varchar(500),
			@SQLJobID varchar(50),
			@W3AppPath varchar(255),
			@StepID int, 
			@StepName varchar(255), 
			@StepTypeName varchar(50), 
			@StepTypeCode varchar(505),
			@StepActionType varchar(50), 
			@StepActionCommand varchar(255), 
			@SSIS32bit int, 
			@RunMode char(1),
			@RunModeID int,
			@StepDisabled bit,
			@SQLOnSuccess int, 
			@StepOrder int,
			@RequiresSetup int, 
			@Step_Desc varchar(255), 
			@Sub_System varchar(40), 
			@Step_Command varchar(255),
			--@OnSuccess int,
			@OnSuccessStepID int,
			@OnFailAction int,
			@OnFailStepID int,
			--@PrevStepOnSuccess int,
			@PrevStepDisabled bit,
			@PrevStep int, 
			@TotalSteps int,
			@StepCount int = 0,
			@LoopFound int =0

		--SQL Step Action Values
		--1	Quit with success.
		--2	Quit with failure.
		--3	Go to next step.

		SELECT @JobName=j.JobName
				--, @JobCatName='Wired Job Cat: ' + coalesce(jc.Code,'NA') + ' Type: ' + coalesce(jt.Type,'NA')
				, @JobCatName='Wired Job'
			FROM JobControl..Jobs j
				left outer join JobControl..JobCategories jc on jc.ID = j.CategoryID
				left outer join JobControl..Jobs jt on jt.IsTemplate = 1 and jt.JobID = j.JobTemplateID
			WHERE j.JobID = @JobID;
		set @NewJobName = @JobCatName + ' - ' + left(@JobName,100) + ' [' + convert(varchar, @JobID) + ']';
		set @NewJobName = replace(@NewJobName, '''','''''');

		-- Get the Category_ID for this job if it exists
		SELECT @SQLJobCatID=category_id 
			FROM msdb.dbo.syscategories 
			WHERE category_class = 1 
				AND category_type = 1 
				AND name = @JobCatName;
		if @SQLJobCatID is null
			Begin
				-- Category_ID didn't exist.  Add it and then retrieve the new value
				set @SQL='EXEC msdb.dbo.sp_add_category @class=''JOB'', @type=''LOCAL'', @name=N''' + @JobCatName + '''';
				print @SQL;
				exec(@SQL);

				SELECT @SQLJobCatID=category_id 
					FROM msdb.dbo.syscategories 
					WHERE category_class = 1 
						AND category_type = 1 
						AND name = @JobCatName;
			End

		--Create the new job
		EXEC msdb.dbo.sp_add_job 
			@job_name = @NewJobName, 
			@category_id = @SQLJobCatID;

		-- Add the server name
		EXEC msdb.dbo.sp_add_jobserver  
		    @job_name = @NewJobName,  
		    @server_name = @@SERVERNAME; 

		-- Get the Job_ID (uniqueidentifier) from the new record created in msdb.dbo.sysjobs
		-- and update the JobControl..Jobs record with it.
		SELECT @SQLJobID=job_id FROM msdb.dbo.sysjobs sj where name=@NewJobName;
		Update JobControl..Jobs set SQLJobID = @SQLJobID where JobID = @JobID;

		-- Get the path to be used for the executables
		declare @ServerName varchar(50)
		Select @W3AppPath=W3AppPath 
				, @ServerName = ServerName
			from Support..Servers 
			where SQLName=@@SERVERNAME;

		drop table if exists #js

		select js.StepID, js.StepName, jst.StepName StepTypeName, jst.Code StepTypeCode, 
						coalesce(tt.JobStepActionType, jst.StepActionType) StepActionType,
						case when jst.StepActionType = 'OSCmd' then '{0}\' else '' end + coalesce(tt.JobStepActionCommand, jst.StepActionCommand) StepActionCommand,
						jst.SSIS32bit, jm.Code RunMode, jst.RequiresSetup,
						case when js.RunModeID = 1 then 1
							when js.RunModeID = 3 and js.CompletedStamp is null then 0
							when js.RunModeID = 3 and js.CompletedStamp is not null then 1
							else 1 end as RunModeID
						, coalesce(js.Disabled,0) StepDisabled
						, 3 SQLOnSuccess
						, js.StepOrder
					into #js
					from JobSteps js
						join JobStepTypes jst on jst.StepTypeID = js.StepTypeID
						join JobModes jm on jm.ID = js.RunModeID
						left outer join TransformationTemplates tt on jst.Code = 'T' and tt.ID = js.TransformationID
					where js.JobID = @JobID
				
		update #js set SQLOnSuccess = 1
				where StepOrder = (select Max(StepOrder) from #js)

		update js set SQLOnSuccess = 1
			from #js js
				join #js js2 on js.steporder = js2.steporder-1 and js2.RunMode = 'M'

		-- Get the data to build the SQL Job Steps
		DECLARE BuildSQLAgentJob_cursor CURSOR FOR 
			select StepID, StepName, StepTypeName, StepTypeCode 
					, StepActionType
					, StepActionCommand
					, SSIS32bit, RunMode, RequiresSetup
					, RunModeID
					, StepDisabled
					, SQLOnSuccess
					, StepOrder
				from #js order by StepOrder
		

		OPEN BuildSQLAgentJob_cursor;
		set @TotalSteps = @@CURSOR_ROWS;  
		FETCH NEXT FROM BuildSQLAgentJob_cursor INTO @StepID, @StepName, @StepTypeName, @StepTypeCode, @StepActionType, @StepActionCommand
			, @SSIS32bit, @RunMode, @RequiresSetup, @RunModeID, @StepDisabled, @SQLOnSuccess, @StepOrder
		WHILE @@FETCH_STATUS = 0  
		BEGIN 
			--if rtrim(ltrim(@StepName))='' set @StepName='--Blank Step Name--';
			set @Step_Desc = @StepTypeName + ' [' + convert(varchar,@StepID) + '] ' + @RunMode;
			set @Sub_System='TSQL';  -- Default
			set @OnSuccessStepID = 0;
			set @OnFailStepID = 0;

			-- Set the @Sub_System and @Step_Command values based on the @StepActionType
			if @StepDisabled = 1
				Begin
					--set @Step_Command = 'select ''Step Disabled'' Step'
					set @Step_Command = 'exec JobControl.dbo.JC_ManualDisabledStep ' + convert(varchar, @StepID) + ';'
					set @Step_Desc = '[Disabled] ' + @Step_Desc
				End
			else if @StepActionType='OSCmd'
				Begin
					set @Sub_System='CMDEXEC';
					--MP 11/13/19 Line below is to be turned on when EXE are recoded to take a server parameter and following line in to be disabled
					set @Step_Command = Replace(@StepActionCommand, '{0}',@W3AppPath) + ' ' + @ServerName + ' ' + convert(varchar, @StepID);
					--set @Step_Command = Replace(@StepActionCommand, '{0}',@W3AppPath) + ' ' + convert(varchar, @StepID);
				End
			Else if @StepActionType='SP' 
					set @Step_Command = 'exec ' + @StepActionCommand + ' ' + convert(varchar, @StepID) + ';' + 
						iif(@StepTypeCode='ELOOP','',' IF @@ERROR > 0 ' + 
						'exec JobControl.dbo.JobControlStepUpdate ' + convert(varchar, @StepID) + ', ''Fail''');
			Else
				set @Step_Command = '-- Manual UI Step, Will skip if complete or stop job';

			-- Add the new job step
			SET @StepCount = @StepCount + 1;
			--SET @OnSuccess = iif(@StepCount=@TotalSteps or @RunMode='M',1, iif(@RunModeID=1,3,1));

			--if @StepCount < @TotalSteps --and @StepDisabled = 0
			--	set @OnSuccess = 3;	--Go to next step.
			--else
			--	set @OnSuccess = 1;	--Quit with success.

			
			SET @OnFailAction=2;

			if @StepTypeCode = 'BLOOP' or @StepTypeCode='ELOOP'
				Set @LoopFound=1;


			Print ' ----------------------';
			Print '@StepDisabled: ' + convert(varchar,@StepDisabled);
			Print '@StepCount: ' + convert(varchar,@StepCount);
			Print '@TotalSteps: ' + convert(varchar,@TotalSteps);
			Print '@RunModeID: ' + convert(varchar,@RunModeID);
			--Print '@OnSuccess: ' + convert(varchar,@OnSuccess);

			
			EXEC msdb.dbo.sp_add_jobstep  
				@job_name = @NewJobName,  
				@step_name = @Step_Desc,
				@on_success_action = @SQLOnSuccess,
				@on_success_step_id = @OnSuccessStepID,
				@on_fail_action = @OnFailAction, 
				@on_fail_step_id = @OnFailStepID,  
				@subsystem = @Sub_System,  
				@command = @Step_Command;
	

			--Update the JobSteps table with the step number
			Update JobControl..JobSteps set SQLJobStepID=@StepCount where StepID = @StepID;

			--if @StepCount > 1 and @RunMode='M' and @PrevStepDisabled = 0 and @StepDisabled = 0 
			--	Begin
			--		-- Update the previous SQL Job Step
			--		SET @PrevStep = @StepCount -1;
			--		--Print ' ************************';
			--		--Print '   @StepCount: ' + convert(varchar,@StepCount);
			--		--Print '   @PrevStepOnSuccess: ' + convert(varchar,@PrevStepOnSuccess);
			--		--Print '   @PrevStep: ' + convert(varchar,@PrevStep);
			--		--Print ' ************************';
			--		EXEC msdb.dbo.sp_update_jobstep 
			--		    @job_name = @NewJobName,  
			--		    @step_id = @PrevStep,
			--			@on_success_action = 1;
			--	End

			--SET @PrevStepOnSuccess=@OnSuccess;
			SET @PrevStepDisabled=@StepDisabled;
			FETCH NEXT FROM BuildSQLAgentJob_cursor INTO @StepID, @StepName, @StepTypeName, @StepTypeCode, @StepActionType, @StepActionCommand
				, @SSIS32bit, @RunMode, @RequiresSetup, @RunModeID, @StepDisabled, @SQLOnSuccess, @StepOrder
		END
		CLOSE BuildSQLAgentJob_cursor  
		DEALLOCATE BuildSQLAgentJob_cursor 
		if @LoopFound=1
			Declare @BloopStep int = 0, @EloopStep int = 0, @ContinueStep int = 0;
		While @LoopFound=1
			Begin
				-- There is a loop in this job.  Reset the on success step for the end loop and the on failure step for the begin loop.
				Select Top 1 @BloopStep=step_id 
					from msdb.dbo.sysjobsteps 
					where job_id=@SQLJobID 
						and [command] like '%JC_BeginLoop%' 
						and step_id>@BloopStep 
					order by step_id
				if @@ROWCOUNT=0
					Begin
						set @LoopFound=-1;
						BREAK
					END
				Select Top 1 @EloopStep=step_id 
					from msdb.dbo.sysjobsteps 
					where job_id=@SQLJobID 
						and [command] like '%JC_EndLoop%' 
						and step_id>@EloopStep 
					order by step_id
				if @BloopStep>0 and @EloopStep>0
					Begin
						-- Set eloop to on success go to bloop step
						EXEC msdb.dbo.sp_update_jobstep 
							@job_name = @NewJobName,	
						    @step_id = @EloopStep,
							@on_fail_action = 4,
							@on_fail_step_id = @BloopStep;
					End
				else
					set @LoopFound=-1;
			End
					

			--@job_name = @NewJobName, 
			---- If the step is a Begin Loop step, On Failure should go to the step after the next end loop.
			--	if @StepTypeCode='BLOOP'
			--		Begin
			--			Set @OnFailStepID = 
			--				(Select top 1 js.StepOrder
			--					from JobSteps js
			--						join JobStepTypes jst on jst.StepTypeID = js.StepTypeID
			--					where js.JobID=@JobID
			--						and js.StepOrder>@StepCount
			--						and jst.Code='ELOOP'
			--					order by js.StepOrder)
			--			set @OnSuccess=4;
			--		End
			--	-- If the step is an End Loop step, On Success should go to the Begin Loop step.
			--	if @StepTypeCode='ELOOP'
			--		Begin
			--			Set @OnFailStepID = 
			--				(Select top 1 js.StepOrder
			--					from JobSteps js
			--						join JobStepTypes jst on jst.StepTypeID = js.StepTypeID
			--					where js.JobID=@JobID
			--						and js.StepOrder<5
			--						and jst.Code='BLOOP'
			--					order by js.StepOrder desc)
			--			set @OnFailAction=4;
			--		End
			--END


	END

END
