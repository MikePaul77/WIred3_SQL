/****** Object:  Procedure [dbo].[JobThrottler]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JobThrottler 
AS
BEGIN
	SET NOCOUNT ON;

	declare @ManualMode bit = 0
		
	Declare @WaitingJobs int
			, @RunningJobs int
			, @tEnabled bit
			, @WiredJobMaxRunMinutes int
			, @NextJobID int
			, @JobLogRecID int

	declare @DeleteCompletedJobs bit = 1

	select @DeleteCompletedJobs = case when Value = '1' then 1 else 0 end
		from JobControl..Settings
		where Property = 'DeleteCompletedJobs'

	Select @tEnabled=[ThrottlerEnabled]
			, @WiredJobMaxRunMinutes=WiredJobMaxRunMinutes 
		from JobThrottlerSettings;

	if @ManualMode = 1
		set @tEnabled = 1

	if @tEnabled=1
		Begin
			-- Find out how many jobs are waiting and how many are currently running
			Select @WaitingJobs=count(ID)
				from JobLog
				where StartTime is Null and CancelTime is null;

			SELECT @RunningJobs=count(*)
				FROM JobControl..vRunningJobs

		End

	drop table if exists #NextJob 
	create table #NextJob (JobID int
						, JobName varchar(500), QueueRunPriority int, UseRunPriority int, Runnable bit
						, QueueJobParams varchar(50)
						, PrebuildJob bit, PrebuildStarted bit, PreBuildComplete bit
						, QueuedByUser varchar(100), QueueTime DateTime
						, PreBuildTableName varchar(300)
						, JobLogRecID int) 

	While @tEnabled=1
	Begin  

			set @NextJobID = -1
			set @JobLogRecID = -1

			truncate table #NextJob

			insert into #NextJob
				exec JobThrottler_GetNextJob

			select @NextJobID = JobID
					, @JobLogRecID = JobLogRecID
				from #NextJob

			if @JobLogRecID > 0
			begin
				
				print 'Start Job: @NextJobID: ' + ltrim(str(@NextJobID))  + ', @JobLogRecID: ' + ltrim(str(@JobLogRecID))

				exec JobControl..StartWiredJob @NextJobID, @JobLogRecID

			end

			-- Update the values to determine to stay in the job start loop
			Select @tEnabled=[ThrottlerEnabled], @WiredJobMaxRunMinutes=WiredJobMaxRunMinutes 
				from JobThrottlerSettings;

			if @ManualMode = 1
				set @tEnabled = 1
	
			if @tEnabled=1
				Begin
					-- Find out how many jobs are waiting and how many are currently running
					Select @WaitingJobs=count(ID)
						from JobLog
						where StartTime is Null and CancelTime is null;

					SELECT @RunningJobs=count(*)
						FROM JobControl..vRunningJobs

				End

			-- CHECK TO SEE IF ANY JOBS ARE RUNNING PAST THE MAXIMUM TIME LIMIT

			if @ManualMode = 0
			begin

				declare @JobToCancel varchar(100), @WiredJobID int, @JobStepID int

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

				declare @StartTime datetime, @StopTime datetime, @SQLdJobID varchar(40), @result nvarchar(4000)

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

				if @WaitingJobs > 0
					WAITFOR DELAY '00:00:05'; --Pause for 5 seconds
				else
					WAITFOR DELAY '00:00:15'; --Pause for 15 seconds
			end

		if @ManualMode = 1
			set @tEnabled = 0


	END -- END OF MAIN LOOP


END
