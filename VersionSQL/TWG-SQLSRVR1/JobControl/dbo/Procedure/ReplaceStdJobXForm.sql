/****** Object:  Procedure [dbo].[ReplaceStdJobXForm]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE ReplaceStdJobXForm @JobID int, @NewXFormID int
AS
BEGIN
	SET NOCOUNT ON;

	update tt set tt.MasterXForm = 0
	        from JobControl..Jobs j
		        join JobControl..JobSteps tjs on tjs.JobID = j.jobID and tjs.StepTypeID = 29
		        join JobControl..TransformationTemplates tt on tt.Id = tjs.TransformationID
	        where j.JOBID = @JobID;

	update JobControl..TransformationTemplates set MasterXForm = 1 where ID = @NewXFormID;

	update JobControl..TransformationTemplates set AutoName = JobControl.dbo.AutoXFormLayoutName(ID,null) where ID = @NewXFormID;

	update js set TransformationID = @NewXFormID, FileLayoutID = fl.ID
		from JobControl..JobSteps js
			join JobControl..FileLayouts fl on fl.TransformationTemplateId = @NewXFormID and DefaultLayout = 1
		where jobID = @JobID and stepTypeID = 29;

END
