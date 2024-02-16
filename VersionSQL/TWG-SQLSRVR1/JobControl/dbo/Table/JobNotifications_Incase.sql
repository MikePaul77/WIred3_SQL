/****** Object:  Table [dbo].[JobNotifications_Incase]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobNotifications_Incase(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[CreatedStamp] [datetime] NULL,
	[JobID] [int] NULL,
	[NoticeSentStamp] [datetime] NULL
) ON [PRIMARY]
