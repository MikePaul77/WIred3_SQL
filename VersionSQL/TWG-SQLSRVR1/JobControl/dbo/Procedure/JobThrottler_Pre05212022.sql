/****** Object:  Procedure [dbo].[JobThrottler_Pre05212022]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 10-13-2018
-- Description:	Kicks off scheduled jobs and throttles how many jobs can run at one time.
-- =============================================
create PROCEDURE dbo.JobThrottler_Pre05212022
AS
BEGIN
	SET NOCOUNT ON;
	
	Declare @WaitingJobs int,
			@MaxJobs int,
			@tEnabled bit,
			@RunningJobs int,
			@SQLJobID varchar(36),
			@ID int,
			@WiredJobMaxRunMinutes int,
			@JobToCancel varchar(100),
			@Max2Run int,
			@LoopCount int,
			@WiredJobID int,
			@JobStepID int,
			@JobLog_JobID int,
			@JobParameters varchar(25),
			@JobName nvarchar(200), 
			@JobStepName nvarchar(200),
			@StepOrder int,
			@SQL varchar(max),
			@StartTime Datetime, 
			@SQLdJobID varchar(40), 
			@StopTime datetime, 
			@result nvarchar(4000)

	declare @DeleteCompletedJobs bit = 1

	select @DeleteCompletedJobs = case when Value = '1' then 1 else 0 end
		from JobControl..Settings
		where Property = 'DeleteCompletedJobs'

	Select @tEnabled=[ThrottlerEnabled], @MaxJobs=MaxJobs, @WiredJobMaxRunMinutes=WiredJobMaxRunMinutes 
		from JobThrottlerSettings;

	if @tEnabled=1
		Begin
			-- Find out how many jobs are waiting and how many are currently running
			Select @WaitingJobs=count(ID)
				from JobLog
				where StartTime is Null and CancelTime is null;

			SELECT @RunningJobs=count(ja.job_id)
				FROM msdb.dbo.sysjobactivity ja 
					LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
					JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
					JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
				WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
					AND start_execution_date is not null
					AND stop_execution_date is null
		End


	While @tEnabled=1
	Begin  -- START OF MAIN LOOP

		set @LoopCount=0;
		Set @Max2Run = @MaxJobs - @RunningJobs;


		--- PART 1 - JOB START SECTION
		While @MaxJobs>@RunningJobs and @WaitingJobs>0 and @tEnabled=1 and @LoopCount<@Max2Run
		Begin
			-- Job Start Loop
				--Select top 1 @SQLJobID=SQLJobID, @ID=ID, @JobLog_JobID=JobID, @JobStepID=JobStepID
				--	from JobLog
				--	Where StartTime is null and CancelTime is null
				--	order by RunPriority, ID
			exec JobThrottler_GetNextJob @ID output;
			Select @SQLJobID=SQLJobID, @JobLog_JobID=JobID, @JobStepID=JobStepID
				from JobLog
				Where ID=@ID;

			if @SQLJobID is not null
				Begin
					--set @JobParameters='';
					--exec GetJobParamText @JobLog_JobID, @JobParameters OUTPUT;  --Get the job's parameters
					if @JobStepID is null
						Begin
							--Exec msdb.dbo.sp_start_job @job_id = @SQLJobID;
							----Update JobLog 
							----	SET StartTime=getdate()
							----		, JobParameters=@JobParameters
							----		, TestMode=(Select TestMode from Jobs where JobID=@JobLog_JobID)
							----	WHERE ID=@ID;
							--update jl set StartTime=getdate()
							--		, JobParameters=@JobParameters
							--		, TestMode = j.TestMode
							--		, InProduction = j.InProduction
							--	from JobLog jl
							--		join Jobs j on j.JobID = @JobLog_JobID
							--	WHERE ID=@ID;

					--		exec JobControl..StartWiredJob @JobLog_JobID, @ID

							--Update Jobs 
							--	SET LastJobLogID=@ID,
							--		LastJobParameters=@JobParameters
							--	WHERE JobID=(Select JobID from JobLog where ID=@ID);
							set @LoopCount = @LoopCount + 1;
						End
					else
						Begin
							Select @StepOrder=js.StepOrder, @SQLJobID=j.SQLJobID 
								from JobSteps js
									join Jobs J on J.JobID=js.JobID
								where js.StepID=@JobStepID

							Select @JobName=j.name, @JobStepName=js.step_name
								from msdb.dbo.sysjobsteps js
									join msdb.dbo.sysjobs j on j.job_id=js.job_id
								where js.job_id=@SQLJobID
									and js.step_id=@StepOrder
							set @SQL = 'EXEC msdb.dbo.sp_start_job N''' + replace(@JobName, '''', '''''') +
								''', @step_name = N''' + replace(@JobStepName,'''', '''''') + '''';
							Exec(@SQL);
						
							Update JobLog 
								SET StartTime=getdate(), 
									JobParameters=@JobParameters
								WHERE ID=@ID;
							Update Jobs 
								SET LastJobLogID=@ID,
									LastJobParameters=@JobParameters
								WHERE JobID=(Select JobID from JobLog where ID=@ID);
							set @LoopCount = @LoopCount + 1;
						End
				End
			else
				Begin
					if @ID > 0
					begin

						exec JobControl..StartWiredJob @JobLog_JobID, @ID

						--exec JobControl..RebuildSQLAgentJob @JobLog_JobID

						----update jl set SQLJobID = j.SQLJobID
						----	from JobControl..JobLog jl
						----		join JobControl..Jobs j on j.JobID = jl.JobID
						----	where jl.ID = @ID
						----		and jl.SQLJobID is null

						--update jl set SQLJobID = j.SQLJobID
						--	from JobControl..JobLog jl
						--		join JobControl..Jobs j on j.JobID = jl.JobID
						--	where j.JobID = @JobLog_JobID
						--		and jl.SQLJobID is null

					end
				end

			-- Update the values to determine to stay in the job start loop
			Select @tEnabled=[ThrottlerEnabled], @MaxJobs=MaxJobs, @WiredJobMaxRunMinutes=WiredJobMaxRunMinutes 
				from JobThrottlerSettings;
	
			if @tEnabled=1
			Begin
				Select @WaitingJobs=count(JobID)
					from JobLog
					where StartTime is Null and CancelTime is null;

				SELECT @RunningJobs=count(ja.job_id)
					FROM msdb.dbo.sysjobactivity ja 
						LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
						JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
						JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
					WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
						AND start_execution_date is not null
						AND stop_execution_date is null
			End

		End  -- End of Part 1 - Job Start Section

		-- Part 2 - CHECK TO SEE IF ANY JOBS ARE RUNNING PAST THE MAXIMUM TIME LIMIT
		DECLARE OverLimit CURSOR FOR
		Select x.Job_ID as JobToCancel, x.WiredJobID from 
			(SELECT ja.job_id, 
				iif(datediff(mi,start_execution_date, getdate())>=@WiredJobMaxRunMinutes,1,0) as KillJob,
				dbo.ExtractJobIDFromBrackets(j.name) as WiredJobID
			FROM msdb.dbo.sysjobactivity ja 
				LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
				JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
				JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
			WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
				AND start_execution_date is not null
				AND stop_execution_date is null) x
				Where x.KillJob=1 and x.WiredJobID>0
		OPEN OverLimit
		FETCH NEXT FROM OverLimit INTO @JobToCancel, @WiredJobID;
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			Exec msdb.dbo.sp_stop_job @job_id = @JobToCancel;
			
			Select Top 1 @JobStepID=StepID from JobSteps
				where JobID=@WiredJobID
					and startedstamp is not null 
					and completedstamp is null 
					and failedstamp is null;
			if @@ROWCOUNT=1
				--Insert into JobStepLog(JobId, JobStepID, LogInformation, LogInfoType, LogInfoSource, LogStamp)
				--	values(@WiredJobID, @JobStepID, 'Job Cancelled due to exceeding maximum runtime of ' 
				--	+ convert(varchar, @WiredJobMaxRunMinutes) + ' minutes',1,'JobControl.dbo.JobThrottle', getdate());

					declare @LogInfo varchar(50) = 'Job Cancelled due to exceeding maximum runtime of ' 
					+ convert(varchar, @WiredJobMaxRunMinutes) + ' minutes'

					exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, 'JobControl.dbo.JobThrottle'

			Update JobControl..JobSteps set failedstamp=getdate() 
				where JobID=@WiredJobID 
					and startedstamp is not null 
					and completedstamp is null 
					and failedstamp is null;
			FETCH NEXT FROM OverLimit INTO @JobToCancel, @WiredJobID;
		END 
		CLOSE OverLimit 
		DEALLOCATE OverLimit
		-- End of Part 2

		if @WaitingJobs>5
			WAITFOR DELAY '00:00:05'; --Pause for 5 seconds
		else
			WAITFOR DELAY '00:00:15'; --Pause for 15 seconds

		-- Code added 11/22/2019 - Mark W.
		-- Get the Stop Time of recently run jobs and then delete the SQL Agent Job
		--DECLARE TempDelJobs CURSOR FOR
		--	Select jl.StartTime, jl.SQLJobID as SQLdJobID -- Get all the jobs that started in the last 24 hours that don't have an EndTime
		--		From JobLog jl
		--			join Jobs j on j.JobID = jl.JobID
		--		Where jl.StartTime is not null
		--			and jl.EndTime is null
		--			and j.FailedStamp is null
		--			and jl.StartTime>=dateadd(hh,-24,getdate())
		--		Order by jl.ID desc

		DECLARE TempDelJobs CURSOR FOR
			select starttime, SQLJObID
				from (
					select js.JobID, jl.SQLJobID, Max(js.StartedStamp) starttime
						, count(*) steps, sum(case when js.CompletedStamp >=dateadd(hh,-24,getdate()) then 1 else 0 end) CompSteps
						from JobControl..JobSteps js
							join ( select j.JobID, sj.job_id SQLJobID, sj.name
										from msdb.dbo.sysjobs sj
											join JobControl..Jobs j  on sj.name like '%![' + ltrim(str(j.JobID)) + '!]'  ESCAPE '!'
										group by j.JobID, sj.job_id, sj.name
								) jl on js.JobID = jl.JobID
						group by js.JobID, jl.SQLJobID
				) x
				where steps = CompSteps

		OPEN TempDelJobs
		FETCH NEXT FROM TempDelJobs INTO @StartTime, @SQLdJobID;
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			Select Top 1 @StopTime=stop_execution_date
				from msdb.dbo.sysjobactivity 
				where job_ID=@SQLdJobID 
					and start_execution_date>=dateadd(ss,-5,@StartTime)
	
			If @StopTime is not null
				Begin
					Select top 1 @result=[message]
						From msdb.dbo.sysjobhistory 
						Where job_ID=@SQLdJobID
							and msdb.dbo.agent_datetime(run_date,run_time)>=dateadd(ss,-5,@StartTime)
							and step_id=0
							and step_name='(Job outcome)';
					Update JobLog 
						Set EndTime=@StopTime, JobOutcome=@result
						Where SQLJobID=@SQLdJobID and StartTime=@StartTime;

					Exec JobControl..UpdateLastRunFields @SQLdJobID;

					--Comment out the two lines below if you temporarily want to stop 
					--deleting the SQL Agent jobs after they complete.
					if @DeleteCompletedJobs = 1
					Begin
						Delete from msdb.dbo.sysjobs where Job_ID=@SQLdJobID;
						Delete from msdb.dbo.sysjobsteps where Job_ID=@SQLdJobID;
					end
				End

			FETCH NEXT FROM TempDelJobs INTO @StartTime, @SQLdJobID;
		END 
		CLOSE TempDelJobs
		DEALLOCATE TempDelJobs

		-- Before we get to the bottom of the loop, refresh variables
		Select @tEnabled=[ThrottlerEnabled], @MaxJobs=MaxJobs, @WiredJobMaxRunMinutes=WiredJobMaxRunMinutes 
			from JobThrottlerSettings;

		if @tEnabled=1
		Begin
			Select @WaitingJobs=count(JobID)
				from JobLog
				where StartTime is Null and CancelTime is null;
			SELECT @RunningJobs=count(ja.job_id)
				FROM msdb.dbo.sysjobactivity ja 
					LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
					JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
					JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
				WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
					AND start_execution_date is not null
					AND stop_execution_date is null
		End

	END -- END OF MAIN LOOP


	--if @DeleteCompletedJobs = 1
	--Begin
	--	declare @SQLdJobID2 varchar(40)

	--	DECLARE TempDelJobs2 CURSOR FOR
	--		select distinct sj.Job_id
	--			from msdb.dbo.sysjobs sj
	--				join msdb.dbo.sysjobactivity ja on ja.job_id = sj.job_id
	--			where datediff(ss,ja.start_execution_date,getdate()) > 4

	--	OPEN TempDelJobs2
	--	FETCH NEXT FROM TempDelJobs2 INTO @SQLdJobID2;
	--	WHILE @@FETCH_STATUS = 0  
	--	BEGIN
						
	--		Delete from msdb.dbo.sysjobs where Job_ID=@SQLdJobID2;
	--		Delete from msdb.dbo.sysjobsteps where Job_ID=@SQLdJobID2;

	--		FETCH NEXT FROM TempDelJobs2 INTO @SQLdJobID2;
	--	END 
	--	CLOSE TempDelJobs2
	--	DEALLOCATE TempDelJobs2

	--end


END
