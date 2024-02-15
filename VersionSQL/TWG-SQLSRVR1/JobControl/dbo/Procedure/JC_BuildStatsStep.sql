/****** Object:  Procedure [dbo].[JC_BuildStatsStep]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 5/3/2019
-- Description:	Builds the STATS data files
-- =============================================
CREATE PROCEDURE dbo.JC_BuildStatsStep 
	@JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	Print 'JC_BuildStatsStep running for JobStepID ' + convert(varchar, @JobStepID);

	Declare @JobID int,
		@StatsTypeID int,
		@TargetFile varchar(100),
		@SourceFile varchar(100),
		@DependsOnStepIDs varchar(100),
		@ErrorMessage varchar(200),
		@dSQL nvarchar(100),
		@SQL varchar(max),
		@txt varchar(max),
		@CountyID int,
		@InLoop int = 0


	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

	Select @JobID=JobID, @StatsTypeID=StatsTypeID, @DependsOnStepIDs=DependsOnStepIDs 
		from JobControl..JobSteps 
		where StepID=@JobStepID;

	-- Determine if this step is inside of a loop
	Declare @PrevStepName varchar(50), @PrevStepID int;
	Select @PrevStepID=StepID, @PrevStepName=StepName 
		from JobSteps where JobID=@JobID and StepOrder = (Select (StepOrder-1) from JobSteps where StepID=@JobStepID)
	if @PrevStepName='Begin Loop' set @InLoop=1;

	if isnull(@DependsOnStepIDs,'')='' or CHARINDEX(',', @DependsOnStepIDs)>0
		Begin
			print 'Aborting because the DependsOnStepID is invalid.';
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, 'Invalid DependsOnStepID.', 'JC_BuildStatsStep';
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
			RETURN
		End
	Else
		if @InLoop=0
			Begin
				Set @SourceFile = 'JobControlWork..QueryStepResults_J' + convert(varchar, @JobID) + '_S' + convert(varchar, @DependsOnStepIDs);
				IF OBJECT_ID(@SourceFile, 'U') IS NULL
				Begin
					print 'Aborting because the source file ' + @SourceFile + ' does not exist.';
					set @ErrorMessage = 'Source File ' + @SourceFile + ' does not exist.';
					exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @ErrorMessage, 'JC_BuildStatsStep';
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
					RETURN
				End
			End
		else
			Begin
				Set @SourceFile = 'JobControlWork..BeginLoopStepResults_J' + convert(varchar, @JobID) + '_S' + convert(varchar, @PrevStepID);
				IF OBJECT_ID(@SourceFile, 'U') IS NULL
				Begin
					print 'Aborting because the source file ' + @SourceFile + ' does not exist.';
					set @ErrorMessage = 'Source File ' + @SourceFile + ' does not exist.';
					exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @ErrorMessage, 'JC_BuildStatsStep';
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
					RETURN
				End
			End

	Set @TargetFile = 'JobControlWork..StatsStepResults_J' + convert(varchar, @JobID) + '_S' + convert(varchar, @JobStepID);
	set @SQL = 'IF OBJECT_ID(''' + @TargetFile + ''', ''U'') IS not NULL drop TABLE ' + @TargetFile + ' ';
	exec(@SQL);
	Print 'Source File: ' + @SourceFile;
	Print 'Target File: ' + @TargetFile;

	If @StatsTypeID=1 -- Build Trendlines Report Datafile
		Begin
			print 'Starting TrendlineData Section'
			-- Get the CountyID from the Query Step Results
			if @InLoop=1
				set @dSQL = 'Select @CountyID=CountyID from ' + @SourceFile + ' where ProcessFlag=1';
			else
				set @dSQL = 'Select distinct @CountyID=CountyID from ' + @SourceFile
			exec sp_executesql @dSQL, N' @CountyID int Output', @CountyID output;
			if @@Rowcount=0
				Begin
					set @ErrorMessage = 'Aborting because no CountyID''s found in ' + @SourceFile + '.';
					print @ErrorMessage
					exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @ErrorMessage, 'JC_BuildStatsStep';
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
					RETURN;
				End
			else
				if @@Rowcount>1
					Begin
						set @ErrorMessage = 'Aborting because more than 1 CountyID''s found in ' + @SourceFile + '.';
						print @ErrorMessage
						exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @ErrorMessage, 'JC_BuildStatsStep';
						exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
						RETURN;
					End
			
			-- Get the last month and year for the report
			Declare @CalPeriod varchar(4), @CalYear varchar(4), @ReportMonth int, @ReportYear int
			Select @CalPeriod=ParamValue from JobParameters where JobID=@JobID and ParamName='CalPeriod'
			if @CalPeriod>='01' and @CalPeriod<='12'
				Set @ReportMonth=convert(int,@CalPeriod)
			else
				Begin
					set @ErrorMessage = 'Aborting because of an incorrect date parameter. (CalPeriod=' + @CalPeriod + ')'
					print @ErrorMessage
					exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @ErrorMessage, 'JC_BuildStatsStep';
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
					RETURN;
				End

			Select @ReportYear=convert(int,ParamValue) from JobParameters where JobID=@JobID and ParamName='CalYear'
			set @txt = 'Executing JC_GetTrendlineData ' + convert(varchar, @JobStepID) + ', ' + convert(varchar, @CountyID) + ', ' +
					convert(varchar, @ReportMonth) + ', ' + convert(varchar, @ReportYear)
			Print @txt;
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, @txt
			exec JC_GetTrendlineData @JobStepID, @CountyID, @ReportMonth, @ReportYear
			Print 'JC_BuildStatsStep complete!';

			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
			Return;
		End



	--If @StatsTypeID=1 -- Build Trendlines Report Datafile
	--	Begin
	--		print 'Starting TrendlineData Section'
		
	--		-- Get the CountyID from the Query Step Results
	--		set @dSQL = 'Select distinct @CountyID=CountyID from ' + @SourceFile
	--		exec sp_executesql @dSQL, N' @CountyID int Output', @CountyID output;
	--		if @@Rowcount=0
	--			Begin
	--				set @ErrorMessage = 'Aborting because no CountyID''s found in ' + @SourceFile + '.';
	--				print @ErrorMessage
	--				exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @ErrorMessage, 'JC_BuildStatsStep';
	--				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
	--				RETURN;
	--			End
	--		else
	--			if @@Rowcount>1
	--				Begin
	--					set @ErrorMessage = 'Aborting because more than 1 CountyID''s found in ' + @SourceFile + '.';
	--					print @ErrorMessage
	--					exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @ErrorMessage, 'JC_BuildStatsStep';
	--					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
	--					RETURN;
	--				End

	--		-- Get the last month and year for the report
	--		Declare @CalPeriod varchar(4), @CalYear varchar(4), @ReportMonth int, @ReportYear int
	--		Select @CalPeriod=ParamValue from JobParameters where JobID=@JobID and ParamName='CalPeriod'
	--		if @CalPeriod>='01' and @CalPeriod<='12'
	--			Set @ReportMonth=convert(int,@CalPeriod)
	--		else
	--			Begin
	--				set @ErrorMessage = 'Aborting because of an incorrect date parameter. (CalPeriod=' + @CalPeriod + ')'
	--				print @ErrorMessage
	--				exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @ErrorMessage, 'JC_BuildStatsStep';
	--				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
	--				RETURN;
	--			End

	--		Select @ReportYear=convert(int,ParamValue) from JobParameters where JobID=@JobID and ParamName='CalYear'
	--		Print 'Executing JC_GetTrendlineData ' + convert(varchar, @JobStepID) + ', ' + convert(varchar, @CountyID) + ', ' +
	--				convert(varchar, @ReportMonth) + ', ' + convert(varchar, @ReportYear)
	--		exec JC_GetTrendlineData @JobStepID, @CountyID, @ReportMonth, @ReportYear
	--		Print 'JC_BuildStatsStep complete!';

	--		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
	--		Return;
	--	End

	--if @StatsTypeID=2 or @StatsTypeID=3
	--	Begin
	--		-- Get the CountyID from the Query Step Results
	--		set @dSQL = 'Select distinct @CountyID=CountyID from ' + @SourceFile
	--		exec sp_executesql @dSQL, N' @CountyID int Output', @CountyID output;
	--		if @@Rowcount=0
	--			Begin
	--				set @ErrorMessage = 'Aborting because no CountyID''s found in ' + @SourceFile + '.';
	--				print @ErrorMessage
	--				exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @ErrorMessage, 'JC_BuildStatsStep';
	--				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
	--				RETURN;
	--			End
	--		else
	--			if @@Rowcount>1
	--				Begin
	--					set @ErrorMessage = 'Aborting because more than 1 CountyID''s found in ' + @SourceFile + '.';
	--					print @ErrorMessage
	--					exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @ErrorMessage, 'JC_BuildStatsStep';
	--					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
	--					RETURN;
	--				End

	--		Select @ReportYear=convert(int,ParamValue) from JobParameters where JobID=@JobID and ParamName='CalYear'
	--		Print 'Executing JC_GetFiveYearData ' + convert(varchar, @ReportYear) + ', ' + convert(varchar, @CountyID)
	--			+ convert(varchar, @JobStepID); 
	--		Exec JC_GetFiveYearData @ReportYear, @CountyID, @JobStepID

	--		Print 'JC_GetFiveYearData complete!';
	--		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
	--		Return;
	--	End

END
