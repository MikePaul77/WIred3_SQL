/****** Object:  Procedure [dbo].[EnableDisableProbateJobSteps]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE EnableDisableProbateJobSteps @JobID int, @QueryTemplateID int, @Disabled int
	--QueryTemplateID; pre probate 1132, probates 1133, divorce 1134
AS
BEGIN
	SET NOCOUNT ON;


	declare @querystepid int, @xformstepid int, @reportstepid int
		select @querystepid=js.StepID, @xformstepid = xs.StepID, @reportstepid = rs.StepID  
			from JobControl..JobSteps js
			join jobcontrol..jobsteps xs on ','+xs.DependsOnStepIDs+',' like ','+ltrim(str(js.StepID))+','
			join jobcontrol..jobsteps rs on ','+rs.DependsOnStepIDs+',' like ','+ltrim(str(xs.StepID))+','
			where js.JobID = @JobID and js.QueryTemplateID = @QueryTemplateID

	update JobControl..JobSteps
		set Disabled = @Disabled
		where StepID in (@querystepid, @xformstepid, @reportstepid)

END
