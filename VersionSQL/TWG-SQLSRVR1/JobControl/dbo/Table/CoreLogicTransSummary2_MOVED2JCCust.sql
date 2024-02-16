/****** Object:  Table [dbo].[CoreLogicTransSummary2_MOVED2JCCust]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.CoreLogicTransSummary2_MOVED2JCCust(
	[StateID] [varchar](1000) NULL,
	[Processyear] [varchar](1000) NULL,
	[Processweek] [varchar](1000) NULL,
	[RecType] [varchar](1000) NULL,
	[CLRecCount] [varchar](1000) NULL,
	[TransCount] [varchar](1000) NULL,
	[_IndexOrderKey] [int] NULL,
	[Param_JobStepID] [int] NOT NULL,
	[Param_IssueWeek] [varchar](6) NULL
) ON [PRIMARY]
