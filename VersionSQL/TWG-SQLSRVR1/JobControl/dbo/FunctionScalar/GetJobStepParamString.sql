/****** Object:  ScalarFunction [dbo].[GetJobStepParamString]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.GetJobStepParamString
(
	@JobStepID int, @ParamName varchar(100)
)
RETURNS varchar(500)
AS
BEGIN
	declare @result varchar(500) = null

	select @result = jp.ParamValue
		from JobParameters jp
				join Jobs j on jp.JobID = j.JobID
				join JobSteps js on j.JobID = js.JobID
			where js.StepID = @JobStepID
				and ParamName = @ParamName

	return @result

END
