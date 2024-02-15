/****** Object:  ScalarFunction [dbo].[GetDependsQueryJobStepID]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.GetDependsQueryJobStepID ( @JobStepID int) 
RETURNS int
AS
BEGIN

	DECLARE @DependsQueryJobStepID int = 0

	declare @QueryStepFound bit = 0
	declare @EndOfSteps bit = 0
	declare @StepTypeID int, @QueryStepID int

	set @QueryStepID = 0

	while @QueryStepFound = 0 and @EndOfSteps = 0
	begin


		select @DependsQueryJobStepID = coalesce(Djs.StepID,0)
				, @StepTypeID = Djs.StepTypeID
			from JobSteps js 
				left outer join JobStepTypes jst on jst.StepTypeID = js.StepTypeID
				left outer join JobSteps Djs on js.JobID = Djs.JobID and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(Djs.StepID)) + ',%'
				left outer join JobStepTypes Djst on Djst.StepTypeID = Djs.StepTypeID
		where js.StepID = @JobStepID



		if @StepTypeID in (21,1124)
			begin
				set @QueryStepFound = 1
				set @QueryStepID = @DependsQueryJobStepID
			end
		else
			begin
				if @DependsQueryJobStepID = 0
					set @EndOfSteps = 1
				set @JobStepID = @DependsQueryJobStepID
			end

	end
	
	if @QueryStepFound = 0
		set @QueryStepID = 0

	RETURN @QueryStepID

end
