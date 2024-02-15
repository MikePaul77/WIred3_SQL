/****** Object:  Procedure [dbo].[SetDependsOnStepIDs_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SetDependsOnStepIDs] @NewJobID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @StepID int, @DependsOnStepIDs varchar(100), @JobTemplateID int

     DECLARE curXA CURSOR FOR
		select js.StepID, jts.DependsOnStepIDs, j.JobTemplateID
			from JobControl..Jobs j
				join JobControl..JobSteps js on j.JobID = js.JobID
				join JobControl..JobSteps jts on jts.jobID = j.JobTemplateID and jts.StepOrder = js.StepOrder
			where j.jobID = @NewJobID
				and jts.DependsOnStepIDs > ''

     OPEN curXA

     FETCH NEXT FROM curXA into @StepID, @DependsOnStepIDs, @JobTemplateID 
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

			update JobControl..JobSteps
				set DependsOnStepIDs = null
					where StepID = @StepID

			declare @StepOrder int, @DepentsOnStepID int

			 DECLARE curXB CURSOR FOR
				select jts.StepOrder, js.StepID
					from JobControl..JobSteps jts
						join JobControl..JobSteps js on js.JobID = @NewJobID and js.StepOrder = jts.StepOrder
					where jts.jobID = @JobTemplateID
						and ',' + replace(@DependsOnStepIDs,' ', '') + ',' like '%,' + ltrim(str(jts.StepID)) + ',%'

			 OPEN curXB

			 FETCH NEXT FROM curXB into @StepOrder, @DepentsOnStepID
			 WHILE (@@FETCH_STATUS <> -1)
			 BEGIN

					update JobControl..JobSteps
						set DependsOnStepIDs = coalesce(DependsOnStepIDs,'') + ',' + ltrim(str(@DepentsOnStepID))
							where StepID = @StepID

				  FETCH NEXT FROM curXB into @StepOrder, @DepentsOnStepID
			 END
			 CLOSE curXB
			 DEALLOCATE curXB

			update JobControl..JobSteps
				set DependsOnStepIDs = substring(DependsOnStepIDs,2,500)
					where StepID = @StepID


          FETCH NEXT FROM curXA into @StepID, @DependsOnStepIDs, @JobTemplateID 
     END
     CLOSE curXA
     DEALLOCATE curXA

END
