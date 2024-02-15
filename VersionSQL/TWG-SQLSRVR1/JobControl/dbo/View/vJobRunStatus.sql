/****** Object:  View [dbo].[vJobRunStatus]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE VIEW dbo.vJobRunStatus
AS

	select j.JobID
			, j.JobName
			, case when (jss.CompletedJobSteps + jss.DisabledSteps) = jss.JobSteps then jss.LastCompletedStamp else null end CompletedStamp
			, jss.FirstFailedStamp FailedStamp
			, jss.FailedJobSteps FailedJobSteps
			, coalesce(j.NoticeOnFailure,0) NoticeOnFailure
			, coalesce(j.NoticeOnSuccess,0) NoticeOnSuccess
			, JobControl.dbo.GetJobTestEmailInfo(null, j.JobID) TestModeAction
			, j.LastRunFullJob
			, case when ((jss.CompletedJobSteps + jss.DisabledSteps + jss.FailedJobSteps) = jss.JobSteps) then 1 else 0 end JobHasFinishedLastStep
			, case when FirstFailedStamp >= LastCompletedStamp and FailedJobSteps > 0 then 1 else 0 end FailedStampMostRecent
			, case when LastStartedStamp > FirstFailedStamp and FailedJobSteps  > 0 then 1 else 0 end ContinutedAfterFail

		from JobControl..Jobs j
					join (select JobID
								, min(RunAtStamp) FirstRunAtStamp
								, min(StartedStamp) FirstStartedStamp
								, max(StartedStamp) LastStartedStamp
								, min(FailedStamp) FirstFailedStamp
								, max(CompletedStamp) LastCompletedStamp
								, max(WaitStamp) AnyWaitStamp
								, count(*) JobSteps
								, sum(case when js.Disabled = 1 then 1 else 0 end) DisabledSteps
								, sum(case when CompletedStamp is not null and FailedStamp is null and Disabled = 0 then 1 else 0 end) CompletedJobSteps 
								, count(FailedStamp) FailedJobSteps   
							from JobControl..JobSteps js
							group by JobID
						) jss on jss.JobID = j.JobID
						
