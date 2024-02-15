/****** Object:  Table [dbo].[JobSubProcessTypes]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobSubProcessTypes(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobProcessType] [int] NULL,
	[Code] [varchar](10) NULL,
	[Description] [varchar](100) NULL
) ON [PRIMARY]
