/****** Object:  ScalarFunction [dbo].[GetJobStepParamInt]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.GetJobStepParamInt
(
	@JobStepID int, @ParamName varchar(100)
)
RETURNS int
AS
BEGIN
	declare @result int = null

	select @result = case when isnumeric(jp.ParamValue) = 1 then convert(int,jp.ParamValue) else null end
		from JobParameters jp
				join Jobs j on jp.JobID = j.JobID
				join JobSteps js on j.JobID = js.JobID
			where js.StepID = @JobStepID
				and ParamName = @ParamName

	return @result

END
