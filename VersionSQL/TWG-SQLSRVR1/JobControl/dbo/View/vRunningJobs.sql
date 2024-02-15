/****** Object:  View [dbo].[vRunningJobs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE VIEW dbo.vRunningJobs
AS

	SELECT ja.job_id SQLJobID, j.name AS SQLJobName
			, wj.JobName WiredJobName
			, wj.JObID as JobID
			, wj.RunPriority
		FROM msdb.dbo.sysjobactivity ja 
			LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
			JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
			JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
			join JobControl..Jobs wj on charindex(wj.JobName + ' [' + ltrim(str(wj.jobID)) + ']', j.name) > 0
		WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
			AND start_execution_date is not null
			AND stop_execution_date is null
		
