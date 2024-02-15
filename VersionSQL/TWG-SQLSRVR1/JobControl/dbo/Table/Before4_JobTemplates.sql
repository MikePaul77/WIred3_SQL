/****** Object:  Table [dbo].[Before4_JobTemplates]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.Before4_JobTemplates(
	[TemplateID] [int] IDENTITY(1,1) NOT NULL,
	[Type] [varchar](50) NULL,
	[Description] [varchar](255) NULL,
	[CategoryID] [int] NULL,
	[RunModeID] [int] NULL,
	[RecurringTypeID] [int] NULL,
	[CreatedStamp] [datetime] NULL,
	[disabled] [bit] NULL,
	[UpdatedStamp] [datetime] NULL,
	[PromptState] [bit] NULL,
	[PromptIssueWeek] [bit] NULL,
	[JobStateID] [int] NULL,
	[JobIssueWeek] [int] NULL,
	[ProcessTypeID] [int] NULL,
	[VFPIn] [bit] NULL
) ON [PRIMARY]
