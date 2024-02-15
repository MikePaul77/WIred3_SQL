/****** Object:  ScalarFunction [dbo].[IsLastStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION IsLastStep 
(
	@JobStepID int
)
RETURNS bit
AS
BEGIN
	
		declare @LastStepID int

		select top 1 @LastStepID = StepID
			from JobControl..JobSteps
			where coalesce(Disabled,0) = 0
				and JobID = (select jobID	
								from JobControl..JobSteps
								where StepID = @JobStepID)
			order by StepOrder desc

	declare @result bit = 0
	if @LastStepID = @JobStepID
		set @result = 1

	return @result

END
