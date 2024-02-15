/****** Object:  Procedure [dbo].[AddTemplateStepsToJob]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AddTemplateStepsToJob @TemplateJobID int, @AddToJobID int  

AS
BEGIN
insert JobControl..JobSteps(JobID, StepName, StepOrder, StepTypeID,  RunModeID, QueryCriteriaID, ReportListID, TransformationID, 
        FileLayoutID,StepFileNameAlgorithm, FileSourcePath, FileSourceExt, AllowMultipleFiles, QueryTemplateID,
        DependsOnStepIDs, UpdatedStamp, CreatedStamp, SendDeliveryConfirmationEmail, SendToTWGExtranet, CreateZeroRecordReport, 
        OrigStepFileNameAlgorithm, PrebuildQuery, SharableReport, StatsTypeID, EmailTemplateID, RunSP_Procedure, 
        RunSP_Params, RunSP_ToStepTable, BeginLoopType, QuerySourceStepID, XFormLogMode, Disabled, EmailNotificationSubject, EmailNotificationMessage, QueryPreview, AltDataStepID, CopyToDestTargetTableName, 
        ZipFileDirectly, DeleteBeforeAppend, RawDataSourceTable, AuditID, DeliveryModeID, CopyFilePath, MakeDatedSubDir, CustomName, UnSavedTempStep, LayoutFormattingMode, IgnoreDataTruncation, prevstepID, 
        NoFilesEmailTemplateID, Files2BothEmailFTP, SentToFTPEmailTemplateID, ReportSampleSize, AltDataCond, LC_CustSchema, LC_RemoveDuplicates, LC_KeyFieldName, CtlFiles2BothEmailFTP, FileWatcherID, 
        ValidationClearedStamp, ValidationClearedBy, ReportTemplateFile, FullRunOption, NormalRunOption, FTPCreateSubDir, CustomStepExecOnServerID, CustomStepSQLCode, CustomStepCaptureResults, OverrideMaxFileSize, 
        AppendFieldMode, FieldPopShowLocationType, StepRecordCount, FullLoadMode, XFormDistinct, GroupByTotals, GroupBySubTotals, FTPCleanUpWindowDays)


select
@AddToJobID, StepName, StepOrder, StepTypeID,  RunModeID, -1 QueryCriteriaID, ReportListID, TransformationID, 
    FileLayoutID,StepFileNameAlgorithm, FileSourcePath, FileSourceExt, AllowMultipleFiles, QueryTemplateID,
    DependsOnStepIDs, getdate() UpdatedStamp, getdate() CreatedStamp, SendDeliveryConfirmationEmail, SendToTWGExtranet, CreateZeroRecordReport, 
    OrigStepFileNameAlgorithm, PrebuildQuery, SharableReport, StatsTypeID, EmailTemplateID, RunSP_Procedure, 
    RunSP_Params, RunSP_ToStepTable, BeginLoopType, QuerySourceStepID, XFormLogMode, Disabled, EmailNotificationSubject, EmailNotificationMessage, QueryPreview, AltDataStepID, CopyToDestTargetTableName, 
    ZipFileDirectly, DeleteBeforeAppend, RawDataSourceTable, AuditID, DeliveryModeID, CopyFilePath, MakeDatedSubDir, CustomName, UnSavedTempStep, LayoutFormattingMode, IgnoreDataTruncation, stepid prevstepID, 
    NoFilesEmailTemplateID, Files2BothEmailFTP, SentToFTPEmailTemplateID, ReportSampleSize, AltDataCond, LC_CustSchema, LC_RemoveDuplicates, LC_KeyFieldName, CtlFiles2BothEmailFTP, FileWatcherID, 
    ValidationClearedStamp, ValidationClearedBy, ReportTemplateFile, FullRunOption, NormalRunOption, FTPCreateSubDir, CustomStepExecOnServerID, CustomStepSQLCode, CustomStepCaptureResults, OverrideMaxFileSize, 
    AppendFieldMode, FieldPopShowLocationType, StepRecordCount, FullLoadMode, XFormDistinct, GroupByTotals, GroupBySubTotals, FTPCleanUpWindowDays
from JobControl..JobSteps
where JobID = @TemplateJobID and StepTypeID != 1125


	declare @StepCounter int
	set @StepCounter = 1

	declare  @CurrentStepID int, @ReplacementStepID int      

     DECLARE curA CURSOR FOR

		select js.stepid CurrentStepID,js2.StepID ReplacementStepID
		from JobControl..JobSteps js 
		left outer join jobcontrol..jobsteps js2 on js2.prevstepID like js.DependsOnStepIDs and js2.JobID = js.JobID																					
		where js.jobid = @AddToJobID
		order by case when js.StepTypeID = 1125 then 3 
		when js.prevstepID is null then 1
		else 2 end, js.StepOrder 
     OPEN curA

	
     FETCH NEXT FROM curA into @CurrentStepID , @ReplacementStepID       


     WHILE (@@FETCH_STATUS <> -1)

     BEGIN
		update JobControl..JobSteps set StepOrder = @StepCounter where StepID = @CurrentStepID and JobID = @AddToJobID
		if @ReplacementStepID is not null
			update JobControl..JobSteps set DependsOnStepIDs = @ReplacementStepID where StepID = @CurrentStepID and JobID = @AddToJobID


		set @StepCounter = @StepCounter + 1
          FETCH NEXT FROM curA into @CurrentStepID , @ReplacementStepID

     END

     CLOSE curA

     DEALLOCATE curA

	 declare @DelivStepID int, @ReportStepID int

	 select @ReportStepID = StepID from JobControl..JobSteps 
	 where 	StepTypeID = 22 and JobID = @AddToJobID and prevstepID is not null

	select @DelivStepID = StepID from JobControl..JobSteps
	where StepTypeID = 1125 and JobID = @AddToJobID

	update JobControl..JobSteps set DependsOnStepIDs = case when DependsOnStepIDs > '' then DependsOnStepIDs + ',' else '' end + LTrim(Str(@ReportStepID)) where StepID = @DelivStepID and JobID = @AddToJobID

	declare @TargetID int, @QStepID int, @QueryCriteriaID int 
			select @QStepID = StepID, @QueryCriteriaID = QueryCriteriaID from JobControl..JobSteps
			where StepTypeID = 1124 and JobID = @AddToJobID
			
			drop table if exists #newQID
				
			create table #NewQID (NewQueryID int)

			insert Into #NewQID
			Exec QueryEditor..CloneExistingQuery @QueryCriteriaID
		
			select @TargetID = NewQueryID from #NewQID
		
			Update JobSteps set QueryCriteriaID=@TargetID where StepID=@QStepID;
END
