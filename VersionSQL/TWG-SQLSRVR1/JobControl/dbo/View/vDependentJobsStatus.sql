/****** Object:  View [dbo].[vDependentJobsStatus]    Committed by VersionSQL https://www.versionsql.com ******/

create VIEW [dbo].[DependentJobsStatus]
AS

		select js.JobID
				, count(*) steps
				, sum(case when js.RunModeID = 3 then 1 else 0 end) ManualSteps
				, sum(case when js.CompletedStamp is not null then 1 else 0 end) CompletedSteps
				, sum(case when js.FailedStamp is not null then 1 else 0 end) FailedSteps
				, sum(case when js.StartedStamp is not null and js.CompletedStamp is null then 1 else 0 end) RunningSteps
				, sum(case when js.StartedStamp is null then 1 else 0 end) PendingSteps
				, min(case when js.CompletedStamp is null and js.FailedStamp is null then StepOrder else null end) NextStep
				, min(case when js.RunModeID = 3 and js.CompletedStamp is null then StepOrder else null end) NextManualStep
			from JobControl..JobSteps js
				join (select distinct j.JobID
							from JobControl..JobDepends jd
								join JobControl..jobs j on j.JobID = jd.JobID
															and coalesce(j.disabled,0) = 0
															and coalesce(j.Deleted,0) = 0
					) j2 on j2.JobID = js.JobID
			where coalesce(js.Disabled,0) = 0
			group by js.JobID
		
