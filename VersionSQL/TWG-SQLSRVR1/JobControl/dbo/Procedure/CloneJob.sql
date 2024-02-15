/****** Object:  Procedure [dbo].[CloneJob]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 07-10-2020
-- Description:	Clone a Job and its Job Steps
-- =============================================
CREATE PROCEDURE dbo.CloneJob 
	@OriginalJobID int
	, @resetKeyFields bit
AS
BEGIN
	SET NOCOUNT ON;
	Declare @NewJobID int,
			@CurrentUser varchar(100) = iif(charindex('\',SYSTEM_USER)>0,substring(SYSTEM_USER,charindex('\',SYSTEM_USER)+1,30),SYSTEM_USER);
	--For Testing
	--Select * from Jobs where JobID=@OriginalJobID
	--Select * from JobSteps where JobId=@OriginalJobID

	declare @ProductDefault bit 

	select @ProductDefault = coalesce(ProductDefault,0)
		from JobControl..Jobs 
		WHERE JobID = @OriginalJobID;

	if @OriginalJobID = 0 -- Simple Job
		set @OriginalJobID = 100

	--Clone the Job Record--
	------------------------
	SELECT * INTO #TempCloneJobsTable FROM Jobs WHERE JobID=@OriginalJobID;
	ALTER TABLE #TempCloneJobsTable DROP COLUMN JobID; 
	INSERT INTO Jobs SELECT * FROM #TempCloneJobsTable; 
	Set @NewJobID=@@IDENTITY;
	DROP TABLE #TempCloneJobsTable;

	--Clear out prior run data in the new job and change the job name
	Update Jobs set RunAtStamp=null, StartedStamp=null, CompletedStamp=null, FailedStamp=null, 
		WaitStamp=null, UpdatedStamp=null, LastJobLogID=0, LastJobParameters='', DisabledStamp=null,
		DeletedStamp=null, DeletedBy=null, LastJobRunStartTime=null, LastJobRunElapsedTime='', CreatedStamp=getdate(),
		JobNameAddition = '[Cloned from ' + convert(varchar,@OriginalJobID) +']',
		OrigJobName = '[Cloned from ' + convert(varchar,@OriginalJobID) +'] ' + JobName
		where JobID=@NewJobID;

	update Jobs set JobName = JobControl.dbo.GenAutoJobName(JobID) where JobID=@NewJobID;

	--Clone the JobSteps Records--
	------------------------------
	SELECT * INTO #TempCloneJobStepsTable FROM JobSteps WHERE JobID=@OriginalJobID order by StepOrder;
	ALTER TABLE #TempCloneJobStepsTable DROP COLUMN StepID; 
	Update #TempCloneJobStepsTable set JobID=@NewJobID;
	INSERT INTO JobSteps SELECT * FROM #TempCloneJobStepsTable; 
	DROP TABLE #TempCloneJobStepsTable;

	--Clear out prior run data in the new jobsteps
	Update JobSteps set RunAtStamp=null, StartedStamp=null, CompletedStamp=null, FailedStamp=null, 
		WaitStamp=null, UpdatedStamp=null, CreatedStamp=getdate(), StepRecordCount=null
		Where JobID=@NewJobID;


	--Update the DependsOnStepIDs for the new JobSteps--
	----------------------------------------------------
	Update JobSteps set DependsOnStepIDs=dbo.UpdateDependsOnStepIDs_AfterClone(StepID) where JobID=@NewJobID

	--Set up the Query Steps--
	--------------------------
	Declare @StepID int, @QueryCriteriaID int, @TargetID int=0;
	DECLARE tc CURSOR FOR
		select StepID, QueryCriteriaID from JobSteps where JobID=@NewJobID and StepTypeID in (21, 1124) and QueryCriteriaID > 0;
	OPEN tc
	FETCH NEXT FROM tc into @StepID, @QueryCriteriaID
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		-- This section updated 10/14/2020 - Mark W.
				--Insert into QueryEditor..Queries(CreatedStamp) values(getdate());
				--Set @NewQueryID=@@IDENTITY;
				--Update JobSteps set QueryCriteriaID=@NewQueryID where StepID=@StepID;
				--Exec QueryEditor..OverwriteExistingQuery @QueryCriteriaID, @NewQueryID
				--FETCH NEXT FROM tc into @StepID, @QueryCriteriaID
		
		--Exec QueryEditor..OverwriteExistingQuery @QueryCriteriaID, @TargetID OUTPUT
		
			drop table if exists #newQID
				
			create table #NewQID (NewQueryID int)

			insert Into #NewQID
			Exec QueryEditor..CloneExistingQuery @QueryCriteriaID
		
			select @TargetID = NewQueryID from #NewQID
		
			Update JobSteps set QueryCriteriaID=@TargetID where StepID=@StepID;

		FETCH NEXT FROM tc into @StepID, @QueryCriteriaID
	END
	CLOSE tc
	DEALLOCATE tc


	update ns set QuerySourceStepID = ns2.StepID
		from JobSteps ns
			join jobsteps osq on osq.stepid = ns.QuerySourceStepID and osq.JobID = @OriginalJobID
			join jobsteps ns2 on ns2.StepOrder = osq.StepOrder and ns2.JobID = @NewJobID
		where ns.JobID=@NewJobID and ns.StepTypeID in (21, 1124) 
			and ns.QuerySourceStepID > 0


	IF @resetKeyFields = 0
	BEGIN
		--Clone the Distribution Steps--
		--------------------------------
		Declare @PrevStepID int, @NewStepID int, @DeliveryDestID int;

		--Get all the Distribution StepID's 
		Declare JobStepCursor CURSOR FOR
			Select js.StepID as CurStepID, (Select js2.StepID from JobSteps js2 where js2.JobID=@NewJobID and js2.StepOrder=js.StepOrder) as NewStepID
				from JobSteps js 
				where js.JobID=@OriginalJobID 
					and js.StepTypeID in (1091,1125)
				order by js.StepOrder

		OPEN JobStepCursor
		FETCH NEXT FROM JobStepCursor into @PrevStepID, @NewStepID
		WHILE (@@FETCH_STATUS <> -1)
		BEGIN 
			--Get all the DeliveryDestID's for the Delivery JobSteps 
			Declare DeliveryCursor CURSOR FOR
				select DeliveryDestID 
					from JobControl..DeliveryJobSteps 
					where JobStepID=@PrevStepID 
						and DisabledStamp is null
					order by recid desc
			OPEN DeliveryCursor
			FETCH NEXT FROM DeliveryCursor into @DeliveryDestID
			WHILE (@@FETCH_STATUS <> -1)
			BEGIN
				Insert into JobControl..DeliveryJobSteps(DeliveryDestID, JobStepID, CreatedStamp, CreatedByUser)
					values(@DeliveryDestID, @NewStepID, getdate(), @CurrentUser)
		
				FETCH NEXT FROM DeliveryCursor into @DeliveryDestID	
			END
			CLOSE DeliveryCursor;
			DEALLOCATE DeliveryCursor;

			FETCH NEXT FROM JobStepCursor into @PrevStepID, @NewStepID
		END
		CLOSE JobStepCursor;
		DEALLOCATE JobStepCursor;

		Insert into JobControl..DeliveryJobs(DeliveryDestID, JobID, CreatedStamp, CreatedByUser)
			select DeliveryDestID, @NewJobID, getdate(), @CurrentUser
				from JobControl..DeliveryJobs where JobID = @OriginalJobID 
				and DisabledStamp is null
	END		

	-- Set Query steps with alternate Data sources get the new job steps
	update njs set QuerySourceStepID = njs2.StepID
		from JobControl..JobSteps njs
			join JobControl..JobSteps ojs on ojs.JobID = @OriginalJobID and njs.QuerySourceStepID = ojs.stepID
			join JobControl..JobSteps njs2 on njs2.JobID = @NewJobID and njs2.prevstepID = ojs.stepID

		where njs.JobID = @NewJobID
				and njs.stepTypeID = 1124
				and njs.QuerySourceStepID > 0


	-- Insert a note
	Insert into Notes(JobID, NoteType, Note, LastNoteUpdate, NoteBy)
		values(@NewJobID, 1, 'This job was cloned from job ' + convert(varchar, @OriginalJobID) + '.', 
				getdate(), @CurrentUser)

	-- If there is an extended filter on the source job, add it to the target job.
	-- Added 10/13/2020 - Mark W.
	if exists(Select ExtendedFilterID from ExtendedFiltersJobs where JobID=@OriginalJobID)
		Insert into ExtendedFiltersJobs(ExtendedFilterID, JobID)
		(Select ExtendedFilterID, @NewJobID as JobID
			From ExtendedFiltersJobs 
			where JobID=@OriginalJobID)


	--reset key values
	if @resetKeyFields = 1 
		Begin
			update JobControl..Jobs set TestMode = 1 where JobID = @NewJobID
			update JobControl..Jobs set InProduction = 0 where JobID = @NewJobID
			update JobControl..Jobs set CustID = 0 where JobID = @NewJobID
			update JobControl..Jobs set NoticeOnFailure = 0,  NoticeOnSuccess = 0 where JobID = @NewJobID
		End

	-- Cloan Xforms and Replace
	if @ProductDefault = 1
	begin

		declare @TransformationID int, @XFormStepID int
		declare @NewXFormID int, @NewLayoutID int, @MasterXFormVersion int

		update JobControl..Jobs 
			set ProductDefault = 0 
			where JobID = @NewJobID

		 DECLARE curPDXForm CURSOR FOR
			  select js.TransformationID, js.StepID, tt.MasterVersion
				from JobControl..JobSteps js
					join JobControl..TransformationTemplates tt on tt.Id = js.TransformationID
				where js.JobID = @NewJobID
					and js.TransformationID > 0

		 OPEN curPDXForm

		 FETCH NEXT FROM curPDXForm into @TransformationID, @XFormStepID, @MasterXFormVersion
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

				drop table if exists #newXFID
				
				create table #newXFID (NewXFID int)

				insert Into #newXFID
				Exec JobControl..CloneXForm @TransformationID

				--select @NewXFormID = x.NewXFID
				--		, @NewLayoutID = l.ID
				--	from #newXFID x
				--		join JobControl..FileLayouts l on l.TransformationTemplateId = x.NewXFID

				-- MikeP changed 9/15/23 because if there was more then one Layout the default was not selected
				select top 1 @NewXFormID = x.NewXFID
						, @NewLayoutID = coalesce(ld.ID,la.id)
					from #newXFID x
						left outer join JobControl..FileLayouts ld on ld.TransformationTemplateId = x.NewXFID and ld.DefaultLayout = 1
						left outer join JobControl..FileLayouts la on la.TransformationTemplateId = x.NewXFID
					ORDER BY lD.id, lA.id 


				update JobControl..TransformationTemplates
					set MasterXForm = 0, SourceMasterXFormID = @TransformationID, SourceMasterXFormVersion = @MasterXFormVersion
						, AutoName = JobControl.dbo.AutoXFormLayoutName(ID,null)
					where ID = @NewXFormID

				update JobControl..JobSteps 
					set TransformationID = @NewXFormID
						, FileLayoutID = @NewLayoutID
					where StepID = @XFormStepID

			  FETCH NEXT FROM curPDXForm into @TransformationID, @XFormStepID, @MasterXFormVersion
		 END
		 CLOSE curPDXForm
		 DEALLOCATE curPDXForm

	end



	--For Testing
	--Select * from Jobs where JobID=@NewJobID;
	--Select * from JobSteps where JobID=@NewJobID;
	Select @NewJobID as NewJobID;



END
