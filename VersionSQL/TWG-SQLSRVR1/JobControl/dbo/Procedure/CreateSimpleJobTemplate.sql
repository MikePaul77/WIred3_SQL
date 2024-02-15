/****** Object:  Procedure [dbo].[CreateSimpleJobTemplate]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE CreateSimpleJobTemplate
AS
BEGIN
	SET NOCOUNT ON;

	declare @SimpleJobID int

	select @SimpleJobID = JobID from Jobs where JobName = 'Simple Job Template'

	if @SimpleJobID is null
	begin

		insert JobControl..Jobs (CreatedStamp, JobTemplateID, JobName, disabled, RecurringTypeID, CategoryID, ModeID
								, PromptState, PromptIssueWeek, PromptIssueMonth, PromptCalYear, PromptCalPeriod
								, ProcessTypeID, UpdatedStamp, IsTemplate)

    			select getdate(), -1, 'Simple Job Template', 0, 7, 18, 3
										, 0, 0, 0, 0, 0
										, 0, getdate(), 1

		declare @NewJobID int

		select @NewJobID = convert(int,SCOPE_IDENTITY())

		Insert JobControl..JobSteps ( JobID, StepName, StepOrder, StepTypeID, RunModeID, RequiresSetup, UpdatedStamp, CreatedStamp )
									select 	@NewJobID, 'Select Records', 1, 21, 1, 0, getdate(), getdate()
		Insert JobControl..JobSteps ( JobID, StepName, StepOrder, StepTypeID, RunModeID, RequiresSetup, UpdatedStamp, CreatedStamp )
									select 	@NewJobID, 'STransform Data', 2, 29, 1, 0, getdate(), getdate()
		Insert JobControl..JobSteps ( JobID, StepName, StepOrder, StepTypeID, RunModeID, RequiresSetup, UpdatedStamp, CreatedStamp )
									select 	@NewJobID, 'Create Extract', 3, 22, 1, 0, getdate(), getdate()
		Insert JobControl..JobSteps ( JobID, StepName, StepOrder, StepTypeID, RunModeID, RequiresSetup, UpdatedStamp, CreatedStamp )
									select 	@NewJobID, 'Deliver File(s)', 4, 1091, 1, 0, getdate(), getdate()

		update js set DependsOnStepIDs = ltrim(str(djs.StepID))
			from JobControl..JobSteps js
				left outer join JobControl..JobSteps djs on djs.jobid = js.jobID and djs.StepOrder = js.StepOrder -1
			where js.JobID = @NewJobID

	end




END
