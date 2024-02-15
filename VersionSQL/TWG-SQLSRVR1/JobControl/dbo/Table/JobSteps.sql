/****** Object:  Table [dbo].[JobSteps]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobSteps(
	[StepID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NOT NULL,
	[StepName] [nvarchar](500) NOT NULL,
	[StepOrder] [int] NULL,
	[StepTypeID] [int] NOT NULL,
	[RunAtStamp] [datetime] NULL,
	[StartedStamp] [datetime] NULL,
	[CompletedStamp] [datetime] NULL,
	[FailedStamp] [datetime] NULL,
	[SQLJobStepID] [int] NULL,
	[WaitStamp] [datetime] NULL,
	[RunModeID] [int] NULL,
	[RequiresSetup] [bit] NULL,
	[QueryCriteriaID] [int] NULL,
	[ReportListID] [int] NULL,
	[TransformationID] [int] NULL,
	[FileLayoutID] [int] NULL,
	[SpecialID] [int] NULL,
	[DependsOnStep_DoNOTUSE] [int] NULL,
	[StepFileNameAlgorithm] [varchar](max) NULL,
	[FileSourcePath] [varchar](500) NULL,
	[FileSourceExt] [varchar](50) NULL,
	[AllowMultipleFiles] [bit] NULL,
	[StepSubProcessID] [int] NULL,
	[QueryTemplateID] [int] NULL,
	[DependsOnStepID_DoNOTUSE] [int] NULL,
	[VFPIn] [bit] NULL,
	[VFP_QueryID] [varchar](50) NULL,
	[VFP_BTCRITID] [varchar](50) NULL,
	[VFP_LayoutID] [varchar](50) NULL,
	[VFP_ReportID] [varchar](50) NULL,
	[DependsOnStepIDs] [varchar](500) NULL,
	[UpdatedStamp] [datetime] NULL,
	[CreatedStamp] [datetime] NULL,
	[DeliveryTypeID_DoNotUse] [int] NULL,
	[SendDeliveryConfirmationEmail] [bit] NULL,
	[SendToTWGExtranet] [bit] NULL,
	[VFP_CALLPROC] [varchar](500) NULL,
	[CreateZeroRecordReport] [bit] NULL,
	[OrigStepFileNameAlgorithm] [varchar](max) NULL,
	[DeliveryListID_DONOTUSE] [int] NULL,
	[DeliveryNoticeListID_DONOTUSE] [int] NULL,
	[DeliveryNoticeTemplateID_DONOTUSE] [int] NULL,
	[PrebuildQuery] [bit] NULL,
	[SharableReport] [bit] NULL,
	[StatsTypeID] [int] NULL,
	[EmailTemplateID] [int] NULL,
	[RunSP_Procedure] [varchar](200) NULL,
	[RunSP_Params] [varchar](2000) NULL,
	[RunSP_ToStepTable] [bit] NULL,
	[BeginLoopType] [int] NULL,
	[QuerySourceStepID] [int] NULL,
	[XFormLogMode] [int] NULL,
	[Disabled] [bit] NULL,
	[EmailNotificationSubject] [varchar](200) NULL,
	[EmailNotificationMessage] [varchar](max) NULL,
	[QueryPreview] [varchar](max) NULL,
	[AltDataStepID] [int] NULL,
	[CopyToDestTargetTableName] [varchar](100) NULL,
	[ZipFileDirectly] [int] NULL,
	[DeleteBeforeAppend] [bit] NULL,
	[RawDataSourceTable] [varchar](200) NULL,
	[AuditID] [int] NULL,
	[DeliveryModeID] [int] NULL,
	[CopyFilePath] [varchar](2000) NULL,
	[MakeDatedSubDir] [bit] NULL,
	[CustomName] [varchar](100) NULL,
	[UnSavedTempStep] [bit] NULL,
	[LayoutFormattingMode] [int] NULL,
	[IgnoreDataTruncation] [bit] NULL,
	[prevstepID] [int] NULL,
	[NoFilesEmailTemplateID] [int] NULL,
	[Files2BothEmailFTP] [bit] NULL,
	[SentToFTPEmailTemplateID] [int] NULL,
	[ReportSampleSize] [int] NULL,
	[AltDataCond] [varchar](max) NULL,
	[LC_CustSchema] [varchar](50) NULL,
	[LC_RemoveDuplicates] [bit] NULL,
	[LC_KeyFieldName] [varchar](100) NULL,
	[CtlFiles2BothEmailFTP] [bit] NULL,
	[FileWatcherID] [int] NULL,
	[ValidationClearedStamp] [datetime] NULL,
	[ValidationClearedBy] [varchar](50) NULL,
	[ReportTemplateFile] [varchar](500) NULL,
	[FullRunOption] [varchar](100) NULL,
	[NormalRunOption] [varchar](100) NULL,
	[FTPCreateSubDir] [varchar](100) NULL,
	[CustomStepExecOnServerID] [int] NULL,
	[CustomStepSQLCode] [varchar](max) NULL,
	[CustomStepCaptureResults] [bit] NULL,
	[OverrideMaxFileSize] [bit] NULL,
	[AppendFieldMode] [varchar](20) NULL,
	[FieldPopShowLocationType] [varchar](50) NULL,
	[StepRecordCount] [int] NULL,
	[FullLoadMode] [int] NULL,
	[XFormDistinct] [bit] NULL,
	[GroupByTotals] [bit] NULL,
	[GroupBySubTotals] [bit] NULL,
	[FTPCleanUpWindowDays] [int] NULL,
	[SnowflakeStageName] [varchar](100) NULL,
	[SnowflakeProcedureName] [varchar](100) NULL,
 CONSTRAINT [PK_JobSteps] PRIMARY KEY CLUSTERED 
(
	[StepID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_JobSteps_StepID] ON dbo.JobSteps
(
	[StepID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [JobID] ON dbo.JobSteps
(
	[JobID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [JobSteps_JobID_Stamps] ON dbo.JobSteps
(
	[JobID] ASC
)
INCLUDE([StartedStamp],[CompletedStamp],[FailedStamp]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [JobSteps_QueryCriteriaID_JobID_QueryTemplateID_QuerySourceStepID] ON dbo.JobSteps
(
	[QueryCriteriaID] ASC
)
INCLUDE([JobID],[QueryTemplateID],[QuerySourceStepID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [JobSteps_StepTypeID_WDependsOnStepIDs_Disabled] ON dbo.JobSteps
(
	[StepTypeID] ASC
)
INCLUDE([DependsOnStepIDs],[Disabled]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [StepTypeID_JobIDQueryCriteriaIDQueryTemplateIDDisabled] ON dbo.JobSteps
(
	[StepTypeID] ASC
)
INCLUDE([JobID],[QueryCriteriaID],[QueryTemplateID],[Disabled]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [StepTypeID_JobIDTransformationIDDependsOnStepIDs] ON dbo.JobSteps
(
	[StepTypeID] ASC
)
INCLUDE([JobID],[TransformationID],[DependsOnStepIDs]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [StepTypeID_QueryCriteriaID_JobIDStepOrderDisabled] ON dbo.JobSteps
(
	[StepTypeID] ASC,
	[QueryCriteriaID] ASC
)
INCLUDE([JobID],[StepOrder],[Disabled]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [TransformationID_JobIDDisabled] ON dbo.JobSteps
(
	[TransformationID] ASC
)
INCLUDE([JobID],[Disabled]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[JobSteps_JobControlChangeLogTrigger] 
   ON  dbo.JobSteps 
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

--StepOrder
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'StepOrder', i.StepID, d.StepOrder, i.StepOrder
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.StepOrder,-1) <> coalesce(i.StepOrder,-1)

--RunModeID
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'RunModeID', i.StepID, d.RunModeID, i.RunModeID
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.RunModeID,-1) <> coalesce(i.RunModeID,-1)

--QueryCriteriaID
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'QueryCriteriaID', i.StepID, d.QueryCriteriaID, i.QueryCriteriaID
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.QueryCriteriaID,-1) <> coalesce(i.QueryCriteriaID, -1)
--QueryTemplateID
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'QueryTemplateID', i.StepID, d.QueryTemplateID, i.QueryTemplateID
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.QueryTemplateID, -1) <> coalesce(i.QueryTemplateID,-1)
--ReportListID
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'ReportListID', i.StepID, d.ReportListID, i.ReportListID
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.ReportListID,-1) <> coalesce(i.ReportListID,-1)
			
--TransformationID
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'TransformationID', i.StepID, coalesce(d.TransformationID,''), coalesce(i.TransformationID,'')
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.TransformationID, -1) <> coalesce(i.TransformationID, -1)
--FileLayoutID
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'FileLayoutID', i.StepID, d.FileLayoutID, i.FileLayoutID
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.FileLayoutID, -1) <> coalesce(i.FileLayoutID, -1)
--SpecialID
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'SpecialID', i.StepID, d.SpecialID, i.SpecialID
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.SpecialID, -1) <> coalesce(i.SpecialID, -1)
--StepFileNameAlgorithm
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'StepFileNameAlgorithm', i.StepID, d.StepFileNameAlgorithm, i.StepFileNameAlgorithm
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.StepFileNameAlgorithm, '@#$') <> coalesce(i.StepFileNameAlgorithm, '@#$')
--DependsOnStepIDs
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'DependsOnStepIDs', i.StepID, d.DependsOnStepIDs, i.DependsOnStepIDs
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.DependsOnStepIDs, '@#$') <> coalesce(i.DependsOnStepIDs, '@#$')
--DeliveryTypeID
	--insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	--select getdate(), SYSTEM_USER, 'JobSteps', 'DeliveryTypeID', i.StepID, d.DeliveryTypeID, i.DeliveryTypeID
 --     FROM Inserted i
	--		INNER JOIN Deleted d ON i.StepID = d.StepID
	--	where coalesce(d.DeliveryTypeID, -1) <> coalesce(i.DeliveryTypeID, -1)
--EmailTemplateID
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'EmailTemplateID', i.StepID, d.EmailTemplateID, i.EmailTemplateID
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.EmailTemplateID, -1) <> coalesce(i.EmailTemplateID, -1)
--StatsTypeID
	insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'JobSteps', 'StatsTypeID', i.StepID, d.StatsTypeID, i.StatsTypeID
      FROM Inserted i
			INNER JOIN Deleted d ON i.StepID = d.StepID
		where coalesce(d.StatsTypeID, -1) <> coalesce(i.StatsTypeID, -1)

END

ALTER TABLE dbo.JobSteps ENABLE TRIGGER [JobSteps_JobControlChangeLogTrigger]
