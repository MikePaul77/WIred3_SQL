/****** Object:  Procedure [dbo].[VFPJobs_Test]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE VFPJobs_Test @mark varchar(50), @JobID int , @JobType varchar(50)
AS
BEGIN
	SET NOCOUNT ON;

	declare @cnt int

	select @cnt = count(*)
			from JobControl..JobTemplateSteps js
				join JobControl..JobTemplates jt on jt.TemplateID = js.TemplateID
				where js.VFPIn = 1
				and jt.Type = 'CUBWKL'
				and StepTypeID = 22

	if @cnt > 0
		begin

			select js.ID, js.TemplateID, js.StepOrder, js.StepTypeID
				, js.StepFileNameAlgorithm
				, @mark Mark, @JobID, @JobType
			from JobControl..JobTemplateSteps js
				join JobControl..JobTemplates jt on jt.TemplateID = js.TemplateID
				where js.VFPIn = 1
				and jt.Type = 'CUBWKL'
				and StepTypeID = 22

		end
END
