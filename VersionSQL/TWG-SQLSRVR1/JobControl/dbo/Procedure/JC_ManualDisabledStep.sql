/****** Object:  Procedure [dbo].[JC_ManualDisabledStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_ManualDisabledStep @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	--exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

	update JobControl..JobSteps set WaitStamp = null where StepID = @JobStepID

	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

END
