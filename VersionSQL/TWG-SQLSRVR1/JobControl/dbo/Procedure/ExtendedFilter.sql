/****** Object:  Procedure [dbo].[ExtendedFilter]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 06-10-2019
-- Description:	Returns data for JobControl based on the Extended Filter Dropdown
-- =============================================
CREATE PROCEDURE dbo.ExtendedFilter 
	@EFVal int,
	@DisabledVal int
AS
BEGIN
	SET NOCOUNT ON;

	Declare @ListComplete int=0;
	create table #JobList (JobID int null)


	if @EFVal = 1 and @ListComplete=0
	begin
		insert #JobList (JobID)
		Select distinct js.JobID
				From JobSteps js
					join jobs j on j.jobid=js.jobid
					left outer join Jobs jt on jt.IsTemplate = 1 and jt.jobid = j.JobTemplateID
					left outer join JobSteps djs on ',' + js.DependsOnStepIDs + ',' like  '%,' + ltrim(str(djs.StepID)) + ',%'
				Where js.StepTypeID=1091 
					and js.RunModeID=3
					and js.StartedStamp is null
					and djs.StartedStamp is not null
					and djs.CompletedStamp>djs.StartedStamp
					and djs.FailedStamp is null
					and isnull(j.TestMode,0)=0;
		Set @ListComplete=1;
	end


	--if @EFVal = 2 and @ListComplete=0
	--begin
	--	insert #JobList (JobID)
	--		exec JobControl..JobFilter_Phase1 'IDList', 0;
	--	Set @ListComplete=1;
	--end

	--if @EFVal = 3 and @ListComplete=0
	--begin
	--	insert #JobList (JobID)
	--		exec JobControl..JobFilter_Phase2 'IDList', 0;
	--	Set @ListComplete=1;
	--end


	if @EFVal = 5 and @ListComplete=0
	begin
		insert #JobList (JobID)
		Select jobid from JobRunHold where ReleaseDate is null;
		Set @ListComplete=1;
	end

	if @ListComplete=0
		Begin
			-- This is the code that gets the MTDE jobs
			Declare @SQLCode varchar(max);
			--Select @SQLCode=js.SQLCode 
			--	from ExtendedFilters ef
			--		join JobSchedule js on ef.ScheduleID=js.ScheduleID
			--	where ef.ID=@EFVal;

			Select @SQLCode = ef.SQLCode 
				from ExtendedFilters ef
				where ef.ID=@EFVal;

			if @SQLCode is not null
				Begin
					Set @SQLCode = 'insert #JobList (JobID) ' + @SQLCode;
					print @SQLCode
					Exec(@SQLCode);

					Set @ListComplete=1;
				End
			else
				insert #JobList (JobID)
					select JobID from ExtendedFiltersJobs where ExtendedFilterID = @EFVal
		End

		--if @EFVal = 12 and @ListComplete=0
		--begin
		--	insert #JobList (JobID)
		--		select 2849
		--		union select 2850
		--		union select 2852
		--		union select 2859
		--		union select 2858
		--		union select 3883
		--		union select 3891
		--		union select 3890
		--		union select 3889
		--		union select 3888
		--		union select 3894
		--		union select 3895
		--		union select 3896
		--		union select 3897
		--		union select 3899
		--		union select 3901
		--		union select 3900
		--		union select 3903

		--	Set @ListComplete=1;
		--end

		--if @EFVal = 13 and @ListComplete=0
		--begin
		--	insert #JobList (JobID)
		--		select 2860
		--		union select 2861
		--		union select 3864
		--		union select 3865
		--		union select 3866
		--		union select 3867
		--		union select 3868

		--	Set @ListComplete=1;
		--end

	select j.JobID, coalesce(j.ModeID, 0) ModeID, j.JobName, j.JobStateReference, coalesce(j.CategoryID,-1) CategoryID, coalesce(j.JobTemplateID,-1) JobTemplateID, coalesce(j.disabled,0) [Disabled], j.RunAtStamp, j.StartedStamp, j.CompletedStamp, j.FailedStamp, j.WaitStamp
			, coalesce(rs.RunningSteps,0) RunningSteps, coalesce(jt.JobName,'--None--') JobTemplateName, coalesce(jc.Description,'--None--') JobCategoryName
			, coalesce(j.PromptState, 0) PromptState, coalesce(j.PromptIssueWeek, 0) PromptIssueWeek, coalesce(j.PromptIssueMonth, 0) PromptIssueMonth
			, coalesce(j.PromptCalYear, 0) PromptCalYear, coalesce(j.PromptCalPeriod, 0) PromptCalPeriod, coalesce(j.JobStateID, 0) JobStateID, coalesce(j.JobIssueWeek, 0) JobIssueWeek
			, coalesce(j.RecurringTypeID, 0) RecurringTypeID, coalesce(j.IsTemplate,0) IsTemplate, coalesce(j.Type,'''') Type, coalesce(j.TestMode,0) TestMode, j.LastJobLogID, j.LastJobParameters
			, coalesce(n.Note,'') JobNotes
			, j.CustID
			, coalesce(JobControl.dbo.GetJobPriority(j.JobID),5) RunPriority
		from JobControl..Jobs j
			left outer join (	select js.JobID, sum(case when js.StartedStamp is not null and js.CompletedStamp is null 
															and js.FailedStamp is null then 1 else 0 end) RunningSteps 
									from JobControl..JobSteps js 
									group by js.JobID) rs on rs.JobID = j.JobID
			left outer join JobControl..JobCategories jc on jc.ID = j.CategoryID
			left outer join JobControl..Jobs jt on jt.JobID = j.JobTemplateID and jt.IsTemplate = 1
			left join JobControl..Notes n on j.JobID = n.JobID and n.NoteType=1
			Join #JobList jl on jl.JobID = j.JobID 
		where case	when isnull(j.disabled,0) = 1 and @DisabledVal = 1 then 1  -- Disabled Only
					when isnull(j.disabled,0) = 0 and @DisabledVal = 0 then 1 -- Active Only
					when @DisabledVal = 2 then 1	 -- All Jobs (Active and Disabled)
					else 0 
					end = 1 
		order by j.JobName




END
