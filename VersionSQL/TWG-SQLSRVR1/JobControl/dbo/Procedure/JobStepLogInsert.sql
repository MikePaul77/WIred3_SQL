/****** Object:  Procedure [dbo].[JobStepLogInsert]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JobStepLogInsert(@JobStepID int, @InfoType int, @LogInformation varchar(max), @LogInfoSource varchar(100))
AS
BEGIN
	SET NOCOUNT ON;

	--if @LogInfoSource in ('StepRecordCount', 'StepErrorCount', 'StepFileCount') and @InfoType = 1
	--begin
	--	delete JobStepLog 
	--		where JobStepID = @JobStepID 
	--			and LogInfoSource = @LogInfoSource 
	--			and LogInfoType = @InfoType
	--end

	declare @SCTval int = 0

	declare @InLoop bit 
	declare @JobID int
	declare @StepOrder int

	select @JobID = js.JobID
			, @StepOrder=js.StepOrder
			, @InLoop = JobControl.dbo.InLoop(js.StepID)
		from JobControl..JobSteps js 
		where js.StepID = @JobStepID;

	if @InLoop = 1
	begin

		declare @StartLoopStepID int

		Declare @SCT varchar(10)
		Select top 1 @SCT = (	CASE WHEN BeginLoopType=1 THEN 'State'
								WHEN BeginLoopType=2 THEN 'County'
								WHEN BeginLoopType=4 THEN 'Registry'
								ELSE 'Town' END)
				, @StartLoopStepID = StepID
			from JobControl..JobSteps 
			where JobID = @JobID
				and coalesce(Disabled,0) = 0
				and StepOrder < @StepOrder
				and StepTypeID = 1107
				order by StepOrder desc; 

		if isnull(@SCT,'')<>''
			Begin

				Declare @LoopTable varchar(100), @Q1 nvarchar(max)
				set @LoopTable = 'JobControlWork..BeginLoopStepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@StartLoopStepID));

				if OBJECT_ID(@LoopTable, 'U') is not null
					Begin
						set @Q1='Select count(*) LoopCount from ' + @LoopTable + ' where ProcessFlag > 0'
						--Execute sp_executesql @Q1, N'@SCTval int OUTPUT', @SCTval = @SCTval output;

						drop Table if exists #LoopCount
						create table #LoopCount (LoopCount int)

						insert into #LoopCount exec(@Q1)

						select @SCTval = LoopCount from #LoopCount

					end
			end
	end

	if (@LogInfoSource = 'StepRecordCount')
		Update JobControl..JobSteps set StepRecordCount = TRY_CONVERT(int,@LogInformation) where StepID = @JobStepID;

	insert JobStepLog (JobId, JobStepID, LogStamp, LogInformation, LogInfoType, LogInfoSource, JobLogID, LoopCount )
		select js.JobID, @JobStepID, getdate(), @LogInformation, @InfoType, @LogInfoSource, j.LastJobLogID, @SCTval
			from JobSteps js
				join Jobs j on j.JobID = js.JobID
			where js.StepID = @JobStepID

	insert JobStepLogHist (JobId, JobStepID, LogStamp, LogInformation, LogInfoType, LogInfoSource, JobLogID, LoopCount )
		select js.JobID, @JobStepID, getdate(), @LogInformation, @InfoType, @LogInfoSource, j.LastJobLogID, @SCTval
			from JobSteps js
				join Jobs j on j.JobID = js.JobID
			where js.StepID = @JobStepID

END
