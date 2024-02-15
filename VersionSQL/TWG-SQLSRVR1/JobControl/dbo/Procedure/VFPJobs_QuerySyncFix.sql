/****** Object:  Procedure [dbo].[VFPJobs_QuerySyncFix]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobs_QuerySyncFix @QueryStepID int, @XFromStepID int, @ForceQueryTemplateID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @QueryTemplateID int

	if @ForceQueryTemplateID is not null
		begin
			set @QueryTemplateID = @ForceQueryTemplateID

			update tt set QueryTemplateID = @ForceQueryTemplateID
				from JobControl..TransformationTemplates tt
					join JobControl..JobSteps js on tt.Id = js.TransformationID
				where js.StepID =  @XFromStepID
		end
	else
		begin
			select @QueryTemplateID = tt.QueryTemplateID
				from JobControl..JobSteps js
					join JobControl..TransformationTemplates tt on tt.Id = js.TransformationID
				where js.StepID =  @XFromStepID
		end

	update js set QueryTemplateID = @QueryTemplateID
		from JobControl..JobSteps js
		where js.StepID =  @QueryStepID

	update q set TemplateID = @QueryTemplateID
		from QueryEditor..Queries q 
			join JobControl..JobSteps js on js.QueryCriteriaID = q.ID
		where js.StepID =  @QueryStepID


END
