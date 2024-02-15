/****** Object:  Procedure [dbo].[JobControlStepUpdate]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JobControlStepUpdate @JobStepID int, @Action varchar(100)
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;


	declare @JobID int = 0;
	declare @StepOrder int = 1;
	declare @logtype int;	--	1 Info, 2 Caution, 3 Error
	declare @StepActionType varchar(200), @StepActionCommand varchar(max), @RunModeID int, @CompletedStamp datetime;
	declare @StepDisabled bit
	declare @IsJobFirstStep bit

	select @StepActionType = case when jst.StepActionType = 'SP' then 'SP ' + @Action
								when jst.StepActionType = 'SSIS' then 'SSIS Package ' + @Action
								when jst.StepActionType = 'OSCmd' then 'OS Command ' + @Action
								else 'Other ' + @Action end
			, @StepActionCommand = jst.StepActionCommand + ' : [JobControlStepUpdate]'
			, @JobID = js.JobID
			, @StepOrder = js.StepOrder
			, @RunModeID = js.RunModeID
			, @CompletedStamp = js.CompletedStamp
			, @StepDisabled = coalesce(js.Disabled,0)
			, @IsJobFirstStep = JobControl.dbo.IsFirstStep(@JobStepID)
		from JobSteps js
			join JobStepTypes jst on jst.StepTypeID = js.StepTypeID
		where js.StepID = @JobStepID;

	if @StepDisabled = 1
	begin
		set @StepActionType = 'Disabled so skipped: ' + @StepActionType
	end

	if @Action = 'Start'
	begin
		--MP 6/3/2020 These 3 lines have been moved to SP CleanUpPreviousJobRunRemnants that is called from SP RebuildSQLAgentJob becuse that happens at the start of each job
		--delete JobControl..JobParameters where StepID = @JobStepID
		--delete JobControl..JobInfo where StepID = @JobStepID
		--delete JobControl..JobStepLog where JobStepID = @JobStepID

		if @IsJobFirstStep = 1
		Begin
			print 'Cleanup Previous Job data'

			exec JobControl..CleanUpPreviousJobRunRemnants2 @JobID

			declare @RunServer varchar(50)

			select @RunServer = coalesce(jrs.SQLName,jcs.SQLName,@@Servername)
				from JobControl..Jobs j
					join WiredJobControlRun..Servers jcs on jcs.SQLName = @@Servername
					left outer join WiredJobControlRun..Servers jrs on jrs.ID = J.RunSrvrID
				where J.JobID = @JobID

			declare @SQLCmd varchar(Max)

			set @SQLCmd = '[' + @RunServer + '].WiredJobControlRun.dbo.CleanUpPreviousJobRunRemnantsByJobID ' + ltrim(str(@JobID))
			print @SQLCmd
			exec(@SQLCmd)

		End

		update js set StartedStamp = getdate()
					, RunAtStamp = case when js.RunAtStamp is null then getdate() else js.RunAtStamp end
					, FailedStamp = null
					, CompletedStamp = null  
			from JobSteps js 
				join Jobs j on j.JobID = js.JobID
			where js.StepID = @JobStepID;

		update jobs set StartedStamp = getdate() where JobID = @JobID

		set @logtype = 1;
	end
	if @Action = 'Complete' or @Action = 'End'
	begin

		update js set CompletedStamp = getdate()
					, WaitStamp = null
					, FailedStamp = null  -- added by Mark W. 6/26/2018
			from JobSteps js 
				join Jobs j on j.JobID = js.JobID
			where js.StepID = @JobStepID;

		set @logtype = 1;
	end
	if @Action = 'Fail'
	begin


		update js set FailedStamp = getdate()
					, WaitStamp = null
			from JobSteps js 
				join Jobs j on j.JobID = js.JobID
			where js.StepID = @JobStepID;

		update JobSteps set RunAtStamp = null, WaitStamp = null
			where JobID = @JobID
				and StepOrder > @StepOrder
				and RunAtStamp is not null
				and StartedStamp is null
				and CompletedStamp is null
				and FailedStamp is null

		update jobs set FailedStamp = getdate() where JobID = @JobID

		--exec JobControl..FailQueuedDependentJobs @JobID

		set @logtype = 3;
	end

	exec JobControl.dbo.JobStepLogInsert @JobStepID, @logtype, @StepActionType, @StepActionCommand;


	-- Set WaitStamp of next Manual Step
	update js set WaitStamp = case when jss.NextStep = jss.NextManualStep 
										and jss.RunningSteps = 0
										and jss.FailedSteps = 0
										and jss.PendingSteps > 0
										and jss.ManualSteps > 0 then getdate() else null end
		from JobSteps js
			join (
				select js.JobID
						, count(*) steps
						, sum(case when js.RunModeID = 3 then 1 else 0 end) ManualSteps
						, sum(case when js.CompletedStamp is not null then 1 else 0 end) CompletedSteps
						, sum(case when js.FailedStamp is not null then 1 else 0 end) FailedSteps
						, sum(case when js.StartedStamp is not null and js.CompletedStamp is null then 1 else 0 end) RunningSteps
						, sum(case when js.StartedStamp is null then 1 else 0 end) PendingSteps
						, min(case when js.CompletedStamp is null and js.FailedStamp is null then StepOrder else null end) NextStep
						, min(case when js.RunModeID = 3 and js.CompletedStamp is null then StepOrder else null end) NextManualStep
					from JobSteps js
					where js.JobID = @JobID
					group by  js.JobID
				) jss on jss.JobID = js.JobID and jss.NextManualStep = js.StepOrder;

	Declare @JobHasFinishedLastStep bit = 0
	Declare @JobWasFullRun bit = 0
	Declare @FailedSteps int = 0
	Declare @FailedStampMostRecent bit = 0
	Declare @ContinutedAfterFail bit = 0
	

	select @JobHasFinishedLastStep = JobHasFinishedLastStep
			, @FailedSteps = FailedJobSteps
			, @JobWasFullRun = LastRunFullJob
			, @FailedStampMostRecent = FailedStampMostRecent
			, @ContinutedAfterFail = ContinutedAfterFail
		from JobControl..vJobRunStatus
		where JobID = @JobID

--insert SandBox..StatusWatch
--select getdate(), @JobStepID, *
--	from vJobRunStatus
--	where JobID = @JobID

-- MP Commented out 1/14/2020 added single Comp, failed Hold updates


--	-- Updates Job Stamps based on Step Stamps of changed jobs
--	update j set StartedStamp = jss.FirstStartedStamp
----				, CompletedStamp = case when jss.FailedJobSteps = 0 and (jss.JobSteps - jss.DisabledSteps) = (jss.CompletedJobSteps - jss.DisabledSteps) then jss.LastCompletedStamp else null end
--				, CompletedStamp = case when jss.FailedJobSteps = 0 and (jss.JobSteps - jss.DisabledSteps) = jss.CompletedJobSteps then jss.LastCompletedStamp else null end
--				, WaitStamp = AnyWaitStamp
--				, FailedStamp = case when jss.FailedJobSteps > 0 then jss.FirstFailedStamp else null end
--			from jobs j
--				join (select JobID
--							, min(RunAtStamp) FirstRunAtStamp
--							, min(StartedStamp) FirstStartedStamp
--							, min(FailedStamp) FirstFailedStamp
--							, max(CompletedStamp) LastCompletedStamp
--							, max(WaitStamp) AnyWaitStamp
--							, count(*) JobSteps
--							, sum(case when js.Disabled = 1 then 1 else 0 end) DisabledSteps
--							, count(CompletedStamp) CompletedJobSteps 
--							, count(FailedStamp) FailedJobSteps   
--						from JobSteps js
--							where js.JobID = @JobID
--						group by JobID
--					) jss on jss.JobID = j.JobID
--			where coalesce(j.disabled,0) = 0
--				and jss.FirstRunAtStamp is not null;

print '-----------------------------'
print @JobHasFinishedLastStep
print @JobWasFullRun
print '-----------------------------'

	declare @SendNotice bit
	declare @SrvrName nvarchar(100) = @@ServerName

	--declare @x int
	--set @x = case when @FailedStampMostRecentStamp = 1 then 1 else 0 end

	--insert SandBox..StatusWatch (Stamp, StepID, JobID) 
	--		values(getdate(),@FailedSteps,coalesce(@x,-1))


	if @FailedSteps > 0 and @FailedStampMostRecent = 1 and @ContinutedAfterFail = 0
	Begin
			--insert SandBox..StatusWatch (Stamp, StepID) values(getdate(),-99)

			select @SendNotice = case when (coalesce(j.NoticeOnFailure,1) = 1) and coalesce(d.DDs,0) > 0 then 1 else 0 end
				from JobControl..Jobs j
					left outer join (select count(*) DDs, JobID 
											from JobControl..DeliveryJobs dj
												left outer join JobControl..DeliveryDests dd on dd.ID = dj.DeliveryDestID and dd.DisabledStamp is null
												where dj.DisabledStamp is null group by dj.JobID) d on d.JobID = j.JobID
				where j.JobID = @JobID

	--declare @y int
	--set @y = case when @SendNotice = 1 then 1 else 0 end

	--insert SandBox..StatusWatch (Stamp, StepID, JobID) 
	--		values(getdate(),-88,coalesce(@y,-1))


		if @SendNotice = 1
		Begin
			--exec JobControl..SendJobNotification @SrvrName, @JobID
			insert JobControl..JobNotifications (CreatedStamp, JobID)
				values (getdate(),@JobID)
		end
	end

	if @JobHasFinishedLastStep = 1 and @JobWasFullRun = 1 and @FailedSteps = 0
	Begin

	Begin Try
		update JobControl..Jobs
			set @CompletedStamp = getdate() 
			where JobID = @JobID
	
		Declare @EndJob bit = 0
		declare @FianalParam varchar(50) = ''
		select @EndJob = case when InProduction = 1 
					and CurrParamTarget = FinalParamTarget 
					and coalesce(FinalParamTarget,'') > '' 
					then 1 else 0 end
				, @FianalParam = FinalParamTarget
			from JobControl..Jobs j
			where j.JobID = @JobID
		if @EndJob = 1
		begin
			update JobControl..Jobs
				set InProduction = 0
			where JobID = @JobID

			insert JobControl..Notes (JobID, Note, NoteType, LastNoteUpdate)
				values (@JobID, 'Job removed from production because FinalParam reached ' + @FianalParam,1, getdate())
		
		end

		select @SendNotice = case when (coalesce(j.NoticeOnFailure,1) = 1) and coalesce(d.DDs,0) > 0 then 1 else 0 end
				from JobControl..Jobs j
					left outer join (select count(*) DDs, JobID 
											from JobControl..DeliveryJobs dj
												left outer join JobControl..DeliveryDests dd on dd.ID = dj.DeliveryDestID and dd.DisabledStamp is null
												where dj.DisabledStamp is null group by dj.JobID) d on d.JobID = j.JobID
				where j.JobID = @JobID

		if @SendNotice = 1
		Begin
			--exec JobControl..SendJobNotification @SrvrName, @JobID
			insert JobControl..JobNotifications (CreatedStamp, JobID)
				values (getdate(),@JobID)

		end

	end Try

	begin catch

		DECLARE @ErrorMessage NVARCHAR(4000);  
		DECLARE @ErrorSeverity INT;  
		DECLARE @ErrorState INT;  
		DECLARE @ErrorNumber INT;  
		DECLARE @ErrorLine INT;  

		SELECT   
			@ErrorMessage = ERROR_MESSAGE(),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorNumber = ERROR_NUMBER(),  
			@ErrorLine = ERROR_LINE(),  
			@ErrorState = ERROR_STATE();  

		declare @logEntry varchar(500)

		set @logEntry ='Error Number ' + cast(@ErrorNumber AS nvarchar(50))+ ', ' +
                         'Error Line '   + cast(@ErrorLine AS nvarchar(50)) + ', ' +
                         'Error Message : ''' + @ErrorMessage + ''''

		print @logEntry

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, 'JobControl..SendJobNotification'

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

		RAISERROR (@ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  


	end catch

	end
		


END
