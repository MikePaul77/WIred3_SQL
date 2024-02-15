/****** Object:  Procedure [dbo].[MergeJobs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.MergeJobs
@JobIDs varchar(200)
AS
BEGIN

	SET NOCOUNT ON;


	insert into JobControl..Jobs(CreatedStamp, JobTemplateID, JobName, disabled, SQLJobID, RecurringTypeID, CategoryID, ModeID, PromptState, PromptIssueWeek, 
                         JobStateID, JobIssueWeek, ProcessTypeID, VFPIn, VFPState, VFPCCode, VFPJobID, CustID, xDescription, UpdatedStamp, IsTemplate, Type, PromptIssueMonth, PromptCalYear, PromptCalPeriod, AuditBeforeDistribution, 
                         LastJobLogID, LastJobParameters, BypassDocumentLibrary, DisabledStamp, TestMode, JobStateReference, JobNotes, Deleted, DeletedStamp, DeletedBy, InProduction, InEditModeStamp, InEditModeUser, 
                         NoticeOnFailure, NoticeOnSuccess, TestModeEmail, RecurringTargetID, RecurringOffset)

	select GETDATE(), JobTemplateID, 'Merged Jobs('+ @JobIDs+')', disabled,  SQLJobID,  RecurringTypeID, CategoryID, ModeID, PromptState, PromptIssueWeek, 
                         JobStateID, JobIssueWeek, ProcessTypeID, VFPIn, VFPState, VFPCCode, VFPJobID, CustID, xDescription, GETDATE(), IsTemplate, Type, PromptIssueMonth, PromptCalYear, PromptCalPeriod, AuditBeforeDistribution, 
                         LastJobLogID, LastJobParameters, BypassDocumentLibrary, DisabledStamp, TestMode, JobStateReference, JobNotes, Deleted, DeletedStamp, DeletedBy, InProduction, InEditModeStamp, InEditModeUser, 
                          NoticeOnFailure, NoticeOnSuccess,TestModeEmail, RecurringTargetID, RecurringOffset
						 from JobControl..Jobs
						 --where Jobid = (Select min(value) minID from string_split(@JobIDs, ','))
						 where  @JobIDs like LTRIM(str(JobID)) + ',%'
	declare @newJobID int = (select MAX(JobID) from JobControl..Jobs)

	insert JobControl..JobSteps(JobID, StepName, StepOrder, StepTypeID, SQLJobStepID,  RunModeID, RequiresSetup, QueryCriteriaID, ReportListID, TransformationID, 
                         FileLayoutID, SpecialID, DependsOnStep_DoNOTUSE, StepFileNameAlgorithm, FileSourcePath, FileSourceExt, AllowMultipleFiles, StepSubProcessID, QueryTemplateID,  VFPIn, VFP_QueryID, 
                         VFP_BTCRITID, VFP_LayoutID, VFP_ReportID, DependsOnStepIDs, UpdatedStamp, CreatedStamp, DeliveryTypeID_DoNotUse, SendDeliveryConfirmationEmail, SendToTWGExtranet, VFP_CALLPROC, CreateZeroRecordReport, 
                         OrigStepFileNameAlgorithm, PrebuildQuery, SharableReport, StatsTypeID, EmailTemplateID, RunSP_Procedure, 
                         RunSP_Params, RunSP_ToStepTable, BeginLoopType, QuerySourceStepID, XFormLogMode, Disabled, EmailNotificationSubject, EmailNotificationMessage, QueryPreview, AltDataStepID, CopyToDestTargetTableName, 
                         ZipFileDirectly, DeleteBeforeAppend, RawDataSourceTable, AuditID, DeliveryModeID, CopyFilePath, MakeDatedSubDir, CustomName, UnSavedTempStep, LayoutFormattingMode, IgnoreDataTruncation, PrevStepID)

							select @newJobID, StepName, 
							ROW_NUMBER() OVER (ORDER BY JobID, StepOrder) StepOrder
							,StepTypeID, SQLJobStepID,  RunModeID, RequiresSetup, QueryCriteriaID, ReportListID, TransformationID, 
                         FileLayoutID, SpecialID, DependsOnStep_DoNOTUSE, StepFileNameAlgorithm, FileSourcePath, FileSourceExt, AllowMultipleFiles, StepSubProcessID, QueryTemplateID,  VFPIn, VFP_QueryID, 
                         VFP_BTCRITID, VFP_LayoutID, VFP_ReportID, DependsOnStepIDs, UpdatedStamp, CreatedStamp, DeliveryTypeID_DoNotUse, SendDeliveryConfirmationEmail, SendToTWGExtranet, VFP_CALLPROC, CreateZeroRecordReport, 
                         OrigStepFileNameAlgorithm, PrebuildQuery, SharableReport, StatsTypeID, EmailTemplateID, RunSP_Procedure, 
                         RunSP_Params, RunSP_ToStepTable, BeginLoopType, QuerySourceStepID, XFormLogMode, Disabled, EmailNotificationSubject, EmailNotificationMessage, QueryPreview, AltDataStepID, CopyToDestTargetTableName, 
                         ZipFileDirectly, DeleteBeforeAppend, RawDataSourceTable, AuditID, DeliveryModeID, CopyFilePath, MakeDatedSubDir, CustomName, UnSavedTempStep, LayoutFormattingMode, IgnoreDataTruncation, stepID
							 from JobControl..JobSteps 
							where  ',' + @jobids + ',' like '%,'+ LTRim(str(jobid)) + ',%'

							--updates dependent stepids

							declare @DepIDS varchar(500), @newDepID varchar(500), @oldStepID int, @newStepID int, @sep varchar(5), @useStepID int      
	DECLARE curA CURSOR FOR          
		select DependsOnStepIDs, StepID from JobSteps
			where jobid = @newJobID and DependsOnStepIDs > ''
				OPEN curA
					FETCH NEXT FROM curA into @DepIDS, @usestepID
					WHILE (@@FETCH_STATUS <> -1)    
					BEGIN

					set @newDepID = ''
					set @sep= ''


								DECLARE curB CURSOR FOR          


									select njs.stepid newstepid, ojs.stepid oldstepid
									from JobSteps njs
									join JobSteps ojs on ojs.StepID = njs.prevStepID
									where njs.JobID = @newJobID and ',' + @DepIDS+ ',' like '%,' + LTRIM(str( ojs.StepId)) + ',%'
								OPEN curB
								FETCH NEXT FROM curB into @newStepID, @oldstepID
								WHILE (@@FETCH_STATUS <> -1)    
								BEGIN


								set @newDepID = @newDepID + @sep+ LTRIM(str(@newstepID))

								set @sep = ','
								FETCH NEXT FROM curB into @newStepID, @oldstepID
								END    
							CLOSE curB    
					DEALLOCATE curB

					update jobsteps set DependsOnStepIDs = @newDepID
					where StepID = @useStepID

					-- clone querys to new query steps
										declare @OldQStepID int, @NewQStepID int, @OldQueryID int, @newQueryID int
										DECLARE CurC CURSOR FOR

										select njs.StepID, ojs.StepID, ojs.QueryCriteriaID from jobsteps njs
										join JobSteps ojs on njs.prevstepid = ojs.StepID
										where njs.JobID = @newJobID and njs.StepTypeID in (1124, 21)

										OPEN CurC
										FETCH NEXT FROM CurC into @NewQStepID, @OldQStepID, @OldQueryID
										WHILE (@@FETCH_STATUS <> -1)
										BEGIN

										drop table if exists #NewID
										create table #newID (ID int)

										insert into #newID
										exec QueryEditor..cloneExistingQuery @oldQueryID

										select @newQueryID = ID from #newID

										update JobControl..JobSteps
										set QueryCriteriaID = @newQueryID
										where StepID = @NewQStepID

										FETCH NEXT FROM CurC into @newstepid, @oldstepid, @OldQueryID		
									END
								CLOSE CurC
							DEALLOCATE CurC



					FETCH NEXT FROM curA into @DepIDS, @usestepID
					END    
				CLOSE curA    
		DEALLOCATE curA

		

				insert DeliveryJobSteps (DeliveryDestID, JobStepID, CreatedStamp, CreatedByUser, CreatedNote)
				select djs.DeliveryDestID, njs.StepID, GETDATE(), djs.CreatedByUser, 'Merged Jobs ' + @JobIDs 
				from JobSteps njs
				join JobSteps ojs on ojs.StepID = njs.prevStepID
				join DeliveryJobSteps djs on djs.JobStepID = ojs.StepID and DisabledStamp is null
				where njs.JobID = @newJobID and ',' + @jobIds+ ',' like '%,' + LTRIM(str( ojs.JobID)) + ',%' and ojs.StepTypeID in (1091, 1115) 

				insert DeliveryJobs (DeliveryDestID, JobID, CreatedStamp, CreatedByUser, CreatedNote)
				select DeliveryDestID, @newJobID, GETDATE(), CreatedByUser, 'Merged Jobs ' + @JobIDs 
				from JobControl..DeliveryJobs
				where  @JobIDs like LTRIM(str(JobID)) + ',%' and DisabledStamp is null

				insert JobControl..ExtendedFiltersJobs(ExtendedFilterID, JobID)
				select ExtendedFilterID, @newJobID from JobControl..ExtendedFiltersJobs
				where @JobIDs like LTRIM(str(JobID)) + ',%'



		Select @newJobID NewJobID


END
