/****** Object:  Table [dbo].[JobStepLogHist]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobStepLogHist(
	[LogRecID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[JobStepID] [int] NULL,
	[LogStamp] [datetime] NULL,
	[LogInformation] [varchar](max) NULL,
	[LogInfoType] [int] NULL,
	[LogInfoSource] [varchar](100) NULL,
	[JobLogID] [int] NULL,
	[LoopCount] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

CREATE NONCLUSTERED INDEX [JobStepLogHist_JobID_W_LogRecID_JobStepID_LogStamp_LogInformation_LogInfoType_LogInfoSource] ON dbo.JobStepLogHist
(
	[JobID] ASC
)
INCLUDE([LogRecID],[JobStepID],[LogStamp],[LogInformation],[LogInfoType],[LogInfoSource]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
