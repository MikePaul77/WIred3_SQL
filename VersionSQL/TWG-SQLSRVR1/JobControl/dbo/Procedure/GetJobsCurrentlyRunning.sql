/****** Object:  Procedure [dbo].[GetJobsCurrentlyRunning]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 09-29-2018
-- Description:	Simple proc to return the currently running jobs
-- =============================================
CREATE PROCEDURE dbo.GetJobsCurrentlyRunning 
AS
BEGIN
	SET NOCOUNT ON;

	Declare @WaitingJobs int;
	declare @KillJob int;
	Select @KillJob=Convert(int, value) from [SQLStage].JobControl.dbo.Settings where Property='KillJobAfterMinutes';

	Select @WaitingJobs = count(JobID)
		from JobControl..JobLog (readpast) where StartTime is Null and canceltime is null;

	Select @WaitingJobs as WaitingJobs, MaxJobs, ThrottlerEnabled, convert(varchar(20), EnabledTime,22) as EnabledTime, 
			convert(varchar(20), DisabledTime,22) as DisabledTime, WiredJobMaxRunMinutes
		from JobThrottlerSettings

	SELECT ja.job_id, j.name AS job_name, convert(varchar(20), ja.start_execution_date,22) as start_execution_date,      
		    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id, Js.step_name, 
			Convert(varchar, getdate() - ja.start_execution_date, 108) as ElapsedTime,
			iif(datediff(mi,start_execution_date, getdate())>=@KillJob,1,0) as KillJob
			--, dbo.ExtractJobIDFromBrackets(j.name) as WiredJobID
			, wj.JObID as WiredJobID
			, wj.LastJobParameters
		FROM msdb.dbo.sysjobactivity ja 
			LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
			JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
			JOIN msdb.dbo.sysjobsteps js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
			join [SQLStage].JobControl.dbo.Jobs wj (readpast) on charindex(wj.JobName + ' [' + ltrim(str(wj.jobID)) + ']', j.name) > 0
		WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
			AND start_execution_date is not null
			AND stop_execution_date is null
		Order by ja.start_execution_date
END
