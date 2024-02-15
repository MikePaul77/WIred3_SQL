/****** Object:  Procedure [dbo].[UpdateQueryFromJobParams_TEST]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.UpdateQueryFromJobParams_TEST @StepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @ParamValue varchar(100), @ParamName varchar(50), @QueryID int, @JobID int, 
		@SQLCmd varchar(max), @TemplateID int, @QueryStateID int, @cond varchar(10),
		@StartMark int, @EndMark int, @IssueWeek varchar(10), @LoIssueWeek varchar(10),
		@HiIssueWeek varchar(10), @LoModidate varchar(50), @HiModidate varchar(50),
		@IWClause varchar(500), @IssueFound bit = 0, @PreBuild int

	select @JobID = js.JobID
			, @QueryID = js.QueryCriteriaID
			, @SQLCmd = q.SQLCmd
			, @TemplateID = q.TemplateID
			, @PreBuild=iif(isnull(js.PreBuildQuery,0)=0,0,1)
		from JobControl..JobSteps js
			join QueryEditor..Queries q on js.QueryCriteriaID = q.ID
		where js.StepID = @StepID

	select @QueryStateID = StateID from QueryEditor..QueryLocations where QueryID = @QueryID and StateID is not null
	print 'QueryStateID: ' + convert(varchar,@QueryStateID)
	print 'QueryID: ' + ltrim(str(@QueryID))
	print 'JobID: ' + ltrim(str(@JobID))
	print 'PreBuild: ' + convert(varchar,@PreBuild)
	print 'SQL: ' + @SQLCmd

	select @LoIssueWeek = min(iw.IssueWeek)
		, @HiIssueWeek = Max(iw.IssueWeek)
		, @LoModidate = convert(varchar(50),Min(iw.LoModidate),101)
		, @HiModidate = convert(varchar(50),Max(iw.HiModidate),101)
	from JobControl..JobSteps js
		join JobControl..JobParameters jpW on jpW.JobID = js.JobID and jpW.ParamName in ('IssueMonth') 
		join Support..IssueWeeks iw on iw.StateID = @QueryStateID
									and month(iw.Issuedate) = convert(int,left(jpW.ParamValue,2))
									and year(iw.Issuedate) = convert(int,right(jpW.ParamValue,4))
	where js.StepID = @StepID
	
	Print '@LoIssueWeek: ' + isnull(@LoIssueWeek, '')
	Print '@HiIssueWeek: ' + isnull(@HiIssueWeek, '')
	Print '@LoModiDate: ' + isnull(@LoModiDate, '')
	Print '@HiModiDate: ' + isnull(@HiModiDate, '')

	if @@ROWCOUNT > 0 and @IssueFound = 0 and @LoIssueWeek is not null
	begin

		set @IssueFound = 1
		
		set @IWClause = ' and ((( coalesce(ModificationDate,''' + @LoModidate + ''') >= ''' + @LoModidate + ''' )  and ( coalesce(ModificationDate,''' + @HiModidate + ''') <= ''' + @HiModidate + ''' )) or (( ProcessYearWeek >= ' + @LoIssueWeek + ' )  and ( ProcessYearWeek <= ' + @HiIssueWeek + ' )))'
		if @TemplateID = 4	-- Properties don't have IssueWeeks
			set @IWClause = ' and ((( coalesce(ModificationDate,''' + @LoModidate + ''') >= ''' + @LoModidate + ''' )  and ( coalesce(ModificationDate,''' + @HiModidate + ''') <= ''' + @HiModidate + ''' )))'
	
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

		set @StartMark = CHARINDEX('#IssueWeekClauseStart#',@SQLCmd) + len('#IssueWeekClauseStart#') + 1
		set @EndMark = CHARINDEX('#IssueWeekClauseEnd#',@SQLCmd) - 3
		if @StartMark > 0 and @EndMark > 0 and @IWClause is not null
			set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + @IWClause + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))

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

		set @IWClause = ' and ((( coalesce(ModificationDate,''' + @LoModidate + ''') >= ''' + @LoModidate + ''' )  and ( coalesce(ModificationDate,''' + @HiModidate + ''') <= ''' + @HiModidate + ''' )) or (( ProcessYearWeek >= ' + @IssueWeek + ' )  and ( ProcessYearWeek <= ' + @IssueWeek + ' )))'
		if @TemplateID = 4	-- Properties don't have IssueWeeks
			set @IWClause = ' and ((( coalesce(ModificationDate,''' + @LoModidate + ''') >= ''' + @LoModidate + ''' )  and ( coalesce(ModificationDate,''' + @HiModidate + ''') <= ''' + @HiModidate + ''' )))'
	
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

		set @StartMark = CHARINDEX('#IssueWeekClauseStart#',@SQLCmd) + len('#IssueWeekClauseStart#') + 1
		set @EndMark = CHARINDEX('#IssueWeekClauseEnd#',@SQLCmd) - 3
		if @StartMark > 0 and @EndMark > 0 and @IWClause is not null
			set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + @IWClause + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))

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

				end

			update QueryEditor..QueryRanges 
				set MinValue = @LoTFDdate
					, MaxValue = @HiTFDdate
				where QueryID = @QueryID and RangeSource = 'TransFilingDateRange'

			if @@ROWCOUNT = 0
				insert QueryEditor..QueryRanges (QueryID, MinValue, MaxValue, RangeSource) values (@QueryID, @LoTFDdate, @HiTFDdate, 'TransFilingDateRange')

		end

		set @StartMark = CHARINDEX('#TransFilingDateClauseStart#',@SQLCmd) + len('#TransFilingDateClauseStart#') + 1
		set @EndMark = CHARINDEX('#TransFilingDateClauseEnd#',@SQLCmd) - 3

		if @StartMark > 0 and @EndMark > 0 and @TemplateID not in (4)
			set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + coalesce(@TFDClause,'') + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))


	 declare @Loc varchar(2000)
	 set @Loc = ''
	 set @cond = ''

     DECLARE curParamA CURSOR FOR
		select jp.ParamValue, jp.ParamName 
			from JobControl..JobSteps js
				join JobControl..JobParameters jp on jp.JobID = js.JobID
			where js.StepID = @StepID
				and jp.ParamName in ('StateID','CountyID') 

     OPEN curParamA

     FETCH NEXT FROM curParamA into @ParamValue, @ParamName
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
			set @Loc = @Loc + @cond + '[' + @ParamName + '] = ' + @ParamValue

			update QueryEditor..QueryLocations 
				set StateID = case when @ParamName = 'StateID' then @ParamValue else null end
					, CountyID = case when @ParamName = 'CountyID' then @ParamValue else null end
				where QueryID = @QueryID

			set @cond = ' and '
			FETCH NEXT FROM curParamA into @ParamValue, @ParamName
     END
     CLOSE curParamA
     DEALLOCATE curParamA
	 print '@Loc: ' + @Loc;
	 print '@cond: ' + @cond;

	 declare @seq int = 1
	 if @Loc > ''
	 begin
		while CHARINDEX('#LocationClauseStart' + ltrim(str(@seq)) + '#',@SQLCmd) > 0
		begin
			set @StartMark = CHARINDEX('#LocationClauseStart' + ltrim(str(@seq)) + '#',@SQLCmd) + len('#LocationClauseStart' + ltrim(str(@seq)) + '#') + 1
			set @EndMark = CHARINDEX('#LocationClauseEnd' + ltrim(str(@seq)) + '#',@SQLCmd) - 3
			set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + @Loc + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))
			set @seq = @seq + 1
		end

	 end

	update QueryEditor..Queries set SQLCmd = @SQLCmd where ID = @QueryID;
	Print '-------------------------------';
	Print '@SQLCmd: ';
	Print @SQLCmd;


END
