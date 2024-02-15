/****** Object:  Procedure [dbo].[MarkJobAsCancelled]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 12-22-2018
-- Description:	This code is used to cancel a scheduled or running job
-- =============================================
CREATE PROCEDURE dbo.MarkJobAsCancelled
	-- Add the parameters for the stored procedure here
	@JobID int
AS
BEGIN
	SET NOCOUNT ON;

	update JobControl..JobLog set CancelTime = getdate() 
		where JobID = @JobID 
			and StartTime is not null
			and CancelTime is null and EndTime is null

	if @@ROWCOUNT = 0
		Begin 
			--if exists( SELECT ja.job_id
			--				FROM msdb.dbo.sysjobactivity ja 
			--					LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
			--					Join JobControl..Jobs on ja.Job_Id=Jobs.SQLJobID
			--				WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY session_id DESC)
			--					AND JobControl..Jobs.JobID=@JobID
			--					AND start_execution_date is not null
			--					AND stop_execution_date is null)
					Update JobLog 
						set CancelTime=getdate() 
						where ID = ( select top 1 ID
									from JobControl..JobLog
										where JobID = @JobID 
											and StartTime is null
											and CancelTime is null and EndTime is null
								order by QueueTime desc )
		End
END
