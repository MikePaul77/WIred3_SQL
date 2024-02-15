/****** Object:  ScalarFunction [dbo].[JobParamatersAreSet]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.JobParamatersAreSet
(
	@JobID int
)
RETURNS bit
AS
BEGIN
	DECLARE @Result bit

	--select @Result = case when count(*) = count(jp.ParamValue) then 1 else 0 end
	--from (
	--		select 'StateID' ParmName, JobID from JobControl..Jobs where JobID = @JobID and PromptState = 1
	--		union select 'IssueWeek' ParmName, JobID from JobControl..Jobs where JobID = @JobID and PromptIssueWeek = 1
	--	) pp
	--left outer join JobControl..JobParameters jp on jp.ParamName = pp.ParmName and jp.JobID = pp.JobID

	select @Result = case when count(*) = count(jp.ParamValue) then 1 else 0 end
	from (
			select 'StateID' ParmName, JobID from JobControl..Jobs where JobID = @JobID and PromptState = 1
			union select 'IssueWeek' ParmName, JobID from JobControl..Jobs where JobID = @JobID and PromptIssueWeek = 1
			union select 'IssueMonth' ParmName, JobID from JobControl..Jobs where JobID = @JobID and PromptIssueMonth = 1
			union select 'CalPeriod' ParmName, JobID from JobControl..Jobs where JobID = @JobID and PromptCalPeriod = 1
			union select 'CalYear' ParmName, JobID from JobControl..Jobs where JobID = @JobID and PromptCalYear = 1

		) pp
	left outer join JobControl..JobParameters jp on (jp.ParamName = pp.ParmName or jp.ParamName = 'FullLoad') and jp.JobID = pp.JobID


	RETURN @Result

END
