/****** Object:  Table [dbo].[HoldJobQueue]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.HoldJobQueue(
	[JobID] [int] NULL,
	[HoldStamp] [datetime] NULL,
	[ReQueuedStamp] [datetime] NULL,
	[HoldReason] [varchar](500) NULL,
	[RecID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
