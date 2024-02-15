/****** Object:  Table [dbo].[JobStepTypeGroups]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobStepTypeGroups(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[GroupName] [varchar](100) NULL,
	[GroupOrder] [int] NULL
) ON [PRIMARY]
