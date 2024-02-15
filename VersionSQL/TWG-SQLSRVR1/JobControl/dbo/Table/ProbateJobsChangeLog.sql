/****** Object:  Table [dbo].[ProbateJobsChangeLog]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.ProbateJobsChangeLog(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[LogStamp] [datetime] NULL,
	[Username] [varchar](50) NULL,
	[ChangeLog] [varchar](500) NULL,
	[OrigValue] [varchar](max) NULL,
	[NewValue] [varchar](max) NULL,
	[LogType] [varchar](50) NULL,
	[StepID] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
