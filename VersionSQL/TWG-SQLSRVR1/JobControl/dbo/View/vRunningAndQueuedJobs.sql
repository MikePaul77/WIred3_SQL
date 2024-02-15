/****** Object:  View [dbo].[vRunningAndQueuedJobs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE VIEW dbo.vRunningAndQueuedJobs
AS

select distinct j.JobID 
	from JobControl..Jobs j
		join JobControl..Jobsteps js on js.jobID = j.JobID and coalesce(js.Disabled,0) = 0
	where coalesce(j.Deleted,0) = 0
		and coalesce(j.disabled,0) = 0
		and js.StartedStamp is not null
		and js.FailedStamp is null
		and js.CompletedStamp is null
  -- select JobId 
		--from [SQLStage].WiredJobControlRun.dbo.vRunningJobs
 --  union 
	--select JobId 
	--	from [TWGNDSVR].WiredJobControlRun.dbo.vRunningJobs     
   union 
	select JobID 
		from JobControl..JobLog     
		where StartTime IS NULL and CancelTime IS NULL AND EndTime IS NULL AND QueueTime IS not NULL 		
