/****** Object:  Procedure [dbo].[JobThrottler_GetNextJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JobThrottler_GetNextJob
AS
BEGIN
	SET NOCOUNT ON;
	
	select top 1 JobID
			, JobName, QueueRunPriority
			, case when PrebuildJob = 1 and PrebuildStarted = 0 and PreBuildComplete = 0 then 1	-- Unbuilt Prebuilds first  
				else QueueRunPriority end UseRunPriority
			, case when RunningJobs >= MaxJobs or IsRunning = 1 then 0 
					when PrebuildJob = 1 then 
						case when PreBuildComplete = 1 then 1
								when PrebuildStarted = 0 and PreBuildComplete = 0 then 1
								when PrebuildStarted = 1 and PreBuildComplete = 0 then 0
							else 0 end
					when DependsOnJobs > 0 then DependsOnJobsAreComplete
				else 1 end Runnable
			, QueueJobParams
			, PrebuildJob, PrebuildStarted, PreBuildComplete
			, QueuedByUser, QueueTime
			, PreBuildTableName
			, JobLogRecID
		from (
			select j.JobID, J.JobName, jl.RunPriority QueueRunPriority
				, jl.ID JobLogRecID
				, jl.QueueJobParams, jl.CreateUser QueuedByUser, jl.QueueTime
				, trj.RunningJobs, trj.RunningOvernightJobs
				, case when rj.JobId > 0 then 1 else 0 end IsRunning 
				, case when jpb.JobID > 0 then 1 else 0 end PrebuildJob
				, jpb.PreBuildTableName
				, jt.MaxJobs
				, coalesce(apb.PrebuildStarted,0) PrebuildStarted
				, case when OBJECT_ID(jpb.PreBuildTableName, 'U') is not null 
							and case when jpb.JobID > 0 then 1 else 0 end = 1
							and jpb.PreBuildTableName = apb.PreBuildTableName
					then 1 else 0 end PreBuildComplete
				, coalesce(dpj.Jobs,0) DependsOnJobs
				, dpj.DependsOnJobsAreComplete
			from JobControl..JobLog jl
				join JobControl..Jobs j on j.JobID = jl.JobID
				join (select count(*) RunningJobs, sum(case when RunPriority = 6 then 1 else 0 end) RunningOvernightJobs  from JobControl..vRunningJobs) trj on 1=1
				left outer join JobControl..vRunningJobs rj on rj.JobId = jl.JobID
				join (select MaxJobs from JobControl..JobThrottlerSettings) jt on 1=1
				left outer join (select distinct j.jobID, jl.QueueJobParams
									, JobControl.dbo.PreBuildTableName2(js.StepID, jl.QueueJobParams) PreBuildTableName
								from JobControl..JobSteps js 
									join JobControl..Jobs j on j.JobID=js.JobID
									join JobControl..JobLog jl on jl.JobID = js.JobID
								where isnull(js.PrebuildQuery,0) = 1
									and coalesce(j.disabled,0) = 0
									AND jl.CancelTime IS NULL
									AND jl.StartTime IS NULL	
									and jl.QueueTime > dateadd(HOUR, -24, getdate())
								) jpb on jpb.JobID = j.JobID and jpb.QueueJobParams = jl.QueueJobParams
				left outer join ( select JobControl.dbo.PreBuildTableName2(js.StepID, jl.QueueJobParams) PreBuildTableName
											, Max(case when jl.PrebuildStarted = 1 then 1 else 0 end) PrebuildStarted
										from JobControl..JobSteps js 
												join JobControl..Jobs j on j.JobID=js.JobID
												join JobControl..JobLog jl on jl.JobID = js.JobID
										where isnull(js.PrebuildQuery,0) = 1
											and jl.CancelTime is null
											and jl.QueueTime > dateadd(HOUR, -24, getdate())
										group by JobControl.dbo.PreBuildTableName2(js.StepID, jl.QueueJobParams)
								) apb on jpb.PreBuildTableName = apb.PreBuildTableName
				left outer join ( 	select distinct jl.JobID
									, doj.Jobs,  doj.CompleteJobs, doj.MaxLastJobParameters, doj.DistinctLastJobParameters
									, case when doj.Jobs = doj.CompleteJobs then 1 else 0 end DependsOnJobsAreComplete
								from JobControl..JobLog jl
									join JobControl..Jobs j on jl.JobId = j.JobID
									join (select JobID, Count(*) Jobs, Max(LastJobParameters) MaxLastJobParameters, count(distinct LastJobParameters) DistinctLastJobParameters
													, sum(case when TotalSteps = CompletedSteps and failedSteps = 0 then 1 else 0 end) CompleteJobs 
											from JobControl..vDependsOnJobsStatus
											group by JobiD
										) doj on jl.JobID = doj.JobID 
								) dpj on dpj.JobID = j.JobID

				where QueueTime > dateadd(HOUR, -24, getdate())
					and jl.StartTime is null and jl.CancelTime is null and jl.EndTime is null
			) x
			where case when RunningJobs >= MaxJobs or IsRunning = 1 then 0
				when QueueRunPriority = 6 then case when RunningJobs - coalesce(RunningOvernightJobs,0) = 0 and getdate() > convert(datetime,convert(varchar(15),convert(date,QueueTime)) + ' 6:00 PM') then 1 else 0 end
					when PrebuildJob = 1 then 
						case when PreBuildComplete = 1 then 1
								when PrebuildStarted = 0 and PreBuildComplete = 0 then 1
								when PrebuildStarted = 1 and PreBuildComplete = 0 then 0
							else 0 end
					when DependsOnJobs > 0 then DependsOnJobsAreComplete
				else 1 end= 1
			order by 4, QueueTime

END
