/****** Object:  Table [dbo].[JobTemplates_2BDel]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobTemplates_2BDel(
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
	[VFPIn] [bit] NULL,
 CONSTRAINT [PK_JobTemplates] PRIMARY KEY CLUSTERED 
(
	[TemplateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE dbo.JobTemplates_2BDel  WITH CHECK ADD  CONSTRAINT [FK_JobTemplates_JobCategories_CategoryID] FOREIGN KEY([CategoryID])
REFERENCES [dbo].[JobCategories] ([ID])
ALTER TABLE dbo.JobTemplates_2BDel CHECK CONSTRAINT [FK_JobTemplates_JobCategories_CategoryID]
ALTER TABLE dbo.JobTemplates_2BDel  WITH CHECK ADD  CONSTRAINT [FK_JobTemplates_JobRecurringTypes_RecurringTypeID] FOREIGN KEY([RecurringTypeID])
REFERENCES [dbo].[JobRecurringTypes] ([ID])
ALTER TABLE dbo.JobTemplates_2BDel CHECK CONSTRAINT [FK_JobTemplates_JobRecurringTypes_RecurringTypeID]
