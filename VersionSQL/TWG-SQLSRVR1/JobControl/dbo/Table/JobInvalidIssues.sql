/****** Object:  Table [dbo].[JobInvalidIssues]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobInvalidIssues(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[StepID] [int] NULL,
	[Issue] [varchar](500) NULL,
	[IssueLevel] [int] NULL
) ON [PRIMARY]
