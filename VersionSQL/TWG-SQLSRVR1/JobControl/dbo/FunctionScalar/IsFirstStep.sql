/****** Object:  ScalarFunction [dbo].[IsFirstStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION IsFirstStep 
(
	@JobStepID int
)
RETURNS bit
AS
BEGIN
	
		declare @FirstStepID int

		select @FirstStepID = StepID 
			from JobControl..JobSteps
			where coalesce(Disabled,0) = 0
				and StepOrder = 1
				and JobID = (select jobID	
								from JobControl..JobSteps
								where StepID = @JobStepID)
	declare @result bit = 0
	if @FirstStepID = @JobStepID
		set @result = 1

	return @result

END
