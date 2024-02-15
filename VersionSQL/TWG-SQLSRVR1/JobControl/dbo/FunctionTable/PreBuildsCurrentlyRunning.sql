/****** Object:  TableFunction [dbo].[PreBuildsCurrentlyRunning]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 12-30-2019
-- Description:	Called by JobControl..JobThrottler_GetNextJob
--				Returns a table of PreBuildTableNames for jobs currently running where the table does not exist yet.
--				We use this so we don't start a job that needs a prebuild file while another job is already running to build
--				that same file.
-- =============================================
CREATE FUNCTION dbo.PreBuildsCurrentlyRunning
(	
)
RETURNS TABLE 
AS
RETURN 
(
	Select distinct PreBuildTableName from
	(	-- Get the Prebuild table names and check for their existance
		Select PreBuildTableName, case when OBJECT_ID(PreBuildTableName, 'U') is not null then 1 else 0 end TableExists from
		(	-- Get all of the Prebuild table names that are running
			Select JobControl.dbo.PreBuildTableName(js.StepID,q.SQLCmd) PreBuildTableName
				from JobControl..JobSteps js 
					join QueryEditor..Queries q on js.QueryCriteriaID = q.ID
					join JobControl..Jobs j on j.JobID=js.JobID
				where js.PrebuildQuery = 1
					and j.jobID in 
						(	--SQL Agent Jobs currently running
							Select j.JobID 
								from Jobs j
								where j.JobID in 
									(	SELECT dbo.ExtractJobIDFromBrackets(j.name) as WiredJobID
											FROM msdb.dbo.sysjobactivity ja 
												LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
												JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
												JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
											WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
												AND start_execution_date is not null
												AND stop_execution_date is null )
							Union
								-- Jobs that have been told to start but the throttler might not have started them yet.
								Select JobID
									From JobLog
									Where StartTime>=DATEADD(hour, -3, getdate())
										and CancelTime is null
										and EndTime is null
						)
		) as x
	) as y
	where TableExists=0
)
