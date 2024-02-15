/****** Object:  Procedure [dbo].[CreateNewJob_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[CreateNewJob] @JobTemplateID int
AS
BEGIN
	SET NOCOUNT ON;

	insert JobControl..Jobs (CreatedStamp, JobTemplateID, CategoryID, JobName, ModeID, RecurringTypeID, PromptState
								, PromptIssueWeek, ProcessTypeID, VFPIn) 
                        select getdate(), JobID, CategoryID, JobName, ModeID, RecurringTypeID, PromptState
								, PromptIssueWeek, ProcessTypeID, VFPIn
                            from JobControl..Jobs
                        where JobID = @JobTemplateID and IsTemplate = 1

	declare @NewJobID int, @NewQueryID int

    set @NewJobID = SCOPE_IDENTITY()

	insert JobSteps (JobID, StepName, StepOrder, StepTypeID
                    --, DependsOnStep
                    , StepFileNameAlgorithm, FileSourcePath, FileSourceExt, AllowMultipleFiles
                    , RunModeID, RequiresSetup, QueryCriteriaID, ReportListID, QueryTemplateId
                    , TransformationID, FileLayoutID, SpecialID, StepSubProcessID, VFPIn
					, VFP_LayoutID, VFP_QueryID, VFP_ReportID)
        select @NewJobID,  StepName, StepOrder, StepTypeID
                    --, DependsOnStep
                    , StepFileNameAlgorithm, FileSourcePath, FileSourceExt, AllowMultipleFiles
                    , RunModeID, RequiresSetup, QueryCriteriaID, ReportListID, QueryTemplateId
                    , TransformationID, FileLayoutID, SpecialID, StepSubProcessID, VFPIn
					, VFP_LayoutID, VFP_QueryID, VFP_ReportID
		        from JobSteps
		        where JobID = @JobTemplateID
                order by StepOrder 

	exec SetDependsOnStepIDs @NewJobID

	declare @StepID int, @QueryCriteriaID int

	DECLARE CNJcurA CURSOR FOR
		select StepID, QueryCriteriaID 
							from JobControl..JobSteps 
						where QueryCriteriaID is not null 
							and JobID = @NewJobID

     OPEN CNJcurA

     FETCH NEXT FROM CNJcurA into @StepID, @QueryCriteriaID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
			exec @NewQueryID = QueryEditor..CloneQuery @QueryCriteriaID

			update JobControl..JobSteps set QueryCriteriaID = @NewQueryID where StepID = @StepID 

          FETCH NEXT FROM CNJcurA into @StepID, @QueryCriteriaID
     END
     CLOSE CNJcurA
     DEALLOCATE CNJcurA


END
