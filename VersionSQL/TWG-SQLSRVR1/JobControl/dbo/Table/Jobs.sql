/****** Object:  Table [dbo].[Jobs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.Jobs(
	[JobID] [int] IDENTITY(1,1) NOT NULL,
	[CreatedStamp] [datetime] NULL,
	[JobTemplateID] [int] NULL,
	[JobName] [nvarchar](200) NULL,
	[disabled] [bit] NULL,
	[RunAtStamp] [datetime] NULL,
	[StartedStamp] [datetime] NULL,
	[CompletedStamp] [datetime] NULL,
	[FailedStamp] [datetime] NULL,
	[SQLJobID] [uniqueidentifier] NULL,
	[WaitStamp] [datetime] NULL,
	[RecurringTypeID] [int] NULL,
	[CategoryID] [int] NULL,
	[ModeID] [int] NULL,
	[PromptState] [bit] NULL,
	[PromptIssueWeek] [bit] NULL,
	[JobStateID] [int] NULL,
	[JobIssueWeek] [int] NULL,
	[ProcessTypeID] [int] NULL,
	[VFPIn] [bit] NULL,
	[VFPState] [varchar](10) NULL,
	[VFPCCode] [varchar](10) NULL,
	[VFPJobIDs] [varchar](200) NULL,
	[CustID] [int] NULL,
	[xDescription] [varchar](255) NULL,
	[UpdatedStamp] [datetime] NULL,
	[IsTemplate] [bit] NULL,
	[Type] [varchar](50) NULL,
	[PromptIssueMonth] [bit] NULL,
	[PromptCalYear] [bit] NULL,
	[PromptCalPeriod] [bit] NULL,
	[AuditBeforeDistribution] [bit] NULL,
	[LastJobLogID] [int] NULL,
	[LastJobParameters] [varchar](25) NULL,
	[BypassDocumentLibrary] [bit] NULL,
	[DisabledStamp] [datetime] NULL,
	[TestMode] [bit] NULL,
	[JobStateReference] [varchar](200) NULL,
	[JobNotes] [varchar](max) NULL,
	[Deleted] [bit] NULL,
	[DeletedStamp] [datetime] NULL,
	[DeletedBy] [varchar](50) NULL,
	[InProduction] [bit] NULL,
	[InEditModeStamp] [datetime] NULL,
	[InEditModeUser] [varchar](50) NULL,
	[LastJobRunStartTime] [datetime] NULL,
	[LastJobRunElapsedTime] [varchar](10) NULL,
	[NoticeOnFailure] [bit] NULL,
	[NoticeOnSuccess] [bit] NULL,
	[LastRunFullJob] [bit] NULL,
	[TestModeEmail] [varchar](100) NULL,
	[RecurringTargetID] [int] NULL,
	[RecurringOffset] [int] NULL,
	[NextParamTarget] [varchar](50) NULL,
	[FinalParamTarget] [varchar](50) NULL,
	[CurrParamTarget] [varchar](50) NULL,
	[ProductDefault] [int] NULL,
	[RunSrvrID] [int] NULL,
	[IntoProductionStamp] [datetime] NULL,
	[RunPriority] [int] NULL,
	[DaysToKeepReports] [int] NULL,
	[JobNameAddition] [varchar](100) NULL,
	[VFP_OrderID] [int] NULL,
	[OrigJobName] [varchar](300) NULL,
	[Developer] [varchar](20) NULL,
	[MultiCustJob] [bit] NULL,
	[HideAsNewJob] [bit] NULL,
	[DevStatus] [varchar](100) NULL,
 CONSTRAINT [PK_Jobs] PRIMARY KEY CLUSTERED 
(
	[JobID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE dbo.Jobs ADD  CONSTRAINT [DF_Jobs_CreatedStamp]  DEFAULT (getdate()) FOR [CreatedStamp]
ALTER TABLE dbo.Jobs ADD  CONSTRAINT [DF_Jobs_LastJobParameters]  DEFAULT ('') FOR [LastJobParameters]
ALTER TABLE dbo.Jobs ADD  CONSTRAINT [DF_Jobs_BypassDocumentLibrary]  DEFAULT ((0)) FOR [BypassDocumentLibrary]
ALTER TABLE dbo.Jobs ADD  CONSTRAINT [DF_Jobs_ProductionMode]  DEFAULT ((0)) FOR [TestMode]
CREATE TRIGGER [dbo].[Jobs_JobControlChangeLogTrigger] 
   ON  dbo.Jobs 
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'Jobs', 'Disabled', i.JobID, d.disabled, i.disabled
      FROM Inserted i
			INNER JOIN Deleted d ON i.JobID = d.JobID
		where d.disabled <> i.disabled

    insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'Jobs', 'JobName', i.JobID, d.JobName, i.JobName
      FROM Inserted i
			INNER JOIN Deleted d ON i.JobID = d.JobID
		where d.JobName <> i.JobName

    insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'Jobs', 'CustID', i.JobID, d.CustID, i.CustID
      FROM Inserted i
			INNER JOIN Deleted d ON i.JobID = d.JobID
		where d.CustID <> i.CustID

    insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue)
	select getdate(), SYSTEM_USER, 'Jobs', 'TestMode', i.JobID, d.TestMode, i.TestMode
      FROM Inserted i
			INNER JOIN Deleted d ON i.JobID = d.JobID
		where d.TestMode <> i.TestMode


END

ALTER TABLE dbo.Jobs ENABLE TRIGGER [Jobs_JobControlChangeLogTrigger]
