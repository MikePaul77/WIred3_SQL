/****** Object:  View [dbo].[vDependsOnJobsStatus]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE VIEW dbo.vDependsOnJobsStatus
AS


select jd.JobID, jd.DependsOnJobID, jds.steps TotalSteps, jds.CompletedSteps, jds.FailedSteps, jds.RunningSteps
		, jds.LastJobParameters
	from JobControl..JobDepends jd
		join (
			select js.JobID, j.LastJobParameters
					, count(*) steps
					, sum(case when js.RunModeID = 3 then 1 else 0 end) ManualSteps
					, sum(case when js.CompletedStamp is not null then 1 else 0 end) CompletedSteps
					, sum(case when js.FailedStamp is not null then 1 else 0 end) FailedSteps
					, sum(case when js.StartedStamp is not null and js.CompletedStamp is null then 1 else 0 end) RunningSteps
					, sum(case when js.StartedStamp is null then 1 else 0 end) PendingSteps
					, min(case when js.CompletedStamp is null and js.FailedStamp is null then StepOrder else null end) NextStep
					, min(case when js.RunModeID = 3 and js.CompletedStamp is null then StepOrder else null end) NextManualStep
				from JobControl..JobSteps js
					join JobControl..Jobs j on j.JobID = js.JobID
					join (select distinct j.JobID
								from JobControl..JobDepends jd
									join JobControl..jobs j on j.JobID = jd.DependsOnJobID
																and coalesce(j.disabled,0) = 0
																and coalesce(j.Deleted,0) = 0
						) j2 on j2.JobID = js.JobID
				where coalesce(js.Disabled,0) = 0
				group by js.JobID, j.LastJobParameters
			) jds on jd.DependsOnJobID = jds.JobID
		
	where jd.JobID > 0
		
