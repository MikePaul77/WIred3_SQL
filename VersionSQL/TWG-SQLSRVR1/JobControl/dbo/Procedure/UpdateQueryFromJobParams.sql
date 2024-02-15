/****** Object:  Procedure [dbo].[UpdateQueryFromJobParams]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.UpdateQueryFromJobParams @StepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @DefaultQueryParamVersion int
	select @DefaultQueryParamVersion = Value from JobControl..Settings where Property = 'DefaultQueryParamVersion'
	declare @QueryParamVersion int

	declare @ParamValue varchar(100), @ParamName varchar(50)
	declare @QueryID int, @JobID int, @SQLCmd varchar(max), @TemplateID int, @QueryStateID int, @QueryTypeID int, @QuerySourceStepID int
	declare @cond varchar(10)

	select @JobID = js.JobID
			, @QueryID = js.QueryCriteriaID
			, @SQLCmd = q.SQLCmd
			, @TemplateID = js.QueryTemplateID
			, @QueryTypeID = qt.QueryTypeID
			, @QuerySourceStepID = coalesce(QuerySourceStepID,0)
			, @QueryParamVersion = coalesce(QueryParamVersion,@DefaultQueryParamVersion)
		from JobControl..JobSteps js
			join QueryEditor..Queries q on js.QueryCriteriaID = q.ID
			join JobControl..QueryTemplates qt on qt.Id = q.TemplateID
		where js.StepID = @StepID

	if @QuerySourceStepID > 0
	begin

		select @JobID = js.JobID
				, @QueryID = js.QueryCriteriaID
				, @SQLCmd = q.SQLCmd
				, @TemplateID = js.QueryTemplateID
				, @QueryTypeID = qt.QueryTypeID
			from JobControl..JobSteps js
				join QueryEditor..Queries q on js.QueryCriteriaID = q.ID
				join JobControl..QueryTemplates qt on qt.Id = q.TemplateID
			where js.StepID = @QuerySourceStepID

	end


	if @TemplateID not in (1060)	--- Not Locations
	begin
		if CHARINDEX('#LocationClauseStart1#',@SQLCmd) = 0
			set @SQLCmd = @SQLCmd + char(10) + '--#LocationClauseStart1#' + char(10) + char(10) + '--#LocationClauseEnd1#' + char(10)
		if CHARINDEX('#TransFilingDateClauseStart#',@SQLCmd) = 0
			set @SQLCmd = @SQLCmd + char(10) + '--#TransFilingDateClauseStart#' + char(10) + char(10) + '--#TransFilingDateClauseEnd#' + char(10)
		if CHARINDEX('#IssueWeekClauseStart#',@SQLCmd) = 0
			set @SQLCmd = @SQLCmd + char(10) + '--#IssueWeekClauseStart#' + char(10) + char(10) + '--#IssueWeekClauseEnd#' + char(10)
		--if CHARINDEX('#IssueWeekClause2Start#',@SQLCmd) = 0
		--	set @SQLCmd = @SQLCmd + char(10) + '--#IssueWeekClause2Start#' + char(10) + char(10) + '--#IssueWeekClause2End#' + char(10)
	end

	--select @QueryStateID = StateID from QueryEditor..QueryLocations where QueryID = @QueryID and StateID is not null
	-- We need to get the Current stateID to update curret IssueWeek Dates
	EXEC JobControl..GetQueryStepStateID @StepID, @StateID = @QueryStateID output

	 declare @StartMark int
	 declare @EndMark int

	--print 'QueryID: ' + ltrim(str(@QueryID))
	--print 'JobID: ' + ltrim(str(@JobID))
	--print @SQLCmd

	declare @IssueWeek varchar(10)
	declare @LoIssueWeek varchar(10)
	declare @HiIssueWeek varchar(10)
	declare @LoModidate varchar(50)
	declare @HiModidate varchar(50)
	declare @IWClause varchar(500)
	declare @IssueMonth varchar(10)
	declare @CreatedIWClause varchar(500)

	declare @IssueFound bit = 0

	select @LoIssueWeek = min(iw.IssueWeek)
		, @HiIssueWeek = Max(iw.IssueWeek)
		, @LoModidate = convert(varchar(50),Min(iw.LoModidate),101)
		, @HiModidate = convert(varchar(50),Max(iw.HiModidate),101)
		, @IssueMonth = Max(jpW.ParamValue)
	from JobControl..JobSteps js
		join JobControl..JobParameters jpW on jpW.JobID = js.JobID and jpW.ParamName in ('IssueMonth') 
		join Support..IssueWeeks iw on iw.StateID = @QueryStateID
									and month(iw.Issuedate) = convert(int,left(jpW.ParamValue,2))
									and year(iw.Issuedate) = convert(int,right(jpW.ParamValue,4))
	where js.StepID = @StepID


	if @@ROWCOUNT > 0 and @IssueFound = 0 and @LoIssueWeek is not null
	begin

		set @IssueFound = 1
		
		if @QueryParamVersion = 1
		begin

			set @IWClause = ' and ((( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' )) or (( ProcessYearWeek >= ' + @LoIssueWeek + ' )  and ( ProcessYearWeek <= ' + @HiIssueWeek + ' )))'

			if @TemplateID in (6,1081)	-- Properties don't have IssueWeeks
				set @IWClause = ' and ( ProcessYearWeek >= ' + @LoIssueWeek + ' and ProcessYearWeek <= ' + @HiIssueWeek + ' )'

			if @TemplateID in (4,1079,1092)	-- Properties don't have IssueWeeks
				set @IWClause = ' and (( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' )) '

			if @TemplateID in (1070)	-- Properties don't have IssueWeeks
				set @IWClause = ' and ( Support.FuncLib.PadWithLeft(month(TownLiveDate),2,''0'') + ltrim(str(Year(TownLiveDate))) = ''' + @IssueMonth + ''' )'

			if @TemplateID in (1078)	-- Properties don't have IssueWeeks
				set @IWClause = ' and ((( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' ))
										or (( convert(date,TownLiveDate) >= ''' + @LoModidate + ''' )  and ( convert(date,TownLiveDate) <= ''' + @HiModidate + ''' )))'

			if @TemplateID = 1073	-- Assessor Sales
				set @IWClause = ' and ((( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' )))'

			if @QueryTypeID = 15	-- Stats
			Begin
				if @JobID = 4031
					set @IWClause = ' and ((ThisYear * 100) + StatMonth) >= ((convert(int, right(''' + @IssueMonth + ''',4)) - 2 ) * 100) + convert(int, left(''' + @IssueMonth + ''',2))
										and ((ThisYear * 100) + StatMonth) <= ((convert(int, right(''' + @IssueMonth + ''',4))) * 100) + convert(int, left(''' + @IssueMonth + ''',2)) '
				else
					set @IWClause = ' and ( IssueMonth = ''' + @IssueMonth + ''')'
			end

			update QueryEditor..QueryRanges 
				set MinValue = @IssueMonth
					, MaxValue = @IssueMonth
				where QueryID = @QueryID and RangeSource = 'TownLiveIssueMonth'
			if @@ROWCOUNT = 0
				insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @IssueMonth, @IssueMonth,'TownLiveIssueMonth')
			
			update QueryEditor..QueryRanges 
				set MinValue = @LoModidate
					, MaxValue = @HiModidate
				where QueryID = @QueryID and RangeSource = 'ModificationDate'
			if @@ROWCOUNT = 0
				insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @LoModidate, @HiModidate,'ModificationDate')

			update QueryEditor..QueryRanges 
				set MinValue = @LoIssueWeek
					, MaxValue = @HiIssueWeek
				where QueryID = @QueryID and RangeSource like '%ProcessWeek%'

			if @@ROWCOUNT = 0
				insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @LoIssueWeek, @HiIssueWeek,'ProcessWeek')

		end

		if @QueryParamVersion = 2
		begin

			set @IWClause = ' and (StateModIssueMonth = ' + @IssueMonth + ' or ( ProcessYearWeek >= ' + @LoIssueWeek + ' )  and ( ProcessYearWeek <= ' + @HiIssueWeek + ' ))'

			if @TemplateID in (1084,1090) -- National FA Properties
				set @IWClause = ' '

			if @QueryTypeID = 25	-- National FA PreForcl
				set @IWClause = ' and (( convert(date,FATimeStamp) >= ''' + @LoModidate + ''' )  and ( convert(date,FATimeStamp) <= ''' + @HiModidate + ''' )) '

			if @TemplateID in (6,1081)	-- Properties don't have IssueWeeks
				set @IWClause = ' and ( ProcessYearWeek >= ' + @LoIssueWeek + ' and ProcessYearWeek <= ' + @HiIssueWeek + ' )'

			if @TemplateID in (4,1079,1092,1099)	-- Properties don't have IssueWeeks
				set @IWClause = ' and (StateModIssueMonth = ' + @IssueMonth + ') '

			if @TemplateID in (1070)	-- Properties don't have IssueWeeks
				set @IWClause = ' and ( Support.FuncLib.PadWithLeft(month(TownLiveDate),2,''0'') + ltrim(str(Year(TownLiveDate))) = ''' + @IssueMonth + ''' )'

			if @TemplateID in (1078)	-- Properties don't have IssueWeeks
				set @IWClause = ' and ((( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' ))
										or (( convert(date,TownLiveDate) >= ''' + @LoModidate + ''' )  and ( convert(date,TownLiveDate) <= ''' + @HiModidate + ''' )))'

			if @TemplateID = 1073	-- Assessor Sales
				set @IWClause = ' and ((( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' )))'

			if @QueryTypeID = 15	-- Stats
			Begin
				if @JobID = 4031
					set @IWClause = ' and ((ThisYear * 100) + StatMonth) >= ((convert(int, right(''' + @IssueMonth + ''',4)) - 2 ) * 100) + convert(int, left(''' + @IssueMonth + ''',2))
										and ((ThisYear * 100) + StatMonth) <= ((convert(int, right(''' + @IssueMonth + ''',4))) * 100) + convert(int, left(''' + @IssueMonth + ''',2)) '
				else
					set @IWClause = ' and ( IssueMonth = ''' + @IssueMonth + ''')'
			end

			update QueryEditor..QueryRanges 
				set MinValue = @IssueMonth
					, MaxValue = @IssueMonth
				where QueryID = @QueryID and RangeSource = 'TownLiveIssueMonth'
			if @@ROWCOUNT = 0
				insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @IssueMonth, @IssueMonth,'TownLiveIssueMonth')
			
			update QueryEditor..QueryRanges 
				set MinValue = @LoModidate
					, MaxValue = @HiModidate
				where QueryID = @QueryID and RangeSource = 'ModificationDate'
			if @@ROWCOUNT = 0
				insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @LoModidate, @HiModidate,'ModificationDate')

			update QueryEditor..QueryRanges 
				set MinValue = @LoIssueWeek
					, MaxValue = @HiIssueWeek
				where QueryID = @QueryID and RangeSource like '%ProcessWeek%'

			if @@ROWCOUNT = 0
				insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @LoIssueWeek, @HiIssueWeek,'ProcessWeek')

		end

		set @StartMark = CHARINDEX('#IssueWeekClauseStart#',@SQLCmd) + len('#IssueWeekClauseStart#') + 1
		set @EndMark = CHARINDEX('#IssueWeekClauseEnd#',@SQLCmd) - 3
		if @StartMark > 0 and @EndMark > 0 and @IWClause is not null
			set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + @IWClause + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))

		--set @StartMark = CHARINDEX('#IssueWeekClause2Start#',@SQLCmd) + len('#IssueWeekClause2Start#') + 1
		--set @EndMark = CHARINDEX('#IssueWeekClause2End#',@SQLCmd) - 3
		--if @StartMark > 0 and @EndMark > 0 and @IWClause is not null
		--Begin
		--	set @CreatedIWClause = @IWClause
		--	set @CreatedIWClause = replace(@CreatedIWClause,'StateModIssueWeek','MtgCreatedIssueWeek')
		--	set @CreatedIWClause = replace(@CreatedIWClause,'ProcessYearWeek','SaleCreatedIssueWeek')
		--	set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + @CreatedIWClause + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))
		--End

	end	

	select @IssueWeek = iw.IssueWeek
		, @LoModidate = convert(varchar(50),iw.LoModidate,101)
		, @HiModidate = convert(varchar(50),iw.HiModidate,101)
	from JobControl..JobSteps js
		join JobControl..JobParameters jpW on jpW.JobID = js.JobID and jpW.ParamName in ('IssueWeek') 
		join Support..IssueWeeks iw on iw.Issueweek = jpW.ParamValue and iw.StateID = @QueryStateID
	where js.StepID = @StepID
	
	if @@ROWCOUNT > 0 and @IssueFound = 0
	begin

		set @IssueFound = 1

		if @QueryParamVersion = 1
		begin

			set @IWClause = ' and ((( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' )) or (( ProcessYearWeek >= ' + @IssueWeek + ' )  and ( ProcessYearWeek <= ' + @IssueWeek + ' )))'

			if @QueryTypeID = 25	-- National FA PreForcl
				set @IWClause = ' and (( convert(date,FATimeStamp) >= ''' + @LoModidate + ''' )  and ( convert(date,FATimeStamp) <= ''' + @HiModidate + ''' )) '

			if @TemplateID in (6,1081)
				set @IWClause = ' and ( ProcessYearWeek >= ' + @IssueWeek + ' and ProcessYearWeek <= ' + @IssueWeek + ' )'

			if @TemplateID in (4,1079,1092)	-- Properties don't have IssueWeeks
				set @IWClause = ' and (( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' )) '

			if @TemplateID in (1070)	-- Properties don't have IssueWeeks
				set @IWClause = ' and ( Support.FuncLib.PadWithLeft(month(TownLiveDate),2,''0'') + ltrim(str(Year(TownLiveDate))) = ''' + @IssueMonth + ''' )'

			if @QueryTypeID = 18	-- Job Control Data
				set @IWClause = ' and ( Param_IssueWeek = ''' + @IssueWeek + ''' )'

			if @TemplateID in (1078)	-- Properties don't have IssueWeeks
				set @IWClause = ' and ((( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' ))
										or (( convert(date,TownLiveDate) >= ''' + @LoModidate + ''' )  and ( convert(date,TownLiveDate) <= ''' + @HiModidate + ''' )))'

			if @TemplateID = 1073	-- Assessor Sales
				set @IWClause = ' and ((( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' )))'

			update QueryEditor..QueryRanges 
				set MinValue = @LoModidate
					, MaxValue = @HiModidate
				where QueryID = @QueryID and RangeSource = 'ModificationDate'
			if @@ROWCOUNT = 0
				insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @LoModidate, @HiModidate,'ModificationDate')

			if @IssueWeek is not null
			begin
				update QueryEditor..QueryRanges 
					set MinValue = @IssueWeek
						, MaxValue = @IssueWeek
					where QueryID = @QueryID and RangeSource like '%ProcessWeek%'

				if @@ROWCOUNT = 0
					insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @IssueWeek, @IssueWeek,'ProcessWeek')
			end

		end

		if @QueryParamVersion = 2
		begin

			set @IWClause = ' and (StateModIssueWeek = ' + @IssueWeek + ' or ProcessYearWeek = ' + @IssueWeek + ' )'

			if @TemplateID in (1084,1090) -- National FA Properties
				set @IWClause = ''

			if @QueryTypeID = 25	-- National FA PreForcl
				set @IWClause = ' and (( convert(date,FATimeStamp) >= ''' + @LoModidate + ''' )  and ( convert(date,FATimeStamp) <= ''' + @HiModidate + ''' )) '

			if @TemplateID in (6,1081)
				set @IWClause = ' and ( ProcessYearWeek >= ' + @IssueWeek + ' and ProcessYearWeek <= ' + @IssueWeek + ' )'

			if @TemplateID in (4,1079,1092,1099)	-- Properties don't have IssueWeeks
				set @IWClause = ' and (StateModIssueWeek = ' + @IssueWeek + ') '

			if @TemplateID in (1070)	-- Properties don't have IssueWeeks
				set @IWClause = ' and ( Support.FuncLib.PadWithLeft(month(TownLiveDate),2,''0'') + ltrim(str(Year(TownLiveDate))) = ''' + @IssueMonth + ''' )'

			if @QueryTypeID = 18	-- Job Control Data
				set @IWClause = ' and ( Param_IssueWeek = ''' + @IssueWeek + ''' )'

			if @TemplateID in (1078)	-- Properties don't have IssueWeeks
				set @IWClause = ' and ((( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' ))
										or (( convert(date,TownLiveDate) >= ''' + @LoModidate + ''' )  and ( convert(date,TownLiveDate) <= ''' + @HiModidate + ''' )))'

			if @TemplateID = 1073	-- Assessor Sales
				set @IWClause = ' and ((( convert(date,ModificationDate) >= ''' + @LoModidate + ''' )  and ( convert(date,ModificationDate) <= ''' + @HiModidate + ''' )))'

			update QueryEditor..QueryRanges 
				set MinValue = @LoModidate
					, MaxValue = @HiModidate
				where QueryID = @QueryID and RangeSource = 'ModificationDate'
			if @@ROWCOUNT = 0
				insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @LoModidate, @HiModidate,'ModificationDate')

			if @IssueWeek is not null
			begin
				print 'XX'
				update QueryEditor..QueryRanges 
					set MinValue = @IssueWeek
						, MaxValue = @IssueWeek
					where QueryID = @QueryID and RangeSource like '%ProcessWeek%'

				if @@ROWCOUNT = 0
					insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @IssueWeek, @IssueWeek,'ProcessWeek')
			end

		end

		set @StartMark = CHARINDEX('#IssueWeekClauseStart#',@SQLCmd) + len('#IssueWeekClauseStart#') + 1
		set @EndMark = CHARINDEX('#IssueWeekClauseEnd#',@SQLCmd) - 3
		if @StartMark > 0 and @EndMark > 0 and @IWClause is not null
			set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + @IWClause + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))

		--set @StartMark = CHARINDEX('#IssueWeekClause2Start#',@SQLCmd) + len('#IssueWeekClause2Start#') + 1
		--set @EndMark = CHARINDEX('#IssueWeekClause2End#',@SQLCmd) - 3
		--if @StartMark > 0 and @EndMark > 0 and @IWClause is not null
		--Begin
		--	set @CreatedIWClause = @IWClause
		--	set @CreatedIWClause = replace(@CreatedIWClause,'StateModIssueWeek','MtgCreatedIssueWeek')
		--	set @CreatedIWClause = replace(@CreatedIWClause,'ProcessYearWeek','SaleCreatedIssueWeek')
		--	set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + @CreatedIWClause + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))
		--End

	end	

	declare @LoTFDdate varchar(50)
	declare @HiTFDdate varchar(50)
	declare @TFDClause varchar(500)

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

		from JobControl..JobSteps js
			left outer join JobControl..JobParameters jpP on jpP.JobID = js.JobID and jpP.ParamName in ('CalPeriod') 
			left outer join JobControl..JobParameters jpY on jpY.JobID = js.JobID and jpY.ParamName in ('CalYear') 
		where js.StepID = @StepID	

		set @TFDClause = ''

		declare @GenFilingDateField varchar(100) = 'FilingDate'
		declare @MtgFilingDateField varchar(100)
		declare @SaleFilingDateField varchar(100)

		select @MtgFilingDateField = AltName
			from QueryEditor.dbo.GetAltFieldNames(@TemplateID, 'FilingDate', 'mtg')

		select @SaleFilingDateField = AltName
			from QueryEditor.dbo.GetAltFieldNames(@TemplateID, 'FilingDate', 'sale')

		--set @MtgFilingDateField = coalesce(@MtgFilingDateField,@GenFilingDateField)
		--set @SaleFilingDateField = coalesce(@SaleFilingDateField,@GenFilingDateField)

		if @HiTFDdate is not null and @LoTFDdate is not null
		begin

			if @MtgFilingDateField is not null and @SaleFilingDateField is not null
			begin
					set @TFDClause = ' and ((( ' + @SaleFilingDateField + ' >= ''' + @LoTFDdate + ''' ) and ( ' + @SaleFilingDateField + ' <= ''' + @HiTFDdate + ''' ))
										 or (( ' + @MtgFilingDateField + ' >= ''' + @LoTFDdate + ''' ) and ( ' + @MtgFilingDateField + ' <= ''' + @HiTFDdate + ''' ))) '
			end
			else
				begin
					set @TFDClause = ' and (( ' + @GenFilingDateField + ' >= ''' + @LoTFDdate + ''' )  and ( ' + @GenFilingDateField + ' <= ''' + @HiTFDdate + ''' )) '
	
					if @MtgFilingDateField is not null
						set @TFDClause = ' and (( ' + @MtgFilingDateField + ' >= ''' + @LoTFDdate + ''' )  and ( ' + @MtgFilingDateField + ' <= ''' + @HiTFDdate + ''' )) '

					if @SaleFilingDateField is not null
						set @TFDClause = ' and (( ' + @SaleFilingDateField + ' >= ''' + @LoTFDdate + ''' )  and ( ' + @SaleFilingDateField + ' <= ''' + @HiTFDdate + ''' )) '

				end

			update QueryEditor..QueryRanges 
				set MinValue = @LoTFDdate
					, MaxValue = @HiTFDdate
				where QueryID = @QueryID and RangeSource = 'TransFilingDateRange'

			if @@ROWCOUNT = 0
				insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @LoTFDdate, @HiTFDdate, 'TransFilingDateRange')

		end

		if @TFDClause > ''
		Begin

			set @StartMark = CHARINDEX('#TransFilingDateClauseStart#',@SQLCmd) + len('#TransFilingDateClauseStart#') + 1
			set @EndMark = CHARINDEX('#TransFilingDateClauseEnd#',@SQLCmd) - 3

			if @StartMark > 0 and @EndMark > 0 and @TemplateID not in (4)
				set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + coalesce(@TFDClause,'') + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))

		end

	 declare @Loc varchar(2000)
	 Declare @InLoop bit

	select @Loc = ' [StateID] in (' + ParamValue + ')'
			, @InLoop = JobControl.dbo.InLoop(js.StepID)
		from JobControl..JobSteps js
			join JobControl..JobParameters jp on jp.JobID = js.JobID
		where js.StepID = @StepID
--				and jp.ParamName in ('StateID','CountyID') 
			and jp.ParamName in ('StateID') 

	 declare @seq int = 1
	 if @Loc > '' and @InLoop = 0
	 begin
		while CHARINDEX('#LocationClauseStart' + ltrim(str(@seq)) + '#',@SQLCmd) > 0
		begin
			set @StartMark = CHARINDEX('#LocationClauseStart' + ltrim(str(@seq)) + '#',@SQLCmd) + len('#LocationClauseStart' + ltrim(str(@seq)) + '#') + 1
			set @EndMark = CHARINDEX('#LocationClauseEnd' + ltrim(str(@seq)) + '#',@SQLCmd) - 3

			if @seq = 1 
				set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + @Loc + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))
			else
				set @SQLCmd = left(@SQLCmd, @StartMark) + ' 1=2 ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))

			set @seq = @seq + 1
		end

	 end

	update QueryEditor..Queries set SQLCmd = @SQLCmd where ID = @QueryID

END
