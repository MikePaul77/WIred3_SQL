/****** Object:  ScalarFunction [dbo].[PreBuildTableName]    Committed by VersionSQL https://www.versionsql.com ******/

-- This function is called by the JobControl..JobThrottler_GetNextJob stored procedure.
CREATE FUNCTION dbo.PreBuildTableName
(
	@StepID int,
	@SQLCmd varchar(max)
)
RETURNS varchar(max)
AS
BEGIN
	DECLARE @NewFileName varchar(max) = ''

	declare @PreBuildQuery bit

	select @PreBuildQuery = isnull(js.PreBuildQuery,0)
			, @NewFileName = qt.FromPart
		from JobControl..JobSteps js
			join JobControl..QueryTemplates qt on qt.Id = js.QueryTemplateID
		where js.StepID = @StepID;

	if @PreBuildQuery = 1
	begin
		Declare @StateCode varchar(2), @StateID int
		select Top 1 @StateCode=s.Code, @StateID=q.StateID 
			from QueryEditor..QueryLocations q 
				join Lookups..states s on s.ID=q.StateID
			where q.StateID is not null
				and q.QueryID=(Select QueryCriteriaID from JobSteps where StepID=@StepID)


		--Set @NewFileName = Substring(@SQLCmd, CHARINDEX('from', @SQLCmd), (CHARINDEX('where', @SQLCmd)-CHARINDEX('from', @SQLCmd)));
		--Set @NewFileName = Substring(@SQLCmd, CHARINDEX('from', @SQLCmd), (CHARINDEX('--#FromClauseEnd#', @SQLCmd)-2-CHARINDEX('from', @SQLCmd)));
		--Set @NewFileName = 'JobControlWork..pb' + rtrim(ltrim(Substring(@NewFileName, CharIndex('..', @NewFileName)+2,500)));
		--Set @NewFileName = replace(@NewFileName, char(10), '');
		--Set @NewFileName = replace(@NewFileName, char(13), '');
		--Set @NewFileName = rtrim(ltrim(@NewFileName)) + '_' + @StateCode + '_';

		Set @NewFileName = 'JobControlWork..pb' + rtrim(ltrim(@NewFileName)) + '_' + @StateCode + '_';

		Declare @IssueMonth varchar(10)='',
			@IssueWeek varchar(10)='',
			@CalPeriod varchar(10)='',
			@CalYear varchar(10)='',
			@ParamName varchar(10)='',
			@ParamValue varchar(10)=''

		Declare jpCursor CURSOR for
			Select ltrim(rtrim(ParamName)), ParamValue from JobParameters 
				where JobID=(Select JobID from JobControl..JobSteps where StepID=@StepID)
		Open jpCursor;
		Fetch Next from jpCursor into @ParamName, @ParamValue;
		While @@Fetch_Status=0
		Begin
			if @ParamName='IssueMonth' and @IssueMonth='' set @IssueMonth=@ParamValue;
			if @ParamName='IssueWeek' and @IssueWeek='' set @IssueWeek=@ParamValue;
			if @ParamName='CalPeriod' and @CalPeriod='' set @CalPeriod=@ParamValue;
			if @ParamName='CalYear' and @CalYear='' set @CalYear=@ParamValue;
			Fetch Next from jpCursor into @ParamName, @ParamValue;
		End
		Close jpCursor;
		Deallocate jpCursor;

		If @IssueWeek<>''
			Begin
				Select @NewFileName=@NewFileName+'IW_' + @IssueWeek;
			End
		Else
			if @IssueMonth<>''
				Begin
					Select @NewFileName=@NewFileName+'IM_' + @IssueMonth;
				End
			else
				Begin
					Select @NewFileName=@NewFileName+'CP_' + @CalPeriod + @CalYear;
				End
	end

	RETURN @NewFileName

END
