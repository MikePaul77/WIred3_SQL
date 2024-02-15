/****** Object:  Procedure [dbo].[JobThrottlerStartStop]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:	Mark W.
-- Create date: 10-14-2018
-- Description:	Starts or Stops the Job Throttler
-- =============================================
CREATE PROCEDURE dbo.JobThrottlerStartStop
	-- Add the parameters for the stored procedure here
	@action varchar(5)
AS
BEGIN
	SET NOCOUNT ON;
	Declare @ToggleBit bit;
	Select @ToggleBit=ThrottlerEnabled from JobThrottlerSettings;

	if @action='start'
		Begin
			--Update the JobThrottlerSettings record if not already running
			If @ToggleBit<>1
				Update JobThrottlerSettings set ThrottlerEnabled=1, EnabledTime=getdate(), LastUpdate=getdate()

			--Start the JobThrottler if it is not running
			If not Exists(	SELECT j.name AS job_name
							FROM msdb.dbo.sysjobactivity ja 
								JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
							WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
								AND start_execution_date is not null
								AND stop_execution_date is null
								AND j.name='Wired3 Job Throttling')
				Exec msdb.dbo.sp_start_job @job_name = 'Wired3 Job Throttling';

			--Make sure the scheduler is set to fire each minute in case it stops
			EXEC msdb.dbo.sp_update_schedule  
			    @name = 'Wired3 Job Throttling Schedule',  
			    @enabled = 1;  
		End
	else
		Begin
			--Disable the Throttler
			If @ToggleBit<>0
				Update JobThrottlerSettings set ThrottlerEnabled=0, DisabledTime=getdate(), LastUpdate=getdate()

			--Stop the JobThrottler if it is running
			If Exists(	SELECT j.name AS job_name
							FROM msdb.dbo.sysjobactivity ja 
								JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
							WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
								AND start_execution_date is not null
								AND stop_execution_date is null
								AND j.name='Wired3 Job Throttling')
				Exec msdb.dbo.sp_stop_job @job_name = 'Wired3 Job Throttling';

			--Disable the Scheduler
			EXEC msdb.dbo.sp_update_schedule  
			    @name = 'Wired3 Job Throttling Schedule',  
			    @enabled = 0;  
		End
END
