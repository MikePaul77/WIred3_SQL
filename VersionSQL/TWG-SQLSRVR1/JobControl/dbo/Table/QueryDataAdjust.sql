/****** Object:  Table [dbo].[QueryDataAdjust]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.QueryDataAdjust(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[StateID] [int] NULL,
	[FieldValue] [varchar](50) NULL,
	[StepID] [int] NULL,
	[Include] [bit] NULL,
	[IssueWeek] [int] NULL,
	[Ignore] [bit] NULL,
	[FieldID] [int] NULL,
	[LogOverride] [bit] NULL,
	[IssueMonth] [varchar](10) NULL
) ON [PRIMARY]
