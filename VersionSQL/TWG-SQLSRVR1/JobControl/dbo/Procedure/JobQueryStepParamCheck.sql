/****** Object:  Procedure [dbo].[JobQueryStepParamCheck]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JobQueryStepParamCheck @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;


	select * 
	from (
	select case when qp.MapParamID > 0 and coalesce(j.PromptIssueWeek,0) = 0 and coalesce(j.PromptIssueMonth,0) = 0 and coalesce(j.PromptCalYear,0) = 0 and coalesce(j.PromptCalPeriod,0) = 0 
					then 'Query Expects Job Prompt of ' + coalesce(qpt.ReplaceValName,'') + ' but Job Prompt is not set'
				when qp.MapParamID <> case when j.PromptIssueWeek = 1 then 1 
												when j.PromptIssueMonth = 1 then 2 
												when j.PromptCalYear = 1 or j.PromptCalPeriod = 1 then 3
												else 0 end
					then 'Job Prompt is set but Query mapping does not match'
				when coalesce(qp.MapParamID,0) = 0 
						and (coalesce(j.PromptIssueWeek,0) = 1 or coalesce(j.PromptIssueMonth,0) = 1 or coalesce(j.PromptCalYear,0) = 1 or coalesce(j.PromptCalPeriod,0) = 1)
						and QueryTemplateID not in (1060)
					then 'Job Prompt is set but query map is not set'
				else '' end Issue

			, case when qp.MapParamID > 0 and coalesce(j.PromptIssueWeek,0) = 0 and coalesce(j.PromptIssueMonth,0) = 0 and coalesce(j.PromptCalYear,0) = 0 and coalesce(j.PromptCalPeriod,0) = 0 
					then 3
				when qp.MapParamID <> case when j.PromptIssueWeek = 1 then 1 
												when j.PromptIssueMonth = 1 then 2 
												when j.PromptCalYear = 1 or j.PromptCalPeriod = 1 then 3
												else 0 end
					then 3
				when coalesce(qp.MapParamID,0) = 0 
						and (coalesce(j.PromptIssueWeek,0) = 1 or coalesce(j.PromptIssueMonth,0) = 1 or coalesce(j.PromptCalYear,0) = 1 or coalesce(j.PromptCalPeriod,0) = 1)
						and QueryTemplateID not in (1060)
					then 2
				else 1 end IssueLevel
			, j.JobID, j.JobName, j.InProduction, j.Deleted, j.disabled
			, j.PromptIssueWeek, j.PromptIssueMonth, j.PromptCalYear, j.PromptCalPeriod
			, case when j.PromptIssueWeek = 1 then 1 
					when j.PromptIssueMonth = 1 then 2 
					when j.PromptCalYear = 1 or j.PromptCalPeriod = 1 then 3
					else 0 end JobPromptForID
			, js.QueryTemplateID
			, qp.ParamTypeID, qp.MapParamID

		from JobControl..JobSteps js 
			join JobControl..Jobs j on j.jobID = js.JobID
			left outer join QueryEditor..QueryParameters qp on qp.QueryID = js.QueryCriteriaID and qp.MapParamID > 0
			left outer join QueryEditor..QueryParamTypes qpt on qpt.ID = qp.ParamTypeID

		where coalesce(js.Disabled,0) = 0 and js.QueryTemplateID > 0
			and js.stepID = @JobStepID
	) x

	where Issue > ''







END
