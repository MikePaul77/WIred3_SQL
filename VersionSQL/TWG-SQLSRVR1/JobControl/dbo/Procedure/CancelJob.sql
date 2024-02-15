/****** Object:  Procedure [dbo].[CancelJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE CancelJob @JobID int
AS
BEGIN
	SET NOCOUNT ON;

		update JobControl..JobNotifications
			set NoticeSentStamp = getdate() 
			where NoticeSentStamp is null and JobID = @JobID

		update JobSteps set RunAtStamp =  case when RunAtStamp is not null and CompletedStamp is null and StartedStamp is null then null else RunAtStamp end
						, FailedStamp = case when CompletedStamp is null and StartedStamp is not null then getdate() else null end
						, WaitStamp = null
						, UpdatedStamp = getdate()
				where JobID = @JobID

		Exec JobControl..MarkJobAsCancelled @JobID

		declare @JobStepID int

		select top 1 @JobStepID = stepID
			from JobSteps 
			where FailedStamp is not null and JobID = @JobID
			order by StepID desc

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, 'Job was canceled by user.', 'JobControl'


END
