/****** Object:  Procedure [dbo].[ExtendedFilter_Unused]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 06-10-2019
-- Description:	Returns data for JobControl based on the Extended Filter Dropdown
-- =============================================
CREATE PROCEDURE [dbo].[ExtendedFilter] 
	@EFVal int,
	@DisabledVal int
AS
BEGIN
	SET NOCOUNT ON;
	Declare @SQL varchar(max)
	Declare @DisabledString varchar(50)
	if @DisabledVal>1
		set @DisabledString='1=1 '
	else
		set @DisabledString='isnull(j.disabled,0)=' + convert(varchar, @DisabledVal) + ' ';

	if @EFVal=1
		Begin
			Set @SQL='
			select j.JobID, j.JobName, coalesce(j.CategoryID,-1) CategoryID, coalesce(j.JobTemplateID,-1) JobTemplateID, j.RunAtStamp, j.StartedStamp, j.CompletedStamp, j.FailedStamp, j.WaitStamp
				, coalesce(rs.RunningSteps,0) RunningSteps, coalesce(jt.JobName,''--None--'') JobTemplateName, coalesce(jc.Description,''--None--'') JobCategoryName
				, coalesce(j.PromptState, 0) PromptState, coalesce(j.PromptIssueWeek, 0) PromptIssueWeek, coalesce(j.PromptIssueMonth, 0) PromptIssueMonth
				, coalesce(j.PromptCalYear, 0) PromptCalYear, coalesce(j.PromptCalPeriod, 0) PromptCalPeriod, coalesce(j.JobStateID, 0) JobStateID, coalesce(j.JobIssueWeek, 0) JobIssueWeek
				, coalesce(j.RecurringTypeID, 0) RecurringTypeID, coalesce(j.IsTemplate,0) IsTemplate, coalesce(j.Type,'''') Type, coalesce(j.TestMode,0) TestMode, j.LastJobLogID, j.LastJobParameters
			from JobControl..Jobs j
				left outer join (	select js.JobID, sum(case when js.StartedStamp is not null and js.CompletedStamp is null 
															   and js.FailedStamp is null then 1 else 0 end) RunningSteps 
										from JobControl..JobSteps js 
										group by js.JobID) rs on rs.JobID = j.JobID
				left outer join JobControl..JobCategories jc on jc.ID = j.CategoryID
				left outer join JobControl..Jobs jt on jt.JobID = j.JobTemplateID and jt.IsTemplate = 1
				join (	Select distinct js.JobID
							From JobSteps js
								join jobs j on j.jobid=js.jobid
								left outer join Jobs jt on jt.IsTemplate = 1 and jt.jobid = j.JobTemplateID
								left outer join JobSteps djs on '','' + js.DependsOnStepIDs + '','' like  ''%,'' + ltrim(str(djs.StepID)) + '',%''
							Where ' + @DisabledString + 
								'and js.StepTypeID=1091 
								and js.RunModeID=3
								and js.StartedStamp is null
								and djs.StartedStamp is not null
								and djs.CompletedStamp>djs.StartedStamp
								and djs.FailedStamp is null) x on j.jobID=x.JobID'
		End


	if @EFVal=2
		Begin
	--		Set @SQL = '
	--		select j.JobID, j.JobName, coalesce(j.CategoryID,-1) CategoryID, coalesce(j.JobTemplateID,-1) JobTemplateID, j.RunAtStamp, j.StartedStamp, j.CompletedStamp, j.FailedStamp, j.WaitStamp
	--				, coalesce(rs.RunningSteps,0) RunningSteps, coalesce(jt.JobName,''--None--'') JobTemplateName, coalesce(jc.Description,''--None--'') JobCategoryName
	--				, coalesce(j.PromptState, 0) PromptState, coalesce(j.PromptIssueWeek, 0) PromptIssueWeek, coalesce(j.PromptIssueMonth, 0) PromptIssueMonth
	--				, coalesce(j.PromptCalYear, 0) PromptCalYear, coalesce(j.PromptCalPeriod, 0) PromptCalPeriod, coalesce(j.JobStateID, 0) JobStateID, coalesce(j.JobIssueWeek, 0) JobIssueWeek
	--				, coalesce(j.RecurringTypeID, 0) RecurringTypeID, coalesce(j.IsTemplate,0) IsTemplate, coalesce(j.Type,'''') Type, coalesce(j.TestMode,0) TestMode, j.LastJobLogID, j.LastJobParameters
	--			from JobControl..Jobs j
	--				left outer join (	select js.JobID, sum(case when js.StartedStamp is not null and js.CompletedStamp is null 
	--															   and js.FailedStamp is null then 1 else 0 end) RunningSteps 
	--										from JobControl..JobSteps js 
	--										group by js.JobID) rs on rs.JobID = j.JobID
	--				left outer join JobControl..JobCategories jc on jc.ID = j.CategoryID
	--				left outer join JobControl..Jobs jt on jt.JobID = j.JobTemplateID and jt.IsTemplate = 1
	--				join 
	--(		select s.jobID
	--			from (
	--				select j.jobID, j.JobName, j.disabled, j.vfpJobID, vdl.EMailName, vdl.EmailAddress 
	--					from  JobControl..Jobs j 
	--						left outer join JobControl..Jobs jt on jt.IsTemplate = 1 and jt.jobid = j.JobTemplateID
	--						join ( select distinct j.JobID, ql.stateID
	--									from QueryEditor..QueryLocations ql
	--										join JobSteps js on js.QueryCriteriaID = ql.QueryID
	--										join JobControl..Jobs j on j.JobID = js.JobID
	--										left outer join Lookups..States s on s.Id = ql.StateID
	--									where ql.stateID > 0
	--										and s.Code = ''MA'') js on js.JobID = j.JobID
	--						left outer join JobControl..vDistList vdl on vdl.JobID = j.JobID
	--					where coalesce(j.IsTemplate,0) = 0 
	--						and jt.type=''MTDE''
	--						and '' '' + j.jobname like ''% comp-%''	) s
	--		full outer join (
	--			select j.JOBID, j.JOBDESCRIP, j.Status, CURSTATE, c.PCEMAIL, c.PCFNAME, c.PCLNAME
	--				from DataLoad..Jobs_jobs j
	--					left outer join DataLoad..Jobs_customer c on c.CUSTID = j.CUSTID
	--				where '' ''  + JOBDESCRIP like ''% Comp-%'' 
	--						and JOBTYPE = ''MTDE''
	--						and CURSTATE = ''MA''
	--			) v on v.JOBID = s.VFPJobID ) xx on xx.jobid=j.jobid
	--		Where ' + @DisabledString + 
	--		'Order by j.JobName'
			Set @SQL = '
			select j.JobID, j.JobName, coalesce(j.CategoryID,-1) CategoryID, coalesce(j.JobTemplateID,-1) JobTemplateID, j.RunAtStamp, j.StartedStamp, j.CompletedStamp, j.FailedStamp, j.WaitStamp
					, coalesce(rs.RunningSteps,0) RunningSteps, coalesce(jt.JobName,''--None--'') JobTemplateName, coalesce(jc.Description,''--None--'') JobCategoryName
					, coalesce(j.PromptState, 0) PromptState, coalesce(j.PromptIssueWeek, 0) PromptIssueWeek, coalesce(j.PromptIssueMonth, 0) PromptIssueMonth
					, coalesce(j.PromptCalYear, 0) PromptCalYear, coalesce(j.PromptCalPeriod, 0) PromptCalPeriod, coalesce(j.JobStateID, 0) JobStateID, coalesce(j.JobIssueWeek, 0) JobIssueWeek
					, coalesce(j.RecurringTypeID, 0) RecurringTypeID, coalesce(j.IsTemplate,0) IsTemplate, coalesce(j.Type,'''') Type, coalesce(j.TestMode,0) TestMode, j.LastJobLogID, j.LastJobParameters
				from JobControl..Jobs j
					left outer join (	select js.JobID, sum(case when js.StartedStamp is not null and js.CompletedStamp is null 
																   and js.FailedStamp is null then 1 else 0 end) RunningSteps 
											from JobControl..JobSteps js 
											group by js.JobID) rs on rs.JobID = j.JobID
					left outer join JobControl..JobCategories jc on jc.ID = j.CategoryID
					left outer join JobControl..Jobs jt on jt.JobID = j.JobTemplateID and jt.IsTemplate = 1
					Join dbo.fnJobFilter_Phase1() x on x.jobid=j.jobid 
				where ' + @DisabledString + ' ' +
				'order by j.JobName'
		End
		--Print @SQL
		exec(@SQL)
END
