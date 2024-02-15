/****** Object:  Table [dbo].[jobthrottle_incase]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.jobthrottle_incase(
	[MaxJobs] [int] NULL,
	[ThrottlerEnabled] [bit] NULL,
	[EnabledTime] [datetime] NULL,
	[DisabledTime] [datetime] NULL,
	[LastUpdate] [datetime] NULL,
	[WiredJobMaxRunMinutes] [int] NULL
) ON [PRIMARY]
