/****** Object:  Procedure [dbo].[JC_BeginLoop]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 05-09-2019
-- Description:	Used in Jobs that loop to create reports.
-- =============================================
CREATE PROCEDURE dbo.JC_BeginLoop
	-- Add the parameters for the stored procedure here
	@JobStepId int
AS
BEGIN
	SET NOCOUNT ON;
	Declare @TargetFile varchar(100),
		@SourceFile varchar(100),
		@DependsOnStepIDs varchar(100),
		@SQL varchar(max),
		@SCT varchar(10),
		@dSQL nvarchar(100),
		@SCTId int,
		@JobID int,
		@CurrentID int,
		@FirstLoop int,
		@cRowCnt int,
		@QuerySourceStepName varchar(500);

	-- Update JobSteps for custom status updates in the interface
	Update JobControl..JobSteps 
		set CompletedStamp = null, 
			FailedStamp = null, 
			StartedStamp=getdate() 
		where StepID=@JobStepID;

	-- Get JobId and DependsOnStepIDs

	Select @JobID = js.JobID
		 , @DependsOnStepIDs = js.DependsOnStepIDs
	 	 , @QuerySourceStepName = 'JobControlWork..' + dst.StepName + 'StepResults_J' + ltrim(str(djs.JobID)) + '_S' + ltrim(str(djs.StepID)) 
		 , @SCT=(	CASE
					    WHEN js.BeginLoopType=1 THEN 'State'
					    WHEN js.BeginLoopType=4 THEN 'Registry'
					    WHEN js.BeginLoopType=2 THEN 'County'
					    ELSE 'Town'
					END)
		from JobControl..JobSteps js
			left outer join JobControl..JobSteps djs on djs.StepID = js.DependsOnStepIDs
			left outer join JobStepTypes dst on dst.StepTypeID = djs.StepTypeID
		where js.StepID=@JobStepID;

	-- Get SCT to determine State, County or Town run
	--Select @SCT = st.SCT
	--	from StatsType st
	--		join JobSteps js on js.StatsTypeID=st.StatsTypeID
	--	where js.JobID=@JobID
	--		and js.StepOrder = (Select StepOrder+1 as StepOrder from JobSteps where StepID=@JobStepId)

	set @TargetFile = 'JobControlWork..BeginLoopStepResults_J' + convert(varchar, @JobID) + '_S' + convert(varchar, @JobStepId);
	IF OBJECT_ID(@TargetFile, 'U') IS NULL
		Begin
			-- The table does not exist.  Create it, populate it, and set the ProcessFlag for the first record.
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'
			set @SQL = 'Create Table ' + @TargetFile + '(ID INT IDENTITY NOT NULL, ' + @SCT + 'ID int, ProcessFlag int)';
			exec(@SQL)
			Print @SQL
			--set @SourceFile = 'JobControlWork..QueryStepResults_J' + convert(varchar, @JobID) + '_S' + convert(varchar, @DependsOnStepIDs);
			set @SourceFile = @QuerySourceStepName;
			set @SQL = 'Insert into ' + @TargetFile + 
							' Select distinct ' + @SCT + 'ID, 0 as ProcessFlag from ' + @SourceFile;
			exec(@SQL)
			Print @SQL
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, @TargetFile
			set @FirstLoop=1;
		End
	Else
		set @FirstLoop=0;

	set @SQL = 'update ' + @TargetFile + ' set ProcessFlag=1 ' + 
					'where ID=(Select top 1 ID from ' + @TargetFile + ' where ProcessFlag=0)'
	exec(@SQL)
	print @SQL;

	-- Get the number of rows
	set @dSQL= 'Select @cRowCnt=count(ID) from ' + @TargetFile;
	exec sp_executesql @dSQL, N' @cRowCnt int Output', @cRowCnt output;

	-- Get the Current ID
	set @dSQL= 'Select @CurrentID=ID from ' + @TargetFile + ' where ProcessFlag=1';
	exec sp_executesql @dSQL, N' @CurrentID int Output', @CurrentID output;


	-- Get the current State, County or Town ID
	set @dSQL = 'Select @SCTID=' + @SCT + 'ID from ' + @TargetFile + ' where ProcessFlag=1';
	print @dSQL;
	exec sp_executesql @dSQL, N' @SCTID int Output', @SCTID output;

	-- Add a record to JobStepLog showing what record is being processed
	declare @CountyState varchar(100)=''
	if @SCT='County'
		Begin
			Select @CountyState='    County: ' + rtrim(c.FullName) + ',  State: ' + s.FullName 
				from lookups..counties c 
					join lookups..states s on c.StateID=s.ID
				where c.ID=@SCTID
		END
	Declare @Logtxt varchar(100) = 'Processing ' + @SCT + ' ' + convert(varchar, isnull(@SCTID,0)) + @CountyState
	exec JobControl.dbo.JobControlStepUpdate @JobStepID, @Logtxt;
	Print @CurrentID;

	if @FirstLoop=1
		Begin
			-- Add the record count to JobStepLog and then set the StartedStamp to null so the record goes back to pending.

			--Insert into JobStepLog(JobID, JobStepID, LogStamp, LogInformation, LogInfoType, LogInfoSource)
			--	Values(@JobID,@JobStepID, getdate(), convert(varchar, @cRowCnt), 1, 'StepRecordCount') 
			declare @StringRowCount varchar(20) = convert(varchar(20), @cRowCnt)


			exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @StringRowCount, 'StepRecordCount';

		End

	if @cRowCnt=@CurrentID
		Begin
			-- Last step.  Mark the job as complete
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
			-- Determine if the code below is necessary
			Update JobControl..JobSteps Set CompletedStamp = getdate() where StepID=@JobStepID
		End
	else
		--Update JobControl..JobSteps Set StartedStamp = null where StepID=@JobStepID

		-- Note: This line above was setting StartedStamp = null.  Not quite sure why I was doing that.
		--		 Changed to the line below on 8-12-2020 to accomodate correct zipping of files
		--		 within a loop.  Mark W.
		Update JobControl..JobSteps Set StartedStamp = getdate() where StepID=@JobStepID
END
