/****** Object:  ScalarFunction [dbo].[ValidationFieldCond]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE function dbo.ValidationFieldCond
(
	@RecID int, @TableName varchar(500)
)
RETURNS varchar(max)
As
Begin

	declare @FieldName varchar(100), @FieldSource varchar(100), @SuccessPct int, @CautionPct int, @AbovePct bit, @DataCheck varchar(50), @SpecificValue varchar(50)

	declare @UseTableName varchar(500)
	if @TableName is null
		set @UseTableName = '##DataTableName##'
	else
		set @UseTableName = @TableName

	declare @Cond varchar(100)
	declare @eCond varchar(100)
	declare @Targets varchar(200)
	declare @SuccessCond varchar(500)
	declare @LevelCond varchar(500)
	declare @UseXForm bit
	declare @cmdA varchar(max)
	declare @cmdB varchar(max)
	declare @cmdC varchar(max)


	select @FieldName = coalesce(fl.OutName, tc.Outname)
			, @SuccessPct = v.SuccessPct
			, @CautionPct = v.CautionPct
			, @AbovePct = coalesce(v.AbovePct,0)
			, @DataCheck = v.DataCheck
			, @SpecificValue = v.SpecificValue
			, @UseXForm = case when Fl.RecID > 0 then 0 else 1 end
	from JobControl..XFormFieldValidations v
		left outer join JobControl..FileLayoutFields fl on fl.RecID = v.LayoutFieldID and fl.FileLayoutID = v.LayoutID and coalesce(Fl.Disabled,0) = 0
		left outer join JobControl..FileLayouts f on f.Id = v.LayoutID
		left outer join JobControl..TransformationTemplateColumns tc on tc.RecID = v.XFormFieldID and tc.TransformTemplateID = f.TransformationTemplateId
	where coalesce(v.disabled,0) = 0
		and v.RecID = @RecID

	set @cond = case when @DataCheck = 'isblank' then ' ltrim(rtrim(' + @FieldName + ')) = '''' '
					when @DataCheck = 'isnotblank' then ' ltrim(rtrim(' + @FieldName + ')) > '''' '
					when @DataCheck = 'Isnumeric' then ' ltrim(rtrim(isnumeric(' + @FieldName + '))) = 1 '
					when @DataCheck = 'Isnotnumeric' then ' ltrim(rtrim(isnumeric(' + @FieldName + '))) = 0 '
					when @DataCheck = 'Specific' then ' ltrim(rtrim(' + @FieldName + ')) = ''' + @SpecificValue + ''' '
					when @DataCheck = 'Contains' then ' ltrim(rtrim(' + @FieldName + ')) like ''%' + @SpecificValue + '%'' '
					else '' end

	set @econd = case when @DataCheck = 'isblank' then ' is blank '
					when @DataCheck = 'isnotblank' then ' is filled '
					when @DataCheck = 'Isnumeric' then ' is a number '
					when @DataCheck = 'Isnotnumeric' then ' is not a number '
					when @DataCheck = 'Specific' then ' is ' + @SpecificValue + ' '
					when @DataCheck = 'Contains' then ' has ' + @SpecificValue + ' '
					else '' end

	declare @Op varchar(10) = '>='
	declare @Op2 varchar(10) = '<'
	if @AbovePct = 0
	Begin
		set @Op = '<'
		set @Op2 = '>='
	End

	set @SuccessCond = 'case when y.Pct ' + @Op + ' ' + ltrim(str(@SuccessPct)) + ' and y.TotalRecs > 0 then 0 else 1 end'
	if @CautionPct > 0
		set @LevelCond = 'case when y.Pct ' + @Op + ' ' + ltrim(str(@SuccessPct)) + ' and y.TotalRecs > 0 then 3 
								when y.Pct ' + @Op2 + ' ' + ltrim(str(@CautionPct)) + ' and y.TotalRecs > 0 then 2 else 1 end'
	else
		set @LevelCond = 'case when y.Pct ' + @Op + ' ' + ltrim(str(@SuccessPct)) + ' and y.TotalRecs > 0 then 3 else 1 end'

	if @CautionPct > 0
		begin
			set @Targets = ' '' Trgts: Fails if ' + iif(@AbovePct = 0, 'less then ', 'more then ') + format(@SuccessPct,'##0') + '% / Warns if ' + iif(@AbovePct = 0, 'less then ', 'more then ')+ format(@CautionPct,'##0') + '%'''
		end
	else
		begin
			set @Targets = ' '' Trgt: Fails if ' + iif(@AbovePct = 0, 'less then ', 'more then ') + format(@SuccessPct,'##0') + '%'''
		end

	set @cmdC = ''

	if @Cond > ''
	begin

		set @cmdA  = 'select count(*) TotalRecs, coalesce(sum(case when ' + @cond + ' then 1 else 0 end),0) IsFilled from ' + @UseTableName
		set @CmdB = ' select z.*, convert(money,(convert(money, IsFilled) / (convert(money, TotalRecs) + 0.001 )) * 100) + 0.001 Pct from (' + @cmdA + ') z '

		set @CmdC = ' select ''' + upper(@FieldName) + @econd + 'in '' + format(y.IsFilled,''#,##0'') + '' of '' + format(y.TotalRecs,''#,##0'') + '' Recs ('' + format(y.pct,''##0.00'') + ''%)'' '
		set @CmdC = @CmdC + ' + ' + @Targets + ' ResultDetail '
		set @CmdC = @CmdC + char(10) + ', ' + @SuccessCond + ' ResultPass '
		set @CmdC = @CmdC + char(10) + ', ' + @LevelCond + ' LogLevel '
		set @CmdC = @CmdC + char(10) + ' from (' + @cmdB + ') y '
	end


	RETURN @CmdC

end
