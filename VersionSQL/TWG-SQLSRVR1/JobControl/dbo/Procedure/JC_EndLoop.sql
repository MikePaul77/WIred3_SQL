/****** Object:  Procedure [dbo].[JC_EndLoop]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 05-10-2019
-- Description:	Used in Jobs that loop to create reports.
-- =============================================
CREATE PROCEDURE dbo.JC_EndLoop 
	-- Add the parameters for the stored procedure here
	@JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	Declare @BeginLoopStepID int,
		@TargetFile varchar(100),
		@JobID int,
		@cRowCnt int,
		@dSQL nvarchar(100),
		@CurrentID int

	-- Update the Stamps
	Update JobControl..JobSteps set CompletedStamp = null, FailedStamp = null, StartedStamp=getdate() where StepID=@JobStepID;

	-- Get the JobID
	Select @JobID=JobID from JobControl..JobSteps where StepID=@JobStepID;

	--Get the StepID for the Begin Loop
	Select top 1 @BeginLoopStepID=[StepID]
		from JobSteps 
		where JobId=@JobID
			and	StepTypeID=1107
			and StepOrder<(Select StepOrder from JobControl..JobSteps where StepID=@JobStepID)
		order by StepOrder Desc

	exec JobControl..GroupCountProcessLoopDone @BeginLoopStepID, @JobStepID

	--Get the Current Loop ID
	Set @TargetFile = 'JobControlWork..BeginLoopStepResults_J' + convert(varchar, @JobID) + '_S' + convert(varchar, @BeginLoopStepID);
	set @dSQL = 'Select @CurrentID=ID from ' + @TargetFile + ' where ProcessFlag=1'
	exec sp_executesql @dSQL, N' @CurrentID int Output', @CurrentID output;
	If isnull(@CurrentID,0)=1
		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start';

	--Get the number of records in the loop
	set @dSQL = 'Select @cRowCnt=count(ID) from ' + @TargetFile
	exec sp_executesql @dSQL, N' @cRowCnt int Output', @cRowCnt output;

	-- Update the Loop file.  Update the running record to set it as done.
	exec('Update ' + @TargetFile + ' set ProcessFlag=2 where ProcessFlag=1');

	-- Update the StepRecordCount
	If @CurrentID=1
		--Insert into JobStepLog(JobID, JobStepID, LogStamp, LogInformation, LogInfoType, LogInfoSource)
		--			Values(@JobID,@JobStepID, getdate(), '1', 1, 'StepRecordCount') 
		exec JobControl.dbo.JobStepLogInsert @jobstepID, '1', 1, 'StepRecordCount'
	else
	begin
		Update JobControl..JobStepLog set LogInformation=convert(varchar, @CurrentID) 
			where JobStepID=@JobStepID and LogInfoSource='StepRecordCount'
		update JobControl..JobSteps set StepRecordCount = @CurrentID where StepID = @jobstepID
	end

	-- Check if there are any more records to be processed.
	exec('Select ID from ' + @TargetFile + ' where ProcessFlag=0')
	if @@Rowcount > 0
		-- There are records to be processed, loop back to the begin step by failing the job
		Begin
			Print 'Jumping to Beginning Loop'
			Update JobControl..JobSteps set CompletedStamp = getdate(), FailedStamp = null, StartedStamp=null where StepID=@JobStepID;
			RAISERROR ('Loop complete.', 16,1);
		End
	else
		Begin
			--No more records to be processed, delete the table and continue to next step
			exec('IF OBJECT_ID(''' + @TargetFile + ''', ''U'') IS not NULL drop TABLE ' + @TargetFile + ' ');
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
		End
	
END
