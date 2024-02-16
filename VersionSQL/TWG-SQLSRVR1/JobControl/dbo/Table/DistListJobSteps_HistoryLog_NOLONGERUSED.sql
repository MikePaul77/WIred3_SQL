/****** Object:  Table [dbo].[DistListJobSteps_HistoryLog_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DistListJobSteps_HistoryLog_NOLONGERUSED(
	[JobStepID] [int] NULL,
	[ListID] [int] NULL,
	[ActionType] [varchar](6) NULL,
	[ActionDate] [datetime] NULL,
	[ActionUser] [varchar](50) NULL
) ON [PRIMARY]
