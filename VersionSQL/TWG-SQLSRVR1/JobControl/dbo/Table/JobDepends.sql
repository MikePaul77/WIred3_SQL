/****** Object:  Table [dbo].[JobDepends]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobDepends(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[DependsOnJobID] [int] NULL
) ON [PRIMARY]
