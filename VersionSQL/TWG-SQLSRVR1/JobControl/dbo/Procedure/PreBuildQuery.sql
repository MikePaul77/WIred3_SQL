/****** Object:  Procedure [dbo].[PreBuildQuery]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 04/04/2019
-- Description:	PreBuild a table for faster state reporting
-- =============================================
CREATE PROCEDURE dbo.PreBuildQuery 
	-- Add the parameters for the stored procedure here
	@StepID int,
	@SQLCmd varchar(max),
	@NewFileName varchar(max) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	Print @SQLCMD;

	-- Get the current State
	Declare @StateCode varchar(2), @StateID int
	select Top 1 @StateCode=s.Code, @StateID=q.StateID 
		from QueryEditor..QueryLocations q 
			join Lookups..states s on s.ID=q.StateID
		where q.StateID is not null
			and q.QueryID=(Select QueryCriteriaID from JobSteps where StepID=@StepID)
	Print 'PreBuildQuery: Current State: ' + @StateCode
	Print 'PreBuildQuery: Current State ID: ' + convert(varchar, @StateID)

	Select @NewFileName=JobControl.dbo.PreBuildTableName(@StepID,@SQLCmd)
	Print 'PreBuildQuery: Prebuild Table Name: ' + @NewFileName

--	Set @NewFileName = Substring(@SQLCmd, CHARINDEX('from', @SQLCmd), (CHARINDEX('--#FromClauseEnd#', @SQLCmd)-2-CHARINDEX('from', @SQLCmd)));
--	Set @NewFileName = 'JobControlWork..pb' + rtrim(ltrim(Substring(@NewFileName, CharIndex('..', @NewFileName)+2,500)));
--	Set @NewFileName = replace(@NewFileName, char(10), '');
--	Set @NewFileName = replace(@NewFileName, char(13), '');
--	Set @NewFileName = rtrim(ltrim(@NewFileName)) + '_' + @StateCode + '_';
--	set @NewFileName = replace(@NewFileName, 'TWG_PropertyData_Rep..', 'JobControlWork..')


	--Declare @IssueMonth varchar(10)='',
	--	@IssueWeek varchar(10)='',
	--	@CalPeriod varchar(10)='',
	--	@CalYear varchar(10)='',
	--	@ParamName varchar(10)='',
	--	@ParamValue varchar(10)=''

	--Declare jpCursor CURSOR for
	--	Select ltrim(rtrim(ParamName)), ParamValue from JobParameters 
	--		where JobID=(Select JobID from JobControl..JobSteps where StepID=@StepID)
	--Open jpCursor;
	--Fetch Next from jpCursor into @ParamName, @ParamValue;
	--While @@Fetch_Status=0
	--Begin
	--	if @ParamName='IssueMonth' and @IssueMonth='' set @IssueMonth=@ParamValue;
	--	if @ParamName='IssueWeek' and @IssueWeek='' set @IssueWeek=@ParamValue;
	--	if @ParamName='CalPeriod' and @CalPeriod='' set @CalPeriod=@ParamValue;
	--	if @ParamName='CalYear' and @CalYear='' set @CalYear=@ParamValue;
	--	Fetch Next from jpCursor into @ParamName, @ParamValue;
	--End
	--Close jpCursor;
	--Deallocate jpCursor;

	--Print 'PreBuildQuery: @IssueMonth: ' + @IssueMonth;
	--Print 'PreBuildQuery: @IssueWeek: ' + @IssueWeek;
	--Print 'PreBuildQuery: @CalPeriod: ' + @CalPeriod;
	--Print 'PreBuildQuery: @CalYear: ' + @CalYear;

	--If @IssueWeek<>''
	--	Begin
	--		Select @NewFileName=@NewFileName+'IW_' + @IssueWeek;
	--	End
	--Else
	--	if @IssueMonth<>''
	--		Begin
	--			Select @NewFileName=@NewFileName+'IM_' + @IssueMonth;
	--		End
	--	else
	--		Begin
	--			Select @NewFileName=@NewFileName+'CP_' + @CalPeriod + @CalYear;
	--		End


		-- If the table exists, Exit Early
		IF OBJECT_ID (@NewFileName, N'U') IS NOT NULL
			RETURN

		-- Create the initial file as temp file
		Declare @TempFileName varchar(100) = 'JobControlWork..temp_' + convert(varchar,@StepID)
		IF OBJECT_ID (@TempFileName, N'U') IS NOT NULL
			exec ('drop table ' +@TempFileName);


		-- Replace --#INTO TABLE# with INTO @NewFileName
		--Set @SQLCmd = Replace(@SQLCmd, '--#INTO TABLE#', 'INTO ' + @NewFileName)
		Set @SQLCmd = Replace(@SQLCmd, '--#INTO TABLE#', 'INTO ' + @TempFileName)

		-- Trim everything after --#TransFilingDateClauseEnd#
		if CHARINDEX('--#TransFilingDateClauseEnd#', @SQLCmd) > 0
			Set @SQLCmd = Substring(@SQLCmd,1,CHARINDEX('--#TransFilingDateClauseEnd#', @SQLCmd)+28)

		-- Trim everything from the location after the [StateID] = 7
		 Set @SQLCmd = substring(@SQLCmd, 1, CHARINDEX('--#LocationClauseStart1#', @SQLCmd) + 25) + 
			'[StateID] = ' + convert(varchar, @StateID) + ' ' +
			substring(@SQLCmd, CHARINDEX('--#LocationClauseEnd1#', @SQLCmd)-1, 1000)
		
		-- Run the new query
		Print 'PreBuildQuery: NEW QUERY: '
		Print @SQLCmd;
		Exec(@SQLCmd);

		IF OBJECT_ID (@TempFileName, N'U') IS NOT NULL
			Begin
				-- Check again to make sure another job didn't build the PreBuild file
				IF OBJECT_ID (@NewFileName, N'U') IS NOT NULL
					Begin
					--Another job built it.  Drop the temp table
					Print 'PreBuildQuery: Dropping ' + @TempFileName + ' because ' + @NewFileName + ' already exists.';
					exec ('Drop Table ' + @TempFileName);
					End
				Else
					Begin
						Declare @TargetName varchar(200);
						Set @TargetName=replace(@NewFileName, 'JobControlWork..','')
						Set @TargetName=replace(@TargetName, 'TWG_PropertyData_Rep..','')

						Print 'PreBuildQuery: Renaming ' + @TempFileName + ' to ' + @TargetName;
						EXEC ('JobControlWork..sp_rename ''' + @TempFileName + ''', ''' + @TargetName + '''')
					End
			End

	RETURN;
END
