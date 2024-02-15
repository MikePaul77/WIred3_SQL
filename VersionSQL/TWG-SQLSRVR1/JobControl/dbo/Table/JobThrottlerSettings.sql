/****** Object:  Table [dbo].[JobThrottlerSettings]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobThrottlerSettings(
	[MaxJobs] [int] NULL,
	[ThrottlerEnabled] [bit] NULL,
	[EnabledTime] [datetime] NULL,
	[DisabledTime] [datetime] NULL,
	[LastUpdate] [datetime] NULL,
	[WiredJobMaxRunMinutes] [int] NULL
) ON [PRIMARY]
