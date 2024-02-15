/****** Object:  Table [dbo].[Test_JobLog]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.Test_JobLog(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[RunPriority] [int] NULL,
	[StartTime] [datetime] NULL,
	[QueueTime] [datetime] NULL,
	[SQLJobID] [varchar](36) NULL,
	[CancelTime] [datetime] NULL,
	[CreateUser] [int] NULL,
	[JobParameters] [varchar](25) NULL,
	[JobStepID] [int] NULL,
	[EndTime] [datetime] NULL,
	[JobOutcome] [nvarchar](4000) NULL,
	[TestMode] [bit] NULL,
	[InProduction] [bit] NULL,
	[QueueJobParams] [varchar](50) NULL,
	[PrebuildStarted] [bit] NULL
) ON [PRIMARY]
