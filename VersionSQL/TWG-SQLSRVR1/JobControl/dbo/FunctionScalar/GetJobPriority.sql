/****** Object:  ScalarFunction [dbo].[GetJobPriority]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.GetJobPriority 
(
	@JobID int
)
RETURNS int
AS
BEGIN
	DECLARE @result int

	select @result = case when JobControl.dbo.GetJobDependenciesFunc(j.JobID, null, null, null, null, 'HasDependent') > 0 then 1
				when JobControl.dbo.GetJobDependenciesFunc(j.JobID, null, null, null, null, 'IsDependent') > 0 then 3
				else coalesce(RunPriority,3) end 
		from JobControl..Jobs j
		where JobID = @JobID

	RETURN @result

END
