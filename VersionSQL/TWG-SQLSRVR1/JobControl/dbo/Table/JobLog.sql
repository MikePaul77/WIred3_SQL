/****** Object:  Table [dbo].[JobLog]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobLog(
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

CREATE NONCLUSTERED INDEX [JobLog_CancelTime] ON dbo.JobLog
(
	[CancelTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [JobLog_CancelTimeQueueTime] ON dbo.JobLog
(
	[CancelTime] ASC,
	[QueueTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [JobLog_ID_wJobParameters] ON dbo.JobLog
(
	[ID] ASC
)
INCLUDE([JobParameters]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [JobLog_JobID_QueueJobParams] ON dbo.JobLog
(
	[JobID] ASC
)
INCLUDE([QueueJobParams]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [JobLog_StartTimeCancelTimeQueueTime] ON dbo.JobLog
(
	[StartTime] ASC,
	[CancelTime] ASC,
	[QueueTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE dbo.JobLog ADD  CONSTRAINT [DF_JobLog_QueueTime]  DEFAULT (getdate()) FOR [QueueTime]
