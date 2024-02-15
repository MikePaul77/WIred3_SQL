/****** Object:  Procedure [dbo].[JobControlClearJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE JobControlClearJob @JobID int, @QueueAt datetime
AS
BEGIN
	SET NOCOUNT ON;

        --  Manual steps are skipped once completed
        --      "required setup" steps are done at job creation and marked as complete
        --  So clearing jobs does not clear manual steps "required steps"

		update Jobs set RunAtStamp = @QueueAt
                , StartedStamp = null
                , CompletedStamp = null
                , FailedStamp = null
         where JobID = @JobID;

        update js set RunAtStamp = @QueueAt
				, StartedStamp = null
				, WaitStamp = case when js.RunModeID = 3 and js.RequiresSetup = 0 then @QueueAt else null end
				, CompletedStamp = null
				, FailedStamp = null
            from JobSteps js
                join JobStepTypes jst on jst.StepTypeID = js.StepTypeID
            where (js.RunModeID = 1 or (js.RunModeID = 3 and js.RequiresSetup = 0))
                and JobID = @JobID;

END
