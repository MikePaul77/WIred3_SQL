/****** Object:  TableFunction [dbo].[XFORMTSQLParts]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.XFORMTSQLParts 
(
	@JobStepID int, @XFormTempID int, @XFormFieldID int, @PivotValuesCSV varchar(max)
)
RETURNS @XFormParts table ( FromClause varchar(max) null
							, JoinClause varchar(max) null
							, WhereClause varchar(max) null
							, IntoClause varchar(max) null
							, SourceFields varchar(max) null
							, FieldList1 varchar(max) null
							, FieldList2 varchar(max) null
							, FieldList3 varchar(max) null
							, FieldList4 varchar(max) null
							, FieldList5 varchar(max) null
							, FieldList6 varchar(max) null
							, ClauseFrameWork varchar(max) null 
	)
AS
BEGIN
	


	Declare @FromClause varchar(max) 
	Declare @JoinClause varchar(max)
	Declare @WhereClause varchar(max)
	Declare @IntoClause varchar(max)
	Declare @SourceFields varchar(max) 
	Declare @FieldList1 varchar(max) 
	Declare @FieldList2 varchar(max) 
	Declare @FieldList3 varchar(max) 
	Declare @FieldList4 varchar(max)
	Declare @FieldList5 varchar(max)
	Declare @FieldList6 varchar(max)
	Declare @GroupByClause varchar(max)
	declare @PivotCalcClause varchar(1000)
	declare @PivotCalcFunc varchar(1000)
	Declare @PivotClause varchar(max)
	declare @PivotValueList varchar(max)
	declare @PivotValueField varchar(200)
    declare @TableName varchar(200), @ControlRepStep int, @ControlRepStepInLoop int
    declare @InLoop int
	declare @JobStarted datetime
 
   declare @sep VARCHAR(10) = ''

	Declare @WorkDB varchar(50) = 'JobControlWork'
	
	declare @SrcTable varchar(200), @StepTable varchar(200) , @ReportCountTables varchar(200)

	declare @QueryTemplateID int = -999

	Declare @UseJobStepID int, @JobID INT, @JobRecurringTypeCode varchar(10)
	set @UseJobStepID = @JobStepID
	if @JobStepID is not null
		begin
			select @SrcTable = Djst.StepName + 'StepResults_J' + ltrim(str(Djs.JobID)) + '_S' + ltrim(str(Djs.StepID)) 
					, @StepTable = jst.StepName + 'StepResultsA_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
					, @XFormTempID = js.TransformationID
					, @InLoop = JobControl.dbo.InLoop(@UseJobStepID)
					, @ControlRepStep = Djs2.stepID
					, @ControlRepStepInLoop = JobControl.dbo.InLoop(Djs2.stepID)
					, @JobID = js.JobID
					, @JobRecurringTypeCode = jrt.Code
					, @JobStarted  = j.StartedStamp
				from JobSteps js
					join Jobs j on js.JobID = j.JobID 
					left outer join JobControl..JobRecurringTypes jrt on jrt.ID = j.RecurringTypeID
					left outer join JobStepTypes jst on jst.StepTypeID =js.StepTypeID
					left outer join JobSteps Djs on js.JobID = Djs.JobID and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(Djs.StepID)) + ',%'
					left outer join JobStepTypes Djst on Djst.StepTypeID = Djs.StepTypeID
					left outer join JobSteps Djs2 on js.JobID = Djs2.JobID and ',' + Djs2.DependsOnStepIDs + ',' like '%,' + ltrim(str(js.StepID)) + ',%'
				where js.StepID = @UseJobStepID
		end
	else
		begin
			set @UseJobStepID = -777
			set @SrcTable = ''
			set @StepTable = ''

			if @XFormFieldID is not null
				select @XFormTempID = TransformTemplateID from TransformationTemplateColumns where recID = @XFormFieldID  

		end

	declare @IssueWeek varchar(10)
	select @IssueWeek = jpW.ParamValue
	from JobControl..JobSteps js
		join JobControl..JobParameters jpW on jpW.JobID = js.JobID and jpW.ParamName in ('IssueWeek') 
	where js.StepID = @JobStepID

	declare @CalYear varchar(10)

	select @CalYear = jpw.ParamValue
	from JobControl..JobSteps js
		join JobControl..JobParameters jpW on jpW.JobID = js.JobID and jpW.ParamName in ('CalYear') 
	where js.StepID = @JobStepID

	if @IssueWeek is null
		select @IssueWeek = Issueweek from Support..IssueWeeks where convert(date,GETDATE()) >= LoModidate and convert(date,GETDATE()) <= HiModidate and stateID = 25

	--select @FromClause = s.Value + '..' + qt.FromPart
	select @FromClause = coalesce(qt.AlternateDB + '.dbo.',s.Value + '..') + qt.FromPart
		, @JoinClause = ltrim(coalesce(tt.TransformJoinClause,''))
		, @WhereClause = ltrim(coalesce(tt.TransformWhereClause,''))
		, @QueryTemplateID = coalesce(tt.QueryTemplateID, 0)
	from TransformationTemplates tt
		left outer join QueryTemplates qt on qt.Id = tt.QueryTemplateID
		join JobControl..Settings s on s.Property = 'ReportDatabase'
		left outer join FileLayouts fl on fl.TransformationTemplateId = tt.ID
	where tt.Id = @XFormTempID

	if @JoinClause like '%#JobStepID#%'
		set @JoinClause = replace(@JoinClause, '#JobStepID#', ltrim(str(@UseJobStepID)))
	if @JoinClause like '%#IssueWeek#%'
		set @JoinClause = replace(@JoinClause, '#IssueWeek#', case when @IssueWeek = 'FullLoad' then '-1' else @IssueWeek end )
	if @JoinClause like '%#CalYear#%'
		set @JoinClause = replace(@JoinClause, '#CalYear#', @CalYear)
	if @JoinClause like '%#JobID#%'
		set @JoinClause = replace(@JoinClause, '#JobID#', ltrim(str(@JobID)))
	if @JoinClause like '%#JobRecurringTypeCode#%'
		set @JoinClause = replace(@JoinClause, '#JobRecurringTypeCode#', '''' + @JobRecurringTypeCode + '''')
	if @JoinClause like '%#JobStarted#%'
		set @JoinClause = replace(@JoinClause, '#JobStarted#', '''' + convert(varchar(20),@JobStarted, 101) + ' ' + convert(varchar(20),@JobStarted, 114) + '''')

	if @WhereClause like '%#JobStepID#%'
		set @WhereClause = replace(@WhereClause, '#JobStepID#', ltrim(str(@UseJobStepID)))
	if @WhereClause like '%#IssueWeek#%'
		set @WhereClause = replace(@WhereClause, '#IssueWeek#', ltrim(str(@IssueWeek)))
	if @WhereClause like '%#JobID#%'
		set @WhereClause = replace(@WhereClause, '#JobID#', ltrim(str(@JobID)))
	if @WhereClause like '%#JobRecurringTypeCode#%'
		set @WhereClause = replace(@WhereClause, '#JobRecurringTypeCode#', '''' + @JobRecurringTypeCode + '''')
	if @WhereClause like '%#JobStarted#%'
		set @WhereClause = replace(@WhereClause, '#JobStarted#', '''' + convert(varchar(20),@JobStarted, 101) + ' ' + convert(varchar(20),@JobStarted, 114) + '''')


	if @QueryTemplateID = -1 or @QueryTemplateID = -2
	begin
			select @FromClause = @WorkDB + '..' + Djst.StepName + 'StepResults_J' + ltrim(str(Djs.JobID)) + '_S' + ltrim(str(Djs.StepID))
			from JobSteps js 
				left outer join JobStepTypes jst on jst.StepTypeID =js.StepTypeID
				left outer join JobSteps Djs on js.JobID = Djs.JobID and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(Djs.StepID)) + ',%'
				left outer join JobStepTypes Djst on Djst.StepTypeID = Djs.StepTypeID
			where js.StepID = @UseJobStepID

	end

	if @QueryTemplateID = -3  --CTLData
	begin

		 declare @Uniontables varchar(max) = ''

		-- This may be dependent of more then 1 Report
		 DECLARE UTcurA CURSOR FOR
			  select 'ReportStepRepCount_J' + ltrim(str(Djs.JobID)) + '_S' + ltrim(str(Djs.StepID))
					from JobSteps js 
						left outer join JobStepTypes jst on jst.StepTypeID =js.StepTypeID
						left outer join JobSteps Djs on js.JobID = Djs.JobID and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(Djs.StepID)) + ',%'
						left outer join JobStepTypes Djst on Djst.StepTypeID = Djs.StepTypeID
					where js.StepID = @UseJobStepID

		 OPEN UTcurA

		 FETCH NEXT FROM UTcurA into @TableName 
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				set @Uniontables = @Uniontables + @sep + 'Select * from ' + @WorkDB + '..' + @TableName  + char(10)
				set @Sep = ' union '
			  FETCH NEXT FROM UTcurA into @TableName 
		 END
		 CLOSE UTcurA
		 DEALLOCATE UTcurA

		set @FromClause = '(' + @Uniontables + ')'
		if @InLoop = 0 or (@ControlRepStep > 0 and @ControlRepStepInLoop = 0)   
			set @WhereClause = ' ' + @WhereClause + ' '
		else
			set @WhereClause = ' where __Processed = 0 '

	end


		declare @FldSrc varchar(1000), @FldID int, @FldSrcName varchar(1000), @FldSrcOut varchar(1000)
		declare @GroupBy bit, @CalcMax bit, @CalcMin bit, @CalcAvg bit, @CalcCount bit, @CalcSum bit, @CalcMedian bit
		declare @PivotCalcType varchar(50), @PivotVal bit, @PivotCalc varchar(50)
		declare @XFormFldSrc varchar(1000)
	 
		set @FieldList1 = ''
		set @FieldList2 = ''
		set @FieldList3 = ''
		set @FieldList4 = ''
		set @FieldList5 = ''
		set @FieldList6 = ''
		set @XFormFldSrc = ''
		set @GroupByClause = ''
		set @sep = ''
		declare @CalcFldSrc varchar(max) = ''

		DECLARE TransTempCol CURSOR FOR

		SELECT coalesce(SourceCode,'null') + ' [XF_' + OutName+ ']' FldSrc, RecID
				, coalesce(SourceCode,'null') FldSrcName
				, OutName FldSrcOut
				, coalesce(GroupByCol,0) GroupByCol
				, coalesce(CalcMaxCol,0) CalcMaxCol
				, coalesce(CalcMinCol,0) CalcMinCol
				, coalesce(CalcAvgCol,0) CalcAvgCol
				, coalesce(CalcCountCol,0) CalcCountCol
				, coalesce(CalcSumCol,0) CalcSumCol
				, coalesce(CalcMedianCol,0) CalcMedianCol
				, coalesce(PivotCalcType,'Int') PivotCalcType
				, coalesce(PivotValCol,0) PivotValCol
				, coalesce(PivotCalcCol,'None') PivotCalcCol

			FROM JobControl..TransformationTemplateColumns
			where TransformTemplateID = @XFormTempID and coalesce(disabled,0) = 0

		OPEN TransTempCol

		FETCH NEXT FROM TransTempCol into @FldSrc, @FldID, @FldSrcName, @FldSrcOut, @GroupBy, @CalcMax, @CalcMin, @CalcAvg, @CalcCount, @CalcSum, @CalcMedian, @PivotCalcType, @PivotVal, @PivotCalc
		WHILE (@@FETCH_STATUS <> -1)
		BEGIN
			if @FldSrc like '%#JobStepID#%'
				set @FldSrc = replace(@FldSrc, '#JobStepID#', ltrim(str(@UseJobStepID)))
			if @FldSrc like '%#IssueWeek#%'
				set @FldSrc = replace(@FldSrc, '#IssueWeek#', case when @IssueWeek = 'FullLoad' then '-1' else @IssueWeek end )
			if @FldSrc like '%#CalYear#%'
				set @FldSrc = replace(@FldSrc, '#CalYear#', @CalYear)
			if @FldSrc like '%#JobID#%'
				set @FldSrc = replace(@FldSrc, '#JobID#', ltrim(str(@JobID)))
			if @FldSrc like '%#JobRecurringTypeCode#%'
				set @FldSrc = replace(@FldSrc, '#JobRecurringTypeCode#', '''' + @JobRecurringTypeCode + '''')
			if @FldSrc like '%#JobStarted#%'
				set @FldSrc = replace(@FldSrc, '#JobStarted#', '''' + convert(varchar(20),@JobStarted, 101) + ' ' + convert(varchar(20),@JobStarted, 114) + '''')

			if @QueryTemplateID = -1  -- Group By
			begin
				if @GroupBy = 1
				begin
					declare @Add2Grp bit = 1
					if len(@FldSrcName) > 3
					Begin
						if left(@FldSrcName,1) = '#' and right(@FldSrcName,1) = '#'
							set @Add2Grp = 0
					End
					if @Add2Grp = 1
					begin
						set @GroupByClause = @GroupByClause + @sep + @FldSrcName
						set @sep = ', '
					end
				end
				if @CalcMax = 1
					set @CalcFldSrc = @CalcFldSrc + ', Max(Convert(' + @PivotCalcType + ',iif(' + @FldSrcName + '='''',null,' + @FldSrcName + '))) XF_' + @FldSrcOut + '_Max'
				if @CalcMin = 1
					set @CalcFldSrc = @CalcFldSrc + ', Min(Convert(' + @PivotCalcType + ',iif(' + @FldSrcName + '='''',null,' + @FldSrcName + '))) XF_' + @FldSrcOut + '_Min'
				if @CalcAvg = 1
					set @CalcFldSrc = @CalcFldSrc + ', Avg(Convert(' + @PivotCalcType + ',iif(' + @FldSrcName + '='''',null,' + @FldSrcName + '))) XF_' + @FldSrcOut + '_Avg'
				if @CalcCount = 1
					set @CalcFldSrc = @CalcFldSrc + ', Count(' + @FldSrcName + ') XF_' + @FldSrcOut + '_Count'
				if @CalcSum = 1
					set @CalcFldSrc = @CalcFldSrc + ', Sum(Convert(' + @PivotCalcType + ',' + @FldSrcName + ')) XF_' + @FldSrcOut + '_Sum'
				if @CalcMedian = 1		-- place holder to calc Median later since there is not Median aggregate function in SQL
					set @CalcFldSrc = @CalcFldSrc + ', Convert(' + @PivotCalcType + ',-1) XF_' + @FldSrcOut + '_Median'
				if @CalcMax = 1 or @CalcMin = 1 or @CalcAvg = 1 or @CalcCount = 1 or @CalcSum = 1 or @CalcMedian = 1
					set @FldSrc = ''
				if @GroupBy = 0 and @CalcMax = 0 and @CalcMin = 0 and @CalcAvg = 0 and @CalcCount = 0 and @CalcSum = 0 and @CalcMedian = 0
					set @FldSrc =  @FldSrcName + ' XF_' + @FldSrcOut
			end		

			if @QueryTemplateID = -2  -- Pivot
			begin
				if @PivotCalc <> 'None' and @PivotCalc > ''
				Begin
					Set @PivotCalcClause = 'Convert(' + @PivotCalcType + ',' + @FldSrcName + ') ' + @FldSrcOut
					if @PivotCalc = 'Median'
						set @PivotCalcFunc = 'Avg(' + @FldSrcOut + ')'	-- place holder to calc Median later since there is not Median aggregate function in SQL
					else
						set @PivotCalcFunc = @PivotCalc + '(' + @FldSrcOut + ')'
					set @FldSrc = ''	-- The Pivot retruns all the used fields so we don't want them 2 times
				end
				if @GroupBy = 1 or @PivotVal = 1
				begin
					if @PivotVal = 1
						set @GroupByClause = @GroupByClause + @sep + @FldSrcName + ' ' + @FldSrcOut
					else
						set @GroupByClause = @GroupByClause + @sep + @FldSrcName
					set @sep = ', '
					set @FldSrc = ''	-- The Pivot retruns all the used fields so we don't want them 2 times
				end
				if @PivotVal = 1
				begin
					set @PivotClause = ' ( select #GroupByClause#, #PivotCalcClause# from #FromClause# x) t Pivot ( #PivotCalcFunc# for ' + @FldSrcOut + ' in (#PivotValueList#) ) '
					set @PivotValueField = @FldSrcOut
				end

			end		


			if @FldSrc > ''
			begin
				if LEN(@FieldList1) < 4000 
					set @FieldList1 = @FieldList1 + ', ' + @FldSrc + char(13)
				else
					begin
						if LEN(@FieldList2) < 4000 
							set @FieldList2 = @FieldList2 + ', ' + @FldSrc + char(13)
						else
						begin
							if LEN(@FieldList3) < 4000 
								set @FieldList3 = @FieldList3 + ', ' + @FldSrc + char(13)
							else
							begin
								if LEN(@FieldList4) < 4000 
									set @FieldList4 = @FieldList4 + ', ' + @FldSrc + char(13)
								else
								begin
									if LEN(@FieldList5) < 4000 
										set @FieldList5 = @FieldList5 + ', ' + @FldSrc + char(13)
									else
									begin
										if LEN(@FieldList6) < 4000 
											set @FieldList6 = @FieldList6 + ', ' + @FldSrc + char(13)
									end
								end
							end
						end
					end

					if @FldID = @XFormFieldID
						set @XFormFldSrc = @FldSrc
			end

			FETCH NEXT FROM TransTempCol into @FldSrc, @FldID, @FldSrcName, @FldSrcOut, @GroupBy, @CalcMax, @CalcMin, @CalcAvg, @CalcCount, @CalcSum, @CalcMedian, @PivotCalcType, @PivotVal, @PivotCalc
		END
		CLOSE TransTempCol
		DEALLOCATE TransTempCol		
	
	if left(@FieldList1,1) = ',' and @QueryTemplateID = -1
		set @FieldList1 = substring(@FieldList1,2,len(@FieldList1) + 1)

	if @CalcFldSrc > '' and @QueryTemplateID = -1  -- Group By
	begin
		if LEN(@FieldList1) < 4000 
			set @FieldList1 = @FieldList1 + @CalcFldSrc + char(13)
		else
			begin
				if LEN(@FieldList2) < 4000 
					set @FieldList2 = @FieldList2 + @CalcFldSrc + char(13)
				else
				begin
					if LEN(@FieldList3) < 4000 
						set @FieldList3 = @FieldList3 + @CalcFldSrc + char(13)
					else
					begin
						if LEN(@FieldList4) < 4000 
							set @FieldList4 = @FieldList4 + @CalcFldSrc + char(13)
						else
						begin
							if LEN(@FieldList5) < 4000 
								set @FieldList5 = @FieldList5 + @CalcFldSrc + char(13)
							else
							begin
								if LEN(@FieldList6) < 4000 
									set @FieldList6 = @FieldList6 + @CalcFldSrc + char(13)
							end
						end
					end
				end
			end
	end

	if @QueryTemplateID = -2  -- Pivot
	begin
		set @PivotValueList = @PivotValuesCSV
		--exec JobControl.dbo.GetDistinctCSVSP 'JobControlWork..AppendStepResults_J3883_S22805','RecType', @builtcsv = @csv Output

		--declare @cmd nvarchar(max)

		--set @cmd = ' select @csv = COALESCE(@csv + '','' ,'''') + ' + @PivotValueField + '
		--		from (select distinct ' + @PivotValueField + ' 
		--				from ' + @FromClause + ') x '

		--declare @CSVout varchar(max) = ''

		--exec sp_executesql @cmd, N'@csv varchar(max) out', @CSVout out

		set @PivotClause = replace(@PivotClause,'#GroupByClause#', @GroupByClause)
		set @PivotClause = replace(@PivotClause,'#PivotCalcClause#', @PivotCalcClause)
		set @PivotClause = replace(@PivotClause,'#FromClause#', @FromClause)
		set @PivotClause = replace(@PivotClause,'#PivotCalcFunc#', @PivotCalcFunc)
		set @PivotClause = replace(@PivotClause,'#PivotValueList#', @PivotValueList)
		set @FromClause = @PivotClause 
	end		


	insert @XFormParts (FromClause
						, JoinClause
						, WhereClause
						, FieldList1
						, FieldList2, FieldList3, FieldList4, FieldList5, FieldList6
						, IntoClause
						, SourceFields
						, ClauseFrameWork)

		select case when coalesce(ltrim(@FromClause),'') = '' and @QueryTemplateID <> -4 then ''
					when @QueryTemplateID < 0 and @QueryTemplateID <> -4 then @FromClause
					when @JobStepID is not null then @WorkDB + '..' + @SrcTable
						else @FromClause
					end FromClause
				, case when coalesce(ltrim(@FromClause),'') = '' and @QueryTemplateID <> -4 then '' else @JoinClause end JoinClause
				, case when coalesce(ltrim(@FromClause),'') = '' and @QueryTemplateID <> -4 then '' 
					when @QueryTemplateID = -1 and @GroupByClause > '' then @WhereClause + char(13) + ' Group By ' + @GroupByClause 
					else @WhereClause end WhereClause
				, case when coalesce(ltrim(@FromClause),'') = '' and @QueryTemplateID <> -4 then ''
						when @XFormFieldID is not null then @XFormFldSrc 
						else @FieldList1 
					end FieldList1
				, case when coalesce(ltrim(@FromClause),'') = '' and @QueryTemplateID <> -4 then ''
						when @XFormFieldID is not null then '' 
						else @FieldList2 
					end FieldList2
				, case when coalesce(ltrim(@FromClause),'') = '' and @QueryTemplateID <> -4 then ''
						when @XFormFieldID is not null then ''
						else @FieldList3 
					end FieldList3					
				, case when coalesce(ltrim(@FromClause),'') = '' and @QueryTemplateID <> -4 then ''
						when @XFormFieldID is not null then ''
						else @FieldList4 
					end FieldList4					
				, case when coalesce(ltrim(@FromClause),'') = '' and @QueryTemplateID <> -4 then ''
						when @XFormFieldID is not null then ''
						else @FieldList5 
					end FieldList5					
				, case when coalesce(ltrim(@FromClause),'') = '' and @QueryTemplateID <> -4 then ''
						when @XFormFieldID is not null then ''
						else @FieldList6 
					end FieldList6					
				, case when @XFormFieldID is not null then ''
						when @JobStepID is not null then 'into ' + @WorkDB + '..' + @StepTable
						else 'into ' + @WorkDB + '..TestXForm_' + ltrim(str(@XFormTempID))
					end IntoClause
				, case when coalesce(ltrim(@FromClause),'') = '' and @QueryTemplateID <> -4 then ''
						when @XFormFieldID is not null then ''
						when @QueryTemplateID = -1 and @GroupByClause > '' then ''
						else 'x.*'
					end SourceFields
				, case when coalesce(ltrim(@FromClause),'') = '' then ''
						when @JobStepID is not null then
							'select #SourceFields# #FieldList1# #FieldList2# #FieldList3# #FieldList4# #FieldList5# #FieldList6# #IntoClause# From #FromClause# x #JoinClause# #WhereClause# '
						when @XFormFieldID is not null then 
							'select top 100 #FieldList1# From #FromClause# x #JoinClause# #WhereClause# '
						else 
							'select top 100 #SourceFields# #FieldList1# #FieldList2# #FieldList3# #FieldList4# #FieldList5# #FieldList6# #IntoClause# From #FromClause# x #JoinClause# #WhereClause# '
					end ClauseFrameWork
					

	RETURN
END
