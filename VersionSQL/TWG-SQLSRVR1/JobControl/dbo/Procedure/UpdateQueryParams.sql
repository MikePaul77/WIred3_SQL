/****** Object:  Procedure [dbo].[UpdateQueryParams]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.UpdateQueryParams @JobStepID int, @CountQueryID int
AS
BEGIN
	SET NOCOUNT ON;

	--### Only for Version 3+ Queries

	print 'A ' + convert(varchar(50),getdate(),22)

	declare @QueryID int, @JobID int, @SQLCmd varchar(max), @TemplateID int, @QueryTypeID int, @QuerySourceStepID int
			,  @QueryParmID int, @JobParamValue varchar(10), @QueryPerviousPeriods int
			, @IMRangeList varchar(3000), @JParamName varchar(100), @FullLoadCond varchar(2000)

	DECLARE curUpDtP CURSOR FOR
		select js.JobID, q.ID, q.SQLCmdBaseV2, q.TemplateID, qt.QueryTypeID, coalesce(QuerySourceStepID,0)
				, coalesce(qp1.MapParamID,qp2.MapParamID,qp3.MapParamID,0), jpw.ParamValue, coalesce(qp1.PreviousPeriods,0)
				, jpw.ParamName, coalesce(qt.FullLoadCond,'') FullLoadCond		
			from QueryEditor..Queries q
				left outer join JobControl..JobSteps js on js.QueryCriteriaID = q.ID
				join JobControl..QueryTemplates qt on qt.Id = coalesce(q.TemplateID, js.QueryTemplateID)
				left outer join JobControl..JobParameters jpW on jpW.JobID = js.JobID
				left outer join QueryEditor..QueryParameters qp1 on qp1.QueryID = q.ID and QP1.ParamTypeID > 0 
																	and qp1.MapParamID in (1,2,3) and jpW.ParamName <> 'StateID'
				left outer join QueryEditor..QueryParameters qp2 on qp2.QueryID = q.ID and QP2.ParamTypeID > 0 
																	and qp2.MapParamID = 4 and jpW.ParamName = 'StateID'
				left outer join QueryEditor..QueryParameters qp3 on qp3.QueryID = q.ID and QP3.ParamTypeID > 0 
																	and qp3.MapParamID in (1,2,3) and js.JobID is null
			where js.StepID = @JobStepID
				or q.id =  @CountQueryID

     OPEN curUpDtP

     FETCH NEXT FROM curUpDtP into @JobID, @QueryID, @SQLCmd, @TemplateID, @QueryTypeID, @QuerySourceStepID
								, @QueryParmID, @JobParamValue, @QueryPerviousPeriods, @JParamName, @FullLoadCond
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

	declare @QueryStateID int

		--select @QueryStateID = StateID from QueryEditor..QueryLocations where QueryID = @QueryID and StateID is not null
	-- We need to get the Current stateID to update curret IssueWeek Dates

	print 'B ' + convert(varchar(50),getdate(),22)

	EXEC JobControl..GetQueryStepStateID @JobStepID, @StateID = @QueryStateID output

	print 'C ' + convert(varchar(50),getdate(),22)

	select top 1 @QueryStateID = ID	
	from (
		select ID, 1 OrdCtl from Lookups..States where Mode = 'Core' and LocationActiveState = 1 and ID = @QueryStateID
		union select ID, 2 OrdCtl from Lookups..States where Mode = 'Bulk' and LocationActiveState = 1
	) x
	order by OrdCtl

	print 'D ' + convert(varchar(50),getdate(),22)

	declare @IssueWeek varchar(10)
	declare @LoIssueWeek varchar(10)
	declare @HiIssueWeek varchar(10)
	declare @IWLoModidate varchar(50)
	declare @IWHiModidate varchar(50)
	declare @IMLoModidate varchar(50)
	declare @IMHiModidate varchar(50)
	declare @IssueMonth varchar(10)
	declare @LoTFDdate varchar(50)
	declare @HiTFDdate varchar(50)
	declare @StateVal varchar(20)

--select @JobStepID JobStepID
--	, @QueryParmID QueryParmID
--	, @QueryStateID QueryStateID
--	, @JobParamValue JobParamValue
--	, @QueryPerviousPeriods QueryPerviousPeriods

	if @JobParamValue <> 'FullLoad'
	Begin

	print 'E ' + convert(varchar(50),getdate(),22)

		if @QueryParmID = 1 -- IW
		Begin

			select @LoIssueWeek = iw.MinIssueWeek
				, @HiIssueWeek = iw.MaxIssueWeek
				, @IWLoModidate = convert(varchar(50),iw.MinLoModidate,101)
				, @IWHiModidate = convert(varchar(50),iw.MaxHiModidate,101) 
			from JobControl..JobSteps js
				join JobControl..JobParameters jpW on jpW.JobID = js.JobID and jpW.ParamName in ('IssueWeek') 
				join QueryEditor..QueryParameters qp on qp.QueryID = js.QueryCriteriaID and qp.MapParamID = 1
				join (select Max(Issueweek) MaxIssueWeek
						, min(Issueweek) MinIssueWeek
						, Min(LoModidate) MinLoModidate
						, Max(HiModidate) MaxHiModidate
					from (
						select Issueweek, LoModidate, HiModidate
								, seq = ROW_NUMBER() over (order by issueweek desc)
							from Support..IssueWeeks
								where Issueweek <= @JobParamValue
									and StateID = @QueryStateID
						) x
					where Seq <= @QueryPerviousPeriods + 1
					) iw on 1=1
				where js.StepID = @JobStepID
			
			if @CountQueryID > 0
			Begin

				-- Get the previous week for a count
				select @IssueWeek = Issueweek
					, @LoIssueWeek = Issueweek
					, @HiIssueWeek = Issueweek
					, @IWLoModidate = convert(varchar(50),LoModidate,101)
					, @IWHiModidate = convert(varchar(50),HiModidate,101) 
					from (
						select Issueweek, LoModidate, HiModidate
							, seq = ROW_NUMBER() over (order by issueweek desc)
							from Support..IssueWeeks 
							where DataImportComplete is not null
								and StateID = @QueryStateID
						) x
					where x.seq = 2
			end

			print 'F ' + convert(varchar(50),getdate(),22)

		End
		if @QueryParmID = 2 -- IM
		Begin


			select @LoIssueWeek = iw.MinIssueWeek
				, @HiIssueWeek = iw.MaxIssueWeek
				, @IMLoModidate = convert(varchar(50),iw.MinLoModidate,101)
				, @IMHiModidate = convert(varchar(50),iw.MaxHiModidate,101)
				, @IssueMonth = jpW.ParamValue
				, @IMRangeList = substring((select ',''' + IssueMonth + ''''
									from (
											select im.IssueMonth
													, seq = ROW_NUMBER() over (order by im.SortableIssueMonth desc)
													from Support..IssueMonth im
												where im.SortableIssueMonth <= (convert(int,right(jpW.ParamValue,4)) * 100) + convert(int,left(jpW.ParamValue,2))
													and im.StateID = @QueryStateID
											) x
										where Seq <= @QueryPerviousPeriods + 1

									order by x.seq
									for XML path('') 
								),2,2000)

			from JobControl..JobSteps js
				join JobControl..JobParameters jpW on jpW.JobID = js.JobID and jpW.ParamName in ('IssueMonth') 
				join QueryEditor..QueryParameters qp on qp.QueryID = js.QueryCriteriaID and qp.MapParamID = 2
				join (select Min(LoModidate) MinLoModidate
							, Max(HiModidate) MaxHiModidate
							, Min(BeginWeek) MinIssueWeek
							, Max(EndWeek) MaxIssueWeek
						from (
							select im.IssueMonth, im.BeginWeek, im.endweek, iwS.LoModidate, iwE.HiModidate
									, seq = ROW_NUMBER() over (order by im.SortableIssueMonth desc)
									from Support..IssueMonth im
										join Support..IssueWeeks iwS on iwS.StateID = im.stateID and iwS.Issueweek = im.BeginWeek
										join Support..IssueWeeks iwE on iwE.StateID = im.stateID and iwE.Issueweek = im.EndWeek
								where im.SortableIssueMonth <= (convert(int,right(@JobParamValue,4)) * 100) + convert(int,left(@JobParamValue,2))
									and im.StateID = @QueryStateID
							) x
						where Seq <= @QueryPerviousPeriods + 1
						) iw on 1=1
			where js.StepID = @JobStepID

			if @CountQueryID > 0
			begin
				select 
						@LoIssueWeek = BeginWeek
					, @HiIssueWeek = endweek
					, @IMLoModidate = convert(varchar(50),LoModidate,101)
					, @IMHiModidate = convert(varchar(50),HiModidate,101)
					, @IssueMonth = IssueMonth
							from (
								select im.IssueMonth, im.BeginWeek, im.endweek, iwS.LoModidate, iwE.HiModidate
									, seq = ROW_NUMBER() over (order by im.SortableIssueMonth desc)
									from Support..IssueMonth im
										join Support..IssueWeeks iwS on iwS.StateID = im.stateID and iwS.Issueweek = im.BeginWeek
										join Support..IssueWeeks iwE on iwE.StateID = im.stateID and iwE.Issueweek = im.EndWeek
									where im.DataImportComplete is not null
										and im.StateID = @QueryStateID
								) x

			end

			print 'G ' + convert(varchar(50),getdate(),22)

		End

		if @QueryParmID= 3 -- CP
		Begin
			declare @PeriodType varchar(10)
			select @LoTFDdate = case when jpY.ParamName = 'CalYear' and jpP.ParamName is null then '1/1/' + jpY.ParamValue
										when jpP.ParamValue = 'Q1' then '1/1/' + jpY.ParamValue
										when jpP.ParamValue = 'Q2' then '4/1/' + jpY.ParamValue
										when jpP.ParamValue = 'Q3' then '7/1/' + jpY.ParamValue
										when jpP.ParamValue = 'Q4' then '10/1/' + jpY.ParamValue
										when jpP.ParamValue = 'YR' then '1/1/' + jpY.ParamValue	-- Added 1/10/2019 - Mark W.
										else jpP.ParamValue + '/1/' + jpY.ParamValue end
					, @HiTFDdate = case when jpY.ParamName = 'CalYear' and jpP.ParamName is null then '12/31/' + jpY.ParamValue
										when jpP.ParamValue = 'Q1' then '3/31/' + jpY.ParamValue
										when jpP.ParamValue = 'Q2' then '6/30/' + jpY.ParamValue
										when jpP.ParamValue = 'Q3' then '9/30/' + jpY.ParamValue
										when jpP.ParamValue = 'Q4' then '12/31/' + jpY.ParamValue
										when jpP.ParamValue = 'YR' then '12/31/' + jpY.ParamValue  -- Added 1/10/2019 - Mark W.
										else convert(varchar(50),EOMONTH(jpP.ParamValue + '/1/' + jpY.ParamValue),101) end
					, @PeriodType = case when jpP.ParamValue = 'YR' then 'Year'
										when jpP.ParamValue like 'Q%' then 'Quarter'
										else 'Month' end
				from JobControl..JobSteps js
					left outer join JobControl..JobParameters jpP on jpP.JobID = js.JobID and jpP.ParamName in ('CalPeriod') 
					left outer join JobControl..JobParameters jpY on jpY.JobID = js.JobID and jpY.ParamName in ('CalYear') 
				where js.StepID = @JobStepID
				if @QueryPerviousPeriods > 0
				begin
					declare @UseLowDate date
					Set @UseLowDate = @LoTFDdate
					if @PeriodType = 'Month'
						set @UseLowDate = dateadd(MONTH, @QueryPerviousPeriods * -1,@UseLowDate)
					if @PeriodType = 'Quarter'
						set @UseLowDate = dateadd(QUARTER, @QueryPerviousPeriods * -1,@UseLowDate)
					if @PeriodType = 'Year'
						set @UseLowDate = dateadd(YEAR, @QueryPerviousPeriods * -1,@UseLowDate)
					set @LoTFDdate = convert(varchar(50),@UseLowDate,101)
				end

			if @CountQueryID > 0
			begin

				select @LoTFDdate = ltrim(str(month(getdate()))) + '/1/' + ltrim(str(year(getdate())))
					, @HiTFDdate = convert(varchar(50),EOMONTH(ltrim(str(month(getdate()))) + '/1/' + ltrim(str(year(getdate())))),101)
					, @PeriodType = 'Month'

			end

			print 'H ' + convert(varchar(50),getdate(),22)


		End
		if @QueryParmID = 4 -- State
		Begin
			select @StateVal = substring((select ',''' + case when qp.ParamTypeID = 19 then s.code else ltrim(str(s.ID)) end + ''''
															from Lookups..States s 
															where ',' + jp.ParamValue + ',' like '%,' + ltrim(str(s.Id)) + ',%'
														for XML path('') 
													),2,2000)

				from JobControl..JobSteps js
					join QueryEditor..QueryParameters qp on qp.QueryID = js.QueryCriteriaID and qp.MapParamID = 4
					join JobControl..JobParameters jp on jp.JobID = js.JobID and jp.ParamName in ('StateID')
				where js.StepID = @JobStepID
		End

	End -- End of Not FullLoad

	--select @IssueWeek IssueWeek
	--, @LoIssueWeek LoIssueWeek
	--, @HiIssueWeek HiIssueWeek
	--, @IWLoModidate IWLoModidate
	--, @IWHiModidate IWHiModidate
	--, @IMLoModidate IMLoModidate
	--, @IMHiModidate IMHiModidate
	--, @IssueMonth IssueMonth
	--, @LoTFDdate LoTFDdate
	--, @HiTFDdate HiTFDdate
	--, @IMRangeList IMRangeList
	--, @StateVal StateVal

	print 'I ' + convert(varchar(50),getdate(),22)

	print '---------------------Before------------------'
	print @SQLCmd
	print '---------------------------------------------'

	-- Clear any existing Param Clause

	declare @ParmPreFix varchar(50)
	declare @ParmStartMark int, @ParmEndMark int
	declare @ParmStartStr varchar(100), @ParmEndStr varchar(100)

	DECLARE curParamClean CURSOR FOR
	select 'TransFilingDate'
	union select 'TransModiDate'
	union select 'IssueWeek'

	OPEN curParamClean

	FETCH NEXT FROM curParamClean into @ParmPreFix
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		set @ParmStartStr = '--#' + @ParmPreFix + 'ClauseStart#'
		set @ParmEndStr = '--#' + @ParmPreFix + 'ClauseEnd#'

		set @ParmStartMark = CHARINDEX(@ParmStartStr,@SQLCmd) -1
		set @ParmEndMark = CHARINDEX(@ParmEndStr,@SQLCmd) + len(@ParmEndStr) + 1
		if @ParmStartMark > 0 and @ParmEndMark > 0
		Begin
			
			set @SQLCmd = SUBSTRING(@SQLCmd,1, @ParmStartMark) + SUBSTRING(@SQLCmd, @ParmEndMark, 4000) 

			print 'K ' + convert(varchar(50),getdate(),22)

		End
		FETCH NEXT FROM curParamClean into @ParmPreFix
	END
	CLOSE curParamClean
	DEALLOCATE curParamClean

	   
	print 'L ' + convert(varchar(50),getdate(),22)


	declare @ParamName varchar(100), @ReplaceValName varchar(100), @ReplaceRangeName varchar(100), @MapParamID int
	   	  
     DECLARE curActParms CURSOR FOR
		select pt.Name, coalesce(pt.ReplaceValName,''), coalesce(pt.ReplaceRangeName,''), p.MapParamID
			from QueryEditor..QueryParameters p
				join QueryEditor..QueryParamTypes pt on pt.ID = p.ParamTypeID
			where p.QueryID = @QueryID and p.ParamTypeID > 0
				and p.MapParamID > 0
     OPEN curActParms

     FETCH NEXT FROM curActParms into @ParamName, @ReplaceValName, @ReplaceRangeName, @MapParamID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

		declare @StartMark int, @EndMark int
		declare @WorkClause varchar(1000)
		declare @StartStr varchar(100), @EndStr varchar(100)
		declare @HighStr varchar(100), @LowStr varchar(100), @ValStr varchar(100)
		declare @HighVal varchar(100), @LowVal varchar(100)
		set @StartStr = '--#ParamClauseStart#'
		set @EndStr = '--#ParamClauseEnd#'
		set @HighStr = '##High' + @ReplaceRangeName + '##'
		set @LowStr = '##Low' + @ReplaceRangeName + '##'
		set @ValStr = '##' + @ReplaceValName + '##'

		set @HighVal = '???High???'
		set @LowVal = '???Low???'
		if @MapParamID = 1 -- IW
		Begin
			set @HighVal = @HiIssueWeek
			set @LowVal = @LoIssueWeek
		End
		if @MapParamID = 2 -- IM
		Begin
			set @HighVal = @HiIssueWeek
			set @LowVal = @LoIssueWeek
		End
		if @MapParamID = 3 -- CP
		Begin
			set @HighVal = @HiTFDdate
			set @LowVal = @LoTFDdate
		End

--select @HiTFDdate, @LoTFDdate

		set @StartMark = CHARINDEX(@StartStr,@SQLCmd) + len(@StartStr) + 1
		set @EndMark = CHARINDEX(@EndStr,@SQLCmd) - 1

		if @StartMark > 0 and @EndMark > 0
		Begin
			set @WorkClause = substring(@SQLCmd, @StartMark, @EndMark - @StartMark) 
			print @WorkClause
			print '================================'

			if @JobParamValue = 'FullLoad'
				begin

					set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))

				end
			else
				begin

				--select @ReplaceValName ReplaceValName, @WorkClause WorkClause
				--		, @ReplaceRangeName ReplaceRangeName
				--		, @MapParamID MapParamID, @ValStr ValStr, @IssueWeek IssueWeek
				--		, @StateVal
				--		, @IWLoModidate, @IWHiModidate
				--		, @QueryStateID
				--		, @QueryPerviousPeriods
				--		, @CountQueryID

					if @ReplaceValName > '' and @MapParamID = 1 -- IW
					Begin
						if @ReplaceValName = 'Date'
						begin
								set @WorkClause = replace(@WorkClause,'##High' + @ReplaceValName + '##',@IWHiModidate)
								set @WorkClause = replace(@WorkClause,'##Low' + @ReplaceValName + '##',@IWLoModidate)
						end
						else
							begin
								set @WorkClause = replace(@WorkClause,'##High' + @ReplaceValName + '##',@HighVal)
								set @WorkClause = replace(@WorkClause,'##Low' + @ReplaceValName + '##',@LowVal)
							end
					end

					if @ReplaceValName > '' and @MapParamID = 2 -- IM
					Begin
						if @ReplaceValName = 'Date'
						begin
								set @WorkClause = replace(@WorkClause,'##High' + @ReplaceValName + '##',@IMHiModidate)
								set @WorkClause = replace(@WorkClause,'##Low' + @ReplaceValName + '##',@IMLoModidate)
						end
						else
							begin
								set @WorkClause = replace(@WorkClause,'##High' + @ReplaceValName + '##',@HighVal)
								set @WorkClause = replace(@WorkClause,'##Low' + @ReplaceValName + '##',@LowVal)
								set @WorkClause = replace(@WorkClause,'##' + @ReplaceValName + '##',@JobParamValue)
							end
					end

					if @ReplaceValName > '' and @MapParamID = 3 -- CP
					Begin
						if @ReplaceValName = 'Date'
						begin
							if @TemplateID = 1116 and @PeriodType = 'Year' and charindex('and period =', @WorkClause) > 0 -- TrendLine Stats
									set @WorkClause = rtrim(left(@WorkClause,charindex('and period =',@WorkClause) - 1)) + ' and period = ''YR'' '

							set @WorkClause = replace(@WorkClause,'##High' + @ReplaceValName + '##',@HighVal)
							set @WorkClause = replace(@WorkClause,'##Low' + @ReplaceValName + '##',@LowVal)

						end
					end

					if @ReplaceValName > '' and @MapParamID = 4 -- State
					Begin
						if @ReplaceValName = 'States'
						begin
							set @WorkClause = replace(@WorkClause,'##' + @ReplaceValName + '##',@StateVal)
						end
					end

					if @HighStr > ''
						set @WorkClause = replace(@WorkClause,@HighStr,@HighVal)
					if @LowStr > ''
						set @WorkClause = replace(@WorkClause,@LowStr,@LowVal)

					print @WorkClause
			
					set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + @WorkClause + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))

				end -- Not FullLoad else

		 end  -- end of has start and end marks



          FETCH NEXT FROM curActParms into @ParamName, @ReplaceValName, @ReplaceRangeName, @MapParamID
     END
     CLOSE curActParms
     DEALLOCATE curActParms


		If @JobParamValue = 'FullLoad' 
		begin

			declare @MTStartStr varchar(100), @MTEndStr varchar(100)
			declare @MTStartMark int, @MTEndMark int
			set @MTStartStr = '--#ModiTypeStart#'
			set @MTEndStr = '--#ModiTypeEnd#'
			set @MTStartMark = CHARINDEX(@MTStartStr,@SQLCmd) + len(@MTStartStr) + 1
			set @MTEndMark = CHARINDEX(@MTEndStr,@SQLCmd) - 1

			if @MTStartMark > 0 and @MTEndMark > 0
				set @SQLCmd = left(@SQLCmd, @MTStartMark) + ' ' + substring(@SQLCmd,@MTEndMark,len(@SQLCmd))

			if @FullLoadCond > ''
				set @SQLCmd = @SQLCmd +  char(10) + '-- FullLoad Condition' + char(10) + ' and ' + @FullLoadCond + char(10)
			else
				set @SQLCmd = @SQLCmd +  char(10) + '-- FullLoad Condition' + char(10) + ' -- No full Load Condition Available ' + char(10)
		end



          FETCH NEXT FROM curUpDtP into @JobID, @QueryID, @SQLCmd, @TemplateID, @QueryTypeID, @QuerySourceStepID
								, @QueryParmID, @JobParamValue, @QueryPerviousPeriods, @JParamName, @FullLoadCond
     END
     CLOSE curUpDtP
     DEALLOCATE curUpDtP





	print '---------------------After------------------'
	print @SQLCmd
	print '---------------------------------------------'

	print 'Y ' + convert(varchar(50),getdate(),22)

	if @JobStepID > 0
		update QueryEditor..Queries set SQLCmd = @SQLCmd where ID = @QueryID
	else 
		select @WorkClause WorkClause, @StartStr StartStr, @EndStr EndStr

	print 'Z ' + convert(varchar(50),getdate(),22)


END
