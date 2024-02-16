/****** Object:  Table [dbo].[JobSchedule_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobSchedule_NOLONGERUSED(
	[ScheduleID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](200) NULL,
	[CreateDate] [datetime] NOT NULL,
	[SQLCode] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE dbo.JobSchedule_NOLONGERUSED ADD  CONSTRAINT [DF_JobSchedule_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
