/****** Object:  Procedure [dbo].[RunnableJobs_2ver_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[RunnableJobs] @RunMode int, @Result varchar(10)
AS
BEGIN
	-- @Result IDs or Details

	drop table if exists #ReadyStateDates
	drop table if exists #AllStatesReady
	drop table if exists #Details

	if @RunMode is null
		set @RunMode = 0

	SET NOCOUNT ON;

	declare @CurrWeekRunDay int
	declare @CurrMonthRunDay int

	declare @FirstDayofMonth date = convert(date,ltrim(str(month(getdate()))) + '/1/' + ltrim(str(Year(getdate()))))
	declare @FirstWeekDayofMonth date = case	when datepart(dw,@FirstDayofMonth) = 1 then dateadd(day,1,@FirstDayofMonth) --when day is a sunday Add 1 day to monday
											when datepart(dw,@FirstDayofMonth) = 7 then dateadd(day,2,@FirstDayofMonth) --when day is a saturday Add 2 days to monday
											else @FirstDayofMonth END

	declare @LastDayofMonth date = eomonth(getdate(),0)
	declare @LastWeekDayofMonth date = case	when datepart(dw,@LastDayofMonth) = 1 then dateadd(day,-2,@LastDayofMonth) --when day is a sunday subtract 2 day to friday
											when datepart(dw,@LastDayofMonth) = 7 then dateadd(day,-1,@LastDayofMonth) --when day is a saturday subtract 1 day to friday
											else @LastDayofMonth END

	set @CurrMonthRunDay = case when convert(date,getdate()) = @LastDayofMonth then 1	--	Monthly - End of the Month
								when day(getdate()) = 1 then 2	--  Monthly - First of the Month
								when convert(date,getdate()) = @LastWeekDayofMonth then 3	--  Monthly - Last work day of the Month
								when convert(date,getdate()) = @FirstWeekDayofMonth then 4	--  Monthly - First work day of the Month
							else 0 end

	set @CurrWeekRunDay = case when datepart(weekday,getdate()) = 2 then 5	--	Weekly - Monday
								when datepart(weekday,getdate()) = 3 then 6	--	Weekly - Tuesday
								when datepart(weekday,getdate()) = 4 then 7	--	Weekly - Wednesday
								when datepart(weekday,getdate()) = 5 then 8	--	Weekly - Thursday
								when datepart(weekday,getdate()) = 6 then 9	--	Weekly - Friday
							else 0 end


	-- Ready state Dates

		select s.code State, s.id StateID, iw.Issueweek, im.IssueMonth, im.CalcIssueMonth
			into #ReadyStateDates
		from Lookups..States s
			left outer join ( select StateID, Issueweek
								from (
								select iw.*, RowNum = ROW_NUMBER() OVER (PARTITION BY stateID ORDER BY Issueweek Desc)
									from Support..IssueWeeks iw
									where DataImportComplete is not null
								) x where RowNum = 1
							) iw on iw.StateID = s.id
			left outer join ( select StateID, IssueMonth, (right(IssueMonth,4) * 100) + left(IssueMonth,2) CalcIssueMonth
								from (
									select *, RowNum = ROW_NUMBER() OVER (PARTITION BY stateID ORDER BY right(IssueMonth,4) Desc, left(IssueMonth,2) Desc) 
										from Support..IssueMonth
										where DataImportComplete is not null
								) x where RowNum = 1
							) im on im.StateID = s.id
		where s.Mode in ('Core','Bulk')
			and s.LocationActiveState = 1

	insert #ReadyStateDates (State, StateID, Issueweek, IssueMonth, im.CalcIssueMonth)
	select '' State, 0, (select max(IssueWeek) from #ReadyStateDates),(select max(IssueMonth) from #ReadyStateDates),(select max(CalcIssueMonth) from #ReadyStateDates)
		where (select max(IssueWeek) from #ReadyStateDates) = (select min(IssueWeek) from #ReadyStateDates)
			or (select max(CalcIssueMonth) from #ReadyStateDates) = (select min(CalcIssueMonth) from #ReadyStateDates)

	select JobID, case when max(rsd.Issueweek) = min(rsd.Issueweek) then 1 else 0 end IssueWeekReady
			, case when max(rsd.CalcIssueMonth) = min(rsd.CalcIssueMonth) then 1 else 0 end CalcIssueMonthReady
		into #AllStatesReady
		from JobControl..Jobs j
			join #ReadyStateDates rsd on (j.JobStateReference like '%' + rsd.State + '%' and ltrim(rsd.State) > '')
		where coalesce(j.disabled, 0) = 0 and coalesce(j.deleted, 0) = 0 and coalesce(j.TestMode, 0) = 0
	group by JobID

	insert #AllStatesReady (JobID, IssueWeekReady, CalcIssueMonthReady)
		select j.JobID, 1 IssueWeekReady, 1 CalcIssueMonthReady
			from JobControl..Jobs j
				join JobControl..JobSteps js on js.JobID = j.JobID and QueryCriteriaID > 0
				join JobControl..QueryTemplates qt on qt.Id = js.QueryTemplateID
				join JobControl..QueryTypes qt2 on qt2.QueryTypeID = qt.QueryTypeID
				join JobControl..QuerySources qs on qs.id = qt2.QuerySourceID
				join #ReadyStateDates rsd on rsd.stateID = 0
			where coalesce(j.disabled, 0) = 0 and coalesce(j.deleted, 0) = 0 and coalesce(j.TestMode, 0) = 0
				and coalesce(j.RecurringTypeID,7) <> 7
				and qs.AllStdStates = 1

declare @CurrIW int
select @CurrIW = Issueweek from #ReadyStateDates where StateID = 0

--3	Issue Monthly
	select distinct JobControl.dbo.GetJobPriority(j.JobID) JobPriority
		, j.JobID, j.JobName, j.JobStateReference
		, j.RecurringTypeID, rt.Description, j.InProduction 
		, jp.ParamValue LastParamVal
		, coalesce(j.RecurringTargetID,0) RecurringTargetID
	into #Details
	from JobControl..Jobs j
		join JobControl..JobParameters jp on jp.JobID = j.JobID and jp.ParamName = 'IssueMonth'
		join JobControl..JobRecurringTypes rt on rt.ID = J.RecurringTypeID
		join #ReadyStateDates rsd on (j.JobStateReference like '%' + rsd.State + '%' and ltrim(rsd.State) > '')
--									or (ltrim(j.JobStateReference) = ltrim(rsd.State) and ltrim(rsd.State) = '')
									or ltrim(j.JobStateReference) = ''

		left outer join #AllStatesReady jr on jr.JobID = j.JobID
	where coalesce(j.disabled, 0) = 0 and coalesce(j.deleted, 0) = 0
		and case when @RunMode = 0 then 1
				when @RunMode = j.ModeID then 1
				else 0 end = 1
		and JobControl.dbo.DependentJobsSuccessfullyRun(j.JobID) = 1
		and j.RecurringTypeID = 3	--Issue Monthly
		and j.InProduction = 1
		and rsd.CalcIssueMonth > JobControl.dbo.ConvertJobParm2CalcIssueMonth(substring(jp.ParamValue,1,2), substring(jp.ParamValue,3,4))
		and coalesce(jr.CalcIssueMonthReady,1) = 1
		and coalesce(j.TestMode, 0) = 0
		and (@CurrMonthRunDay = coalesce(j.RecurringTargetID,0) or coalesce(j.RecurringTargetID,0) = 0)

--2	Issue Weekly
	union select distinct JobControl.dbo.GetJobPriority(j.JobID) JobPriority
		, j.JobID, j.JobName, j.JobStateReference
		, j.RecurringTypeID, rt.Description, j.InProduction 
		, jp.ParamValue LastParamVal
		, coalesce(j.RecurringTargetID,0) RecurringTargetID
	from JobControl..Jobs j
		left outer join JobControl..JobParameters jp on jp.JobID = j.JobID and jp.ParamName = 'IssueWeek'
		join JobControl..JobRecurringTypes rt on rt.ID = J.RecurringTypeID
		join #ReadyStateDates rsd on (j.JobStateReference like '%' + rsd.State + '%' and ltrim(rsd.State) > '')
--									or (ltrim(j.JobStateReference) = ltrim(rsd.State) and ltrim(rsd.State) = '')
									or ltrim(j.JobStateReference) = ''
		left outer join #AllStatesReady jr on jr.JobID = j.JobID
	where coalesce(j.disabled, 0) = 0 and coalesce(j.deleted, 0) = 0
		and case when @RunMode = 0 then 1
				when @RunMode = j.ModeID then 1
				else 0 end = 1
		and JobControl.dbo.DependentJobsSuccessfullyRun(j.JobID) = 1
		and j.RecurringTypeID = 2	--Issue Weekly
		and j.InProduction = 1
		--and rsd.Issueweek > jp.ParamValue
		and (JobControl.dbo.CalcIWOffset(rsd.Issueweek, coalesce(j.RecurringOffset,0)) > jp.ParamValue
					or JobControl.dbo.CalcIWOffset(rsd.Issueweek, coalesce(j.RecurringOffset,0)) = @CurrIW and jp.ParmRecID is null)
		and coalesce(jr.IssueWeekReady,1) = 1
		and coalesce(j.TestMode, 0) = 0
		and (@CurrWeekRunDay = coalesce(j.RecurringTargetID,0) or coalesce(j.RecurringTargetID,0) = 0)

--4	Calendar Monthly
	union select distinct JobControl.dbo.GetJobPriority(j.JobID) JobPriority
		, j.JobID, j.JobName, j.JobStateReference
		, j.RecurringTypeID, rt.Description, j.InProduction 
		, JobControl.dbo.ConvertJobParm2CalcIssueMonth(jpm.ParamValue, jpy.ParamValue) LastParamVal
		, coalesce(j.RecurringTargetID,0) RecurringTargetID
	from JobControl..Jobs j
		join JobControl..JobParameters jpy on jpy.JobID = j.JobID and jpy.ParamName = 'CalYear'
		join JobControl..JobParameters jpm on jpm.JobID = j.JobID and jpm.ParamName = 'CalPeriod'
		join JobControl..JobRecurringTypes rt on rt.ID = J.RecurringTypeID
		join #ReadyStateDates rsd on ((j.JobStateReference like '%' + rsd.State + '%' and ltrim(rsd.State) > '')
										or (ltrim(j.JobStateReference) = ''))
--										or (ltrim(j.JobStateReference) = ltrim(rsd.State) and ltrim(rsd.State) = ''))
		join (select min(CalcIssueMonth) CompleteMonth from #ReadyStateDates where StateID > 0) cm on 1=1
		left outer join #AllStatesReady jr on jr.JobID = j.JobID
	where coalesce(j.disabled, 0) = 0 and coalesce(j.deleted, 0) = 0
		and case when @RunMode = 0 then 1
				when @RunMode = j.ModeID then 1
				else 0 end = 1
		and JobControl.dbo.DependentJobsSuccessfullyRun(j.JobID) = 1
		and j.RecurringTypeID = 4	--Calendar Monthly
		and j.InProduction = 1
		and ((rsd.CalcIssueMonth > JobControl.dbo.ConvertJobParm2CalcIssueMonth(jpm.ParamValue, jpy.ParamValue) and j.JobStateReference > '')
				or (cm.CompleteMonth >= JobControl.dbo.ConvertJobParm2CalcIssueMonth(jpm.ParamValue, jpy.ParamValue) and j.JobStateReference = ''))
		and coalesce(jr.CalcIssueMonthReady,1) = 1
		and coalesce(j.TestMode, 0) = 0
		and (@CurrMonthRunDay = coalesce(j.RecurringTargetID,0) or coalesce(j.RecurringTargetID,0) = 0)


--6	Calendar Annual
--5	Calendar Quarterly

if @Result = 'IDs'
begin
	select distinct JobID from #Details
end

if @Result = 'Details'
begin
	select * from #Details
end

END
