/****** Object:  Procedure [dbo].[UpdateJobStepNames]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.UpdateJobStepNames @JobID int 

AS
BEGIN
	SET NOCOUNT ON;

	update js set StepName = JobControl.dbo.AutoStepName(js.stepID)
	from JobControl..JobSteps js
		left outer join JobControl..JobStepTypes jst on jst.StepTypeID = js.StepTypeID
	where js.JobID = @JobID

END
