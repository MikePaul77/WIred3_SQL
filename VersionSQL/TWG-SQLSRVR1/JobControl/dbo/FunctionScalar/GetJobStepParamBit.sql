/****** Object:  ScalarFunction [dbo].[GetJobStepParamBit]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.GetJobStepParamBit
(
	@JobStepID int, @ParamName varchar(100)
)
RETURNS bit
AS
BEGIN
	declare @result bit = null

	select @result = case when jp.ParamValue in ('1','T','True','Y','Yes') then 1 else 0 end
		from JobParameters jp
				join Jobs j on jp.JobID = j.JobID
				join JobSteps js on j.JobID = js.JobID
			where js.StepID = @JobStepID
				and ParamName = @ParamName

	return @result

END
