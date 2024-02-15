/****** Object:  Procedure [dbo].[RunnableJobs2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.RunnableJobs2 @RunMode int, @Result varchar(10)
AS
BEGIN
	-- @Result IDs or Details

	drop table if exists #IDS

	create table #IDS (JobID Int, LastParam varchar(20), NextParam varchar(20))
						
	declare @RunDate datetime
	set @RunDate = getdate()
	--set @RunDate = '3/30/2022 10:00 AM'

	declare @FirstOfMonth date = ltrim(str(month(@RunDate))) + '/1/' + ltrim(str(year(@RunDate)))
	declare @LastOfMonth date = dateAdd(dd,-1,dateAdd(mm,1,@FirstOfMonth))
	declare @FirstWDOfMonth date = @FirstOfMonth
	declare @LastWDOfMonth date = @LastOfMonth

	if Datepart(dw,@FirstOfMonth) = 1 --Sun
		set @FirstWDOfMonth = dateadd(dd,1,@FirstOfMonth)
	if Datepart(dw,@FirstOfMonth) = 7 --Sat
		set @FirstWDOfMonth = dateadd(dd,2,@FirstOfMonth)

	if Datepart(dw,@LastOfMonth) = 1 --Sun
		set @LastWDOfMonth = dateadd(dd,-2,@LastOfMonth)
	if Datepart(dw,@LastOfMonth) = 7 --Sat
		set @LastWDOfMonth = dateadd(dd,-1,@LastOfMonth)


	drop table if exists #ActJobs

	select distinct j.JobID, j.JobName, j.RecurringTypeID, j.RecurringTargetID, j.RecurringOffset, ql.StateID
			, jp.ParamName, coalesce(jp2.ParamValue,'') + jp.ParamValue ParamValue
			, qs.AllStdStates, jl.LastLiveStartTime
			--, coalesce(j.NextParamTarget, case when jp.ParamValue = 'FullLoad' then ''
			--									when j.RecurringTypeID = 3 then convert(int,right(jp.ParamValue,4) + left(jp.ParamValue,2))
			--									when jp.ParamValue = 'YR' then convert(int,right(jp2.ParamValue,4) + '01')
			--								else convert(int,coalesce(jp2.ParamValue,'') + jp.ParamValue) end, 0) NextParamTarget
			, coalesce(j.NextParamTarget, case when jp.ParamValue = 'FullLoad' then ''
												when j.RecurringTypeID = 3 then ltrim(str(convert(int,right(jp.ParamValue,4) + left(jp.ParamValue,2))))
												when jp.ParamValue = 'YR' then ltrim(str(convert(int,right(jp2.ParamValue,4) + '01')))
											else null end, 0) NextParamTarget
		into #ActJobs
		from JobControl..Jobs j (readpast)
			left outer join JobControl..JobParameters jp on jp.JobID = j.JobID and jp.ParamName <> 'CalYear'
			left outer join JobControl..JobParameters jp2 on jp2.JobID = j.JobID and jp2.ParamName = 'CalYear'
			left outer join JobControl..JobSteps js (readpast) on js.JobID = j.JobID and js.StepTypeID in (21,1124)
			left outer join JobControl..QueryTemplates qt on qt.Id = js.QueryTemplateID
			left outer join JobControl..QueryTypes qty on qty.QueryTypeID = qt.QueryTypeID
			left outer join JobControl..QuerySources qs on qs.Id = qty.QuerySourceID
			left outer join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID and ql.StateID > 0
			left outer join (select JobID, Max(StartTime) LastLiveStartTime 
									from JobControl..JobLog
									where InProduction = 1 and coalesce(TestMode,0) = 0
									group by JobID ) jl on jl.JobID = j.JobID
		where j.InProduction = 1 and coalesce(j.disabled,0) = 0 and coalesce(j.Deleted,0) = 0 and coalesce(j.TestMode,0) = 0

	--IssueWeek

	declare @CurrIW int
	select @CurrIW = Max(IssueWeek) from Support..IssueWeeks where DataImportComplete is not null

	drop table if exists #IW

	select stateID, Max(IssueWeek) IssueWeek
		into #IW
		from Support..IssueWeeks
		where DataImportComplete is not null
		group by stateID

	insert #IDS (JobID, LastParam, NextParam)
	select x.JobID, x.LastRun, x.AdjustIW
		from (
			select JobID
                    , coalesce(ParamValue,'None') LastRun
                    --, coalesce(JobCOntrol.dbo.LastLogicalParam(aj.jobID),'None') LastRun
					, Sum(case when aj.StateID > 0 then 1 else 0 end) TotStates
					, Sum(case when JobControl.dbo.OffsetParam2(aj.ParamName, @CurrIW, aj.RecurringOffset) <= iw.IssueWeek then 1 else 0 end) StateDataReady 
					, @CurrIW CurrentIW
					, Max(JobControl.dbo.OffsetParam2(aj.ParamName, @CurrIW, aj.RecurringOffset)) AdjustIW
					, Max(aj.RecurringTargetID) RecurringTargetID
					, Max(case when aj.AllStdStates = 1 then 1 else 0 end) AllStdStates
					, Max(coalesce(LastLiveStartTime,'1/1/2000')) LastLiveStartTime
				from #ActJobs aj
					left outer join #IW iw on aj.StateID = iw.StateID 
				where RecurringTypeID = 2
					and aj.NextParamTarget <= @CurrIW
				group by JobID, ParamValue
		) x
		where case when (TotStates = StateDataReady or AllStdStates = 1) and LastRun <> AdjustIW then 1 else 0 end = 1
			and x.RecurringTargetID <= datepart(dw,@RunDate) + 3 -- Mon-2, Tue-3
			and DATEDIFF(dd,x.LastLiveStartTime,@RunDate) >= 5
			--and 1=2


	--IssueMonth

	drop table if exists #IM

	select im.stateID, im.IssueMonth, SortableIssueMonth
		into #IM
		from Support..IssueMonth im
			join (
				select im.StateID, Max(SortableIssueMonth) SortIssue
					from Support..IssueMonth IM
						join ( select stateID, Max(IssueWeek) IssueWeek
									from Support..IssueWeeks
									where DataImportComplete is not null
									group by stateID
							) IW on iw.StateID = im.StateID
									and iw.IssueWeek >= Im.EndWeek
					where IM.IssueMonth not Like '13%'
					Group by im.StateID
				) sim on sim.StateID = im.StateID
						and sim.SortIssue = im.SortableIssueMonth


	declare @CurrIM varchar(20)
	declare @SCurrIM int
	select @CurrIM = x.IssueMonth
			, @SCurrIM = x.SortableIssueMonth
		from (
			select top 1 IssueMonth, SortableIssueMonth
				from #IM
				order by SortableIssueMonth desc
			) x


	insert #IDS (JobID, LastParam, NextParam)
	select x.JobID, x.LastRun, x.AdjustIM
		from (
			select JobID
                    , coalesce(ParamValue,'None') LastRun
                    --, coalesce(JobCOntrol.dbo.LastLogicalParam(aj.jobID),'None') LastRun
					, Sum(case when aj.StateID > 0 then 1 else 0 end) TotStates
					, Sum(case when JobControl.dbo.OffsetParam2(aj.ParamName, @CurrIM, aj.RecurringOffset) <= im.IssueMonth then 1 else 0 end) StateDataReady 
					, @CurrIM CurrentIM
					, Max(JobControl.dbo.OffsetParam2(aj.ParamName, @CurrIM, aj.RecurringOffset)) AdjustIM
					, Max(aj.RecurringTargetID) RecurringTargetID
					, Max(case when aj.AllStdStates = 1 then 1 else 0 end) AllStdStates
					, Max(coalesce(LastLiveStartTime,'1/1/2000')) LastLiveStartTime
				from #ActJobs aj
					left outer join #IM IM on aj.StateID = IM.StateID 
				--where (RecurringTypeID in (3,12) and aj.NextParamTarget <= @SCurrIM  and left(@CurrIM,2) <> '13')
				--	or (RecurringTypeID = 12 and aj.NextParamTarget <= @SCurrIM  and left(@CurrIM,2) = '13')\
				where RecurringTypeID in (3,12) and aj.NextParamTarget <= @SCurrIM
				group by JobID, ParamValue
		) x
		where case when (TotStates = StateDataReady or AllStdStates = 1) and LastRun <> AdjustIM then 1 else 0 end = 1
			and (x.RecurringTargetID <= datepart(dw,@RunDate) + 3 -- Mon-2, Tue-3
					or x.RecurringTargetID = 10 ) -- When Ready 
			--and DATEDIFF(dd,x.LastLiveStartTime,@RunDate) >= 25
			and case when DATEDIFF(dd,x.LastLiveStartTime,@RunDate) >= 25 and LastRun = AdjustIM then 0 else 1 end = 1 

	----CalMonth

	--drop table if exists #CY

	--select StateID, IssueMonth
	--	into #CY
	--	from (
	--	select StateID, Max(SortableIssueMonth) IssueMonth
	--		from Support..IssueMonth
	--		where DataImportComplete is not null
	--		group by StateID
	--	) x

	--declare @CurrCY int
	--select @CurrCY = x.IssueMonth
	--	from (
	--		select top 1 IssueMonth
	--			from #CY
	--			order by IssueMonth desc
	--		) x

	drop table if exists #CY

	select StateID, IssueMonth CurrCY, Seq, CYPlus1
		into #CY
		from (
			select StateID, SortableIssueMonth IssueMonth
					, Seq = ROW_NUMBER() OVER (PARTITION BY StateID ORDER BY SortableIssueMonth desc)
					, case when right(ltrim(str(IssueMonth)),2) = '12' then convert(int,left(ltrim(str(IssueMonth)),4) + '01') + 1 else IssueMonth + 1 end CYPlus1
				from Support..IssueMonth
				where DataImportComplete is not null
			) x
		where Seq <= 3

	-- @CurrCYPlus1 and the excpetion JOBID of 2849 below 
	-- is to force this CL Monthly to Run on the Actual Month not the closed Month
	--declare @CurrCYPlus1 int

	--if right(ltrim(str(@CurrCY)),2) = '12'
	--	set @CurrCYPlus1 = convert(int,left(ltrim(str(@CurrCY)),4) + '01') + 1
	--else
	--	set @CurrCYPlus1 = @CurrCY + 1

	insert #IDS (JobID, LastParam, NextParam)
	select x.JobID, x.LastRun, x.AdjustIM
		from (
			select JobID
                    , replace(coalesce(ParamValue,'None'),'YR','13') LastRun
                    --, coalesce(JobCOntrol.dbo.LastLogicalParam(aj.jobID),'None') LastRun
					, Sum(case when aj.StateID > 0 then 1 else 0 end) TotStates
					, Sum(case when JobControl.dbo.OffsetParam2(aj.ParamName, CY.CurrCY, aj.RecurringOffset) <= CY.CurrCY then 1 else 0 end) StateDataReady 
					, Max(CY.CurrCY) CurrentCY
					, Max(JobControl.dbo.OffsetParam2(aj.ParamName, CY.CurrCY, aj.RecurringOffset)) AdjustIM
					, Max(aj.RecurringTargetID) RecurringTargetID
					, Max(aj.RecurringTypeID) RecurringTypeID
					, Max(case when aj.AllStdStates = 1 then 1 else 0 end) AllStdStates
					, Max(coalesce(LastLiveStartTime,'1/1/2000')) LastLiveStartTime
					, Max(CY.CYPlus1) CYPlus1
				from #ActJobs aj
					left outer join #CY CY on aj.StateID = CY.StateID and CY.Seq = 1
--				where RecurringTypeID in (4,5,6,8,9,10)
				where ( (RecurringTypeID in (4,8,9,10) and right(CY.CurrCY,2) <> '13')
						or (RecurringTypeID in (5,6,8,9,10) and right(CY.CurrCY,2) = '13'))
					and (aj.NextParamTarget <= CY.CurrCY
							or (aj.JobID = 2849 and aj.NextParamTarget <= CY.CYPlus1))
				group by JobID, ParamValue
		) x
		where case when (TotStates = StateDataReady or AllStdStates = 1) and LastRun <> AdjustIM then 1 
					when (TotStates = StateDataReady or AllStdStates = 1) and JobID = 2849 and LastRun <> x.CYPlus1 then 1 
				else 0 end = 1
			and (RecurringTypeID in (4,8,9,10)  -- Monthly
					or (RecurringTypeID in (5,9,10) and convert(int,right(x.CurrentCY,2)) in (3,6,9,12,13))   -- Quarterly
					or (RecurringTypeID in (6,8,10) and convert(int,right(x.CurrentCY,2)) in (12,13))   -- Annual
				)
			and case when x.RecurringTargetID = 1 and convert(date,@RunDate) = @LastOfMonth then 1
					when x.RecurringTargetID = 2 and convert(date,@RunDate) = @FirstOfMonth then 1
					when x.RecurringTargetID = 3 and convert(date,@RunDate) = @LastWDOfMonth then 1
					when x.RecurringTargetID = 4 and convert(date,@RunDate) = @FirstWDOfMonth then 1
					when x.RecurringTargetID in (0,10) then 1
					else 0 end = 1


	if @Result = 'IDs'
	begin
		select distinct JobID from #IDS
	end

	if @Result = 'Details'
	begin

		select distinct JobControl.dbo.GetJobPriority(j.JobID) JobPriority
			, j.JobID, j.JobName, j.JobStateReference
			, j.RecurringTypeID, rt.Description, j.InProduction 
			, x.LastParam LastParamVal
			, coalesce(j.RecurringTypeID,0) RecurringTypeID
			from #IDS x
				join JobControl..Jobs j (readpast) on x.JobID = j.JobID
				join JobControl..JobRecurringTypes rt on rt.ID = j.RecurringTypeID

	end

END
