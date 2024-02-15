/****** Object:  Procedure [dbo].[JobThrottler_GetNextJob_Pre05212022]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W./Mike
-- Create date: 12/26/2019
-- Description:	Get next job for the Job Throttler to start
-- =============================================
create PROCEDURE dbo.JobThrottler_GetNextJob_Pre05212022
	@NextID int output
AS
BEGIN
	SET NOCOUNT ON;
	
	set @NextID = null

	declare @PriorityPace int
	-- PriorityPace Controls that all Matching Priorities get run before larger Prioities get run

	-- Find current Running priority
	--select @PriorityPace = min(RunPriority)
	--	--from JobLog
	--	--	where CancelTime is null and EndTime is null
	--	--		and StartTime > '1/1/2020'  -- this because EndTime is a new field and is not filled prior to 11/22/2019
	--	from JobControl..JobLog jl
	--			join JobControl..Jobs j on j.JobID = jl.JobID
	--	where j.StartedStamp is not null and j.FailedStamp is null and j.CompletedStamp is null and j.DeletedStamp is null
	--			and CancelTime is null and EndTime is null
	--					and jl.StartTime > '1/1/2020' -- this because EndTime is a new field and is not filled prior to 11/22/2019

	select @PriorityPace = min(jl.RunPriority)
		from JobControl..JobLog jl
				join JobControl..vRunningJobs rj on rj.JobID = jl.JobID

		Select top 1 @NextID=z.ID from
		(-- * First Query - Get the first job (based on JobID) for any jobs that require a PreBuild Table that does not exist
			Select Min(RunPriority) RunPriority, 0 SubPriority, getdate() as QueueTime
					, min(ID) ID, count(*) Jobs, PreBuildTableName
					, case when OBJECT_ID(PreBuildTableName, 'U') is not null then 1 else 0 end TableExists
					, x.JobID
				from (
					select distinct jl.id, j.jobID, jl.RunPriority
							, JobControl.dbo.PreBuildTableName(js.StepID,q.SQLCmd) PreBuildTableName
						from JobControl..JobSteps js 
							join QueryEditor..Queries q on js.QueryCriteriaID = q.ID
							join JobControl..Jobs j on j.JobID=js.JobID
							join JobControl..JobLog jl on jl.JobID=j.JobID
						where isnull(js.PrebuildQuery,0) = 1
							--and case when @PriorityPace is null then 1
							--		when jl.RunPriority = @PriorityPace then 1
							--		else 0 end = 1
							--and jl.StartTime>='12/23/2019'  -- used for testing to return results
							and jl.StartTime is null and jl.CancelTime is null
							and JobControl.dbo.PreBuildTableName(js.StepID,q.SQLCmd) not in (Select * from PreBuildsCurrentlyRunning())
							and j.SQLJobID not in ( SELECT ja.job_id
										FROM msdb.dbo.sysjobactivity ja 
											LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
											JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
											JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
										WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
											AND start_execution_date is not null
											AND stop_execution_date is null)
					) x
				where case when OBJECT_ID(PreBuildTableName, 'U') is not null then 1 else 0 end = 0
				group by PreBuildTableName, x.JobID
		union 
			-- Get any waiting jobs that require a prebuild that exists
			select RunPriority, 3 SubPriority, QueueTime
					, ID, 1 Jobs, PreBuildTableName
					, case when OBJECT_ID(PreBuildTableName, 'U') is not null then 1 else 0 end TableExists
					, x.JobID
			from (
				select distinct jl.id, jl.RunPriority, jl.QueueTime, j.jobID
						, JobControl.dbo.PreBuildTableName(js.StepID,q.SQLCmd) PreBuildTableName
					from JobControl..JobSteps js 
						join QueryEditor..Queries q on js.QueryCriteriaID = q.ID
						join JobControl..Jobs j on j.JobID=js.JobID
						join JobControl..JobLog jl on jl.JobID=j.JobID
					where isnull(js.PrebuildQuery,0) = 1
						--and case when @PriorityPace is null then 1
						--		when jl.RunPriority = @PriorityPace then 1
						--		else 0 end = 1
						--and jl.StartTime>='12/23/2019'
						and jl.StartTime is null and jl.CancelTime is null
						and JobControl.dbo.PreBuildTableName(js.StepID,q.SQLCmd) not in (Select * from PreBuildsCurrentlyRunning())
						and j.SQLJobID not in ( SELECT ja.job_id
									FROM msdb.dbo.sysjobactivity ja 
										LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
										JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
										JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
									WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
										AND start_execution_date is not null
										AND stop_execution_date is null)

				) x
			where case when OBJECT_ID(PreBuildTableName, 'U') is not null then 1 else 0 end = 1
		union 
			-- Get any other jobs that don't require a prebuild
			select distinct jl.RunPriority, 6 SubPriority, jl.QueueTime
					, jl.ID, 1 Jobs, '' PreBuildTableName, null TableExists
					, j.jobID
				from JobControl..JobSteps js 
					--join QueryEditor..Queries q on js.QueryCriteriaID = q.ID  \\MP Removed this line, Jobs do no need to have a Query to run, needed above becuase of Prebuild
					join JobControl..Jobs j on j.JobID=js.JobID
					join JobControl..JobLog jl on jl.JobID=j.JobID
				where isnull(js.PrebuildQuery,0) = 0
					--and case when @PriorityPace is null then 1
					--		when jl.RunPriority = @PriorityPace then 1
					--		else 0 end = 1
					--and jl.StartTime>='12/23/2019'
					and jl.StartTime is null and jl.CancelTime is null
					and (j.SQLJobID not in ( SELECT ja.job_id
								FROM msdb.dbo.sysjobactivity ja 
									LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
									JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
									JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
								WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
									AND start_execution_date is not null
									AND stop_execution_date is null)
						or j.SQLJobID is null)
		)  z
		--left outer join ( SELECT j.*
		--	FROM msdb.dbo.sysjobactivity ja 
		--		LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
		--		JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
		--		JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
		--	WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
		--		AND start_execution_date is not null
		--		AND stop_execution_date is null ) rsj on rsj.name like '%[[' + ltrim(str(z.JobID)) + ']]'
		--where rsj.job_id is null

		order by z.RunPriority, z.SubPriority, z.QueueTime;

	if @NextID is null
		set @NextID=0;

	return @NextID; 

END
