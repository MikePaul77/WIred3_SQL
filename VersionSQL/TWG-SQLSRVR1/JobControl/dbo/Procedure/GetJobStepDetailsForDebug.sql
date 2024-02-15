/****** Object:  Procedure [dbo].[GetJobStepDetailsForDebug]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE GetJobStepDetailsForDebug @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @StepTypeID int, @JobID int, @JobTemplateID int
	declare @JobStepQueryID int, @JobTemplateQueryID int
	declare @JobName varchar(500), @JobTemplateName varchar(500), @JobStepName varchar(500)

	select @StepTypeID = js.StepTypeID
			, @JobID = j.JobID
			, @JobName = j.JobName
			, @JobTemplateName = jt.Description
			, @JobTemplateID = j.JobTemplateID
			, @JobStepQueryID = js.QueryCriteriaId 
			, @JobTemplateQueryID = jts.QueryCriteriaId
			, @JobStepName = js.StepName 
		from JobControl..JobSteps js
			join JobControl..Jobs j on j.JobID = js.JobID
			join JobControl..JobTemplates jt on j.JobTemplateID = jt.TemplateID
			join JobControl..JobTemplateSteps jts on jt.TemplateID = jts.TemplateID and js.StepOrder = jts.StepOrder
		where js.StepID = @JobStepID

		Print 'Job ID: ' + ltrim(str(@JobID))
		print 'Job Name: ' + @JobName
		Print 'Job TemplateID: ' + ltrim(str(@JobTemplateID))
		print 'Job Template Name: ' + @JobTemplateName
		Print 'Step : ' + @JobStepName
		Print '=================================='
	if @StepTypeID = 21
	begin
		Print 'Query Step: ' + ltrim(str(@JobStepID))
		Print '-----------------------'
		Print 'Template Query Details Query ID: ' + ltrim(str(@JobTemplateQueryID))
		exec JobControl..VFPJobs_QueryDetails @JobTemplateQueryID
		Print '-----------------------'
		Print 'Job Query Details Query ID: ' + ltrim(str(@JobStepQueryID))
		exec JobControl..VFPJobs_QueryDetails @JobStepQueryID
	end



END
