/****** Object:  ScalarFunction [dbo].[GetDependsJobStepID]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.GetDependsJobStepID ( @JobStepID int) 
RETURNS int
AS
BEGIN
	DECLARE @DependsJobStepID int = 0

	--select @DependsJobStepID = coalesce(js.DependsOnStepID, Pjs.StepID,0)
	--	from JobSteps js 
	--		join JobSteps Pjs on js.JobID = Pjs.JobID and (js.StepOrder - 1) = Pjs.StepOrder
	--	where js.StepID = @JobStepID

	select @DependsJobStepID = coalesce(Djs.StepID,0)
			from JobSteps js 
				left outer join JobStepTypes jst on jst.StepTypeID =js.StepTypeID
				left outer join JobSteps Djs on js.JobID = Djs.JobID and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(Djs.StepID)) + ',%'
				left outer join JobStepTypes Djst on Djst.StepTypeID = Djs.StepTypeID
		where js.StepID = @JobStepID

	RETURN @DependsJobStepID
end
