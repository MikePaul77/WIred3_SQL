﻿/****** Object:  Table [dbo].[Jobs_PreOffsetFlip]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.Jobs_PreOffsetFlip(
	[JobID] [int] IDENTITY(1,1) NOT NULL,
	[CreatedStamp] [datetime] NULL,
	[JobTemplateID] [int] NULL,
	[JobName] [nvarchar](100) NOT NULL,
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
	[VFPJobID] [int] NULL,
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
	[DaysToKeepReports] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]