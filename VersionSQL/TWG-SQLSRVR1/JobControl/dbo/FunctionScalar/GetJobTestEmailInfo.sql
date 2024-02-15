/****** Object:  ScalarFunction [dbo].[GetJobTestEmailInfo]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION GetJobTestEmailInfo
(
	@JobStepID int, @JobID int
)
RETURNS varchar(100)
AS
BEGIN
	DECLARE @Result varchar(100)

		select @Result = case when coalesce(j.testmode, 0) = 1 and LTRIM( j.TestModeEmail) > '' then j.TestModeEmail
									when coalesce(j.testmode, 0) = 1 and LTRIM(coalesce(j.TestModeEmail, '')) = '' then 'do nothing'
									else 'normal' end
						 from JobControl..JobSteps js
								left outer join JobControl..Jobs J on J.JobID = js.JobID
						 where js.StepID = @JobStepID 
							or j.JobID = @JobID

	RETURN @Result

END
