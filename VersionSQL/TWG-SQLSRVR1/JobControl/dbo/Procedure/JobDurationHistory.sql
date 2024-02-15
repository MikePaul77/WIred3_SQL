/****** Object:  Procedure [dbo].[JobDurationHistory]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE JobDurationHistory @JobID int, @LastRuns int
AS
BEGIN
	SET NOCOUNT ON;

	drop Table if exists #RawHist 

	select p.LogRecID 
		, p.JobLogID
		, js.JobID, js.StepID, jst.StepName, js.StepTypeID, js.StepOrder
		, p.LogStamp
		, s.ID LoopStateID
		, case when p.LogInfoSource = 'StepRecordCount' then LogInformation else null end RecCount
		, case when p.LogInfoSource = 'XFormRecordCount' then LogStamp else null end XFormEnd
		, case when p.LogInfoSource = 'LayoutRecordCount' then LogStamp else null end LayoutEnd
		, convert(int,null) StepSeq
		, convert(int,null) RunSeq
	into #RawHist
	from JobControl..JobSteps js
		join JobControl..JobStepTypes jst on jst.StepTypeID = js.StepTypeID
		join JobControl..JobStepLogHist p on p.JobStepID = js.StepID
		left outer join Lookups..States s on js.StepTypeID = 1107
												and replace(LogInformation,'SP Processing ','') = 'State ' + ltrim(str(s.ID))
	where p.JobID = @JobID

	declare @LogRecID int, @StepID int, @StateID int, @JobLogID int
	declare @LastStepID int = 0
	declare @LastStateID int = 0
	declare @LastJobLogID int = 0
	declare @StepSeq int = 0
	declare @RunSeq int = 0

	DECLARE curA CURSOR FOR
		select LogRecID, StepID, LoopStateID, JobLogID
			from #RawHist
			order by LogRecID

	OPEN curA

	FETCH NEXT FROM curA into @LogRecID, @StepID, @StateID, @JobLogID
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN

		if @LastStepID <> @StepID
		begin
			set @LastStepID = @StepID
			set @StepSeq = @StepSeq + 1
		end

		if @LastStateID <> @StateID and @StateID > 0
			set @LastStateID = @StateID

		if @LastJobLogID <> @JobLogID
		begin
			set @LastJobLogID = @JobLogID
			set @RunSeq = @RunSeq + 1
		end

		update #RawHist set StepSeq = @StepSeq 
							, LoopStateID = @LastStateID
							, RunSeq = @RunSeq
			where LogRecID = @LogRecID
		
		FETCH NEXT FROM curA into @LogRecID, @StepID, @StateID, @JobLogID
	END
	CLOSE curA
	DEALLOCATE curA

	drop table if exists #FinalHist

	select JobLogID, RunSeq, JobID, StepID, StepName, StepTypeID, StepOrder, StepSeq
		, min(LogStamp) StepStart
		, max(LogStamp) StepEnd
		, Max(RecCount) RecCount
		, Max(LoopStateID) LoopStateID
		, max(XFormEnd) XFormEnd
		, max(LayoutEnd) LayoutEnd
	into #FinalHist
	from #RawHist
	where StepTypeID not in (1107,1108) --Remove Loop
	group by JobLogID, RunSeq, JobID, StepID, StepName, StepTypeID, StepOrder, StepSeq


	--select js.JobStarted
	--		, DATEDIFF(HOUR,js.JobStarted, je.JobEnded) JobRunHrs
	--		, x.RunSeq, x.JobID, x.StepID, x.StepName
	--		, s.Code LoopOnState
	--		, x.RecCount
	--		, DATEDIFF(second, x.StepStart, x.StepEnd) StepDurSec
	--		, DATEDIFF(s, x.StepStart, x.XFormEnd) XFormDurSec
	--		, DATEDIFF(s, x.XFormEnd, x.LayoutEnd) LayoutDurSec
	--	from #FinalHist x
	--		left outer join Lookups..States s on LoopStateID = s.ID
	--		join (select min(LogStamp) JobStarted, JobLogID from #RawHist group by JobLogID) js on js.JobLogID = x.JobLogID
	--		join (select Max(LogStamp) JobEnded, JobLogID from #RawHist group by JobLogID) je on je.JobLogID = x.JobLogID
	--	order by StepSeq

	declare @RunSeqMax int

	select @RunSeqMax = Max(RunSeq) from #FinalHist


	select x.JobID, x.StepID, x.StepName
			, s.Code LoopOnState

			, js.JobStarted Started1
			, DATEDIFF(HOUR,js.JobStarted, js.JobEnded) JobRunHrs1
			, x.RecCount RecCount1
			, DATEDIFF(MINUTE, x.StepStart, x.StepEnd) StepDurMin1
			, x.RecCount / case when DATEDIFF(MINUTE, x.StepStart, x.StepEnd) > 0 then DATEDIFF(MINUTE, x.StepStart, x.StepEnd) else 1 end RecPerMin1
			, DATEDIFF(MINUTE, x.StepStart, x.XFormEnd) XFormDurMin1
			, DATEDIFF(MINUTE, x.XFormEnd, x.LayoutEnd) LayoutDurMin1

			, js2.JobStarted Started2
			, DATEDIFF(HOUR,js2.JobStarted, js2.JobEnded) JobRunHrs2
			, x2.RecCount RecCount2
			, DATEDIFF(MINUTE, x2.StepStart, x2.StepEnd) StepDurMin2
			, x2.RecCount / case when DATEDIFF(MINUTE, x2.StepStart, x2.StepEnd) > 0 then DATEDIFF(MINUTE, x2.StepStart, x2.StepEnd) else 1 end RecPerMin2
			, DATEDIFF(MINUTE, x2.StepStart, x2.XFormEnd) XFormDurMin2
			, DATEDIFF(MINUTE, x2.XFormEnd, x2.LayoutEnd) LayoutDurMin2

			, js3.JobStarted Started3
			, DATEDIFF(HOUR,js3.JobStarted, js3.JobEnded) JobRunHrs3
			, x3.RecCount RecCount3
			, DATEDIFF(MINUTE, x3.StepStart, x3.StepEnd) StepDurMin3
			, x3.RecCount / case when DATEDIFF(MINUTE, x3.StepStart, x3.StepEnd) > 0 then DATEDIFF(MINUTE, x3.StepStart, x3.StepEnd) else 1 end RecPerMin3
			, DATEDIFF(MINUTE, x3.StepStart, x3.XFormEnd) XFormDurMin3
			, DATEDIFF(MINUTE, x3.XFormEnd, x3.LayoutEnd) LayoutDurMin3

			, js4.JobStarted Started4
			, DATEDIFF(HOUR,js4.JobStarted, js4.JobEnded) JobRunHrs4
			, x4.RecCount RecCount4
			, DATEDIFF(MINUTE, x4.StepStart, x4.StepEnd) StepDurMin4
			, x4.RecCount / case when DATEDIFF(MINUTE, x4.StepStart, x4.StepEnd) > 0 then DATEDIFF(MINUTE, x4.StepStart, x4.StepEnd) else 1 end RecPerMin4
			, DATEDIFF(MINUTE, x4.StepStart, x4.XFormEnd) XFormDurMin4
			, DATEDIFF(MINUTE, x4.XFormEnd, x4.LayoutEnd) LayoutDurMin4

			, js5.JobStarted Started5
			, DATEDIFF(HOUR,js5.JobStarted, js5.JobEnded) JobRunHrs5
			, x5.RecCount RecCount5
			, DATEDIFF(MINUTE, x5.StepStart, x5.StepEnd) StepDurMin5
			, x5.RecCount / case when DATEDIFF(MINUTE, x5.StepStart, x5.StepEnd) > 0 then DATEDIFF(MINUTE, x5.StepStart, x5.StepEnd) else 1 end RecPerMin5
			, DATEDIFF(MINUTE, x5.StepStart, x5.XFormEnd) XFormDurMin5
			, DATEDIFF(MINUTE, x5.XFormEnd, x5.LayoutEnd) LayoutDurMin5

		from #FinalHist x
			left outer join Lookups..States s on LoopStateID = s.ID
			left outer join #FinalHist x2 on x2.JobID = x.JobID
											and x2.StepID = x.StepID
											and x2.LoopStateID = x.LoopStateID
											and x2.RunSeq = x.RunSeq - 1
			left outer join #FinalHist x3 on x3.JobID = x.JobID
											and x3.StepID = x.StepID
											and x3.LoopStateID = x.LoopStateID
											and x3.RunSeq = x.RunSeq - 2
			left outer join #FinalHist x4 on x4.JobID = x.JobID
											and x4.StepID = x.StepID
											and x4.LoopStateID = x.LoopStateID
											and x4.RunSeq = x.RunSeq - 3
			left outer join #FinalHist x5 on x5.JobID = x.JobID
											and x5.StepID = x.StepID
											and x5.LoopStateID = x.LoopStateID
											and x5.RunSeq = x.RunSeq - 4
			join (select min(LogStamp) JobStarted, max(logstamp) JobEnded, JobLogID from #RawHist group by JobLogID) js on js.JobLogID = x.JobLogID
			join (select min(LogStamp) JobStarted, max(logstamp) JobEnded, JobLogID from #RawHist group by JobLogID) js2 on js2.JobLogID = x2.JobLogID
			join (select min(LogStamp) JobStarted, max(logstamp) JobEnded, JobLogID from #RawHist group by JobLogID) js3 on js3.JobLogID = x3.JobLogID
			join (select min(LogStamp) JobStarted, max(logstamp) JobEnded, JobLogID from #RawHist group by JobLogID) js4 on js4.JobLogID = x4.JobLogID
			join (select min(LogStamp) JobStarted, max(logstamp) JobEnded, JobLogID from #RawHist group by JobLogID) js5 on js5.JobLogID = x5.JobLogID
		where x.RunSeq = @RunSeqMax
		--order by x.StepSeq
		order by x.StepID, S.code


END
