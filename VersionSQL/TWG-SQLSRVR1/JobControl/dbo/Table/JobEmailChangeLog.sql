/****** Object:  Table [dbo].[JobEmailChangeLog]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobEmailChangeLog(
	[DestID] [int] NULL,
	[EmailAddr] [varchar](100) NULL,
	[ChangeStamp] [datetime] NULL,
	[UserName] [varchar](50) NULL,
	[JobID] [int] NULL,
	[StepID] [int] NULL,
	[Action] [varchar](50) NULL,
	[RecID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
