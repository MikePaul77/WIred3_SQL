/****** Object:  Table [dbo].[DistLists_HistoryLog_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DistLists_HistoryLog_NOLONGERUSED(
	[ID] [int] NULL,
	[ListName] [varchar](500) NULL,
	[Disabled] [bit] NULL,
	[ListCat] [varchar](50) NULL,
	[ActionType] [varchar](6) NULL,
	[ActionDate] [datetime] NULL,
	[ActionUser] [varchar](50) NULL
) ON [PRIMARY]
