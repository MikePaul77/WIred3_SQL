/****** Object:  Procedure [dbo].[JC_AuditStep_CountCheck]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_AuditStep_CountCheck @JobStepID int, @GroupRecID int

AS
BEGIN
	SET NOCOUNT ON;

		declare @Results varchar(1000)
		declare @ResultLevel int
		declare @ResultPass int
		declare @LastRuns int
		declare @FailPct money
		declare @WarnPct money
		declare @ValID int
		declare @Disabled bit

		create table #Results (ResultPass int, ResultLevel int, Results varchar(1000))

		declare @XFormLayoutID int
		declare @XFormStepID int

		Select @XFormLayoutID = js.FileLayoutID
				, @XFormStepID = js.StepID
			from JobControl..JobSteps js
				join JobControl..JobStepTypes st on js.StepTypeID = st.StepTypeID
			where js.StepID = @JobStepID

			print @XFormLayoutID

			select @LastRuns = LastRuns
					, @FailPct = PctFail
					, @WarnPct = PctWarn
					, @ValID = RecID
					, @Disabled = coalesce(Disabled,1)
				from JobControl..XFormRunCountValidataions
				where LayoutID = @XFormLayoutID


			if @ValID > 0 and @Disabled = 0 and @LastRuns > 0
			begin

				declare @PctDif money

				declare @LastAvgTot money
				declare @CurrRunTot money

				drop table if exists #last

				select jl.ID RunID, jl.starttime, convert(int,slh.LogInformation) StepRecords
					, seq = ROW_NUMBER() OVER (PARTITION BY jl.JobID ORDER BY jl.starttime desc)
					into #last
					from JobControl..JobStepLogHist slh
						join JobControl..JobLog jl on jl.JobID = slh.JobID
													and coalesce(jl.TestMode,0) = 0
													and slh.JobLogID = jl.ID
					where isnumeric(slh.LogInformation) = 1
						and slh.LogInfoSource in ('StepRecordCount') 
						and slh.LogInfoType = 1
						and slh.JobStepID = @XFormStepID

				select @LastAvgTot = Avg(x.StepRecords)
					from (
						select hrA.StepRecords
							from #last hrA
							where hrA.seq <= @LastRuns
						) x

				select @CurrRunTot = x.StepRecords
					from (
						select hrA.StepRecords
							from #last hrA
								join #last hrB on hrA.seq + 1 = HrB.seq
							where hrA.Seq = 1
						) x


				select @PctDif = Abs(((@CurrRunTot - @LastAvgTot) / @LastAvgTot) *100) 

				select @ResultPass = case when @PctDif > @FailPct then 0 else 1 end 
						, @ResultLevel = case when @PctDif > @FailPct then 3 when @PctDif > @WarnPct then 2 else 1 end 
						, @Results = 'Cur: ' + format(@CurrRunTot,'#,##0') + ' Last ' + ltrim(str(@LastRuns)) 
									+  ' Avg: ' + format(@LastAvgTot,'#,##0') + ' (' + format(@PctDif,'##0.0') + '% Chg)'
									+ ' Trgt Fail/Warn: ' + ltrim(str(@FailPct)) + '% / ' + ltrim(str(@WarnPct)) + '% Chg'

				insert #Results (ResultPass, ResultLevel, Results)
					select @ResultPass, @ResultLevel, @Results

			end


	if @GroupRecID = 0
		select @GroupRecID, *, 'CountCheck' ValType
				from #Results
	else
		insert JobControl..ValsOtherCount (GroupRecID, ValPass, ValLevel, ValResult, ValType)
		select @GroupRecID, *, 'CountCheck' ValType
				from #Results

END
