/****** Object:  Table [dbo].[JobAddedFiles]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobAddedFiles(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[ToJobStepID] [int] NULL,
	[FromJobStepID] [int] NULL,
	[Iteration_TownID] [int] NULL,
	[Iteration_CountyID] [int] NULL,
	[Iteration_StateID] [int] NULL
) ON [PRIMARY]
