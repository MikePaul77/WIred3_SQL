/****** Object:  Table [dbo].[DistListEntries_HistoryLog_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DistListEntries_HistoryLog_NOLONGERUSED(
	[ID] [int] NULL,
	[ListID] [int] NULL,
	[EntryType] [varchar](10) NULL,
	[Disabled] [bit] NULL,
	[SourceID] [int] NULL,
	[EmailAddress] [varchar](250) NULL,
	[EmailName] [varchar](250) NULL,
	[FTP] [bit] NULL,
	[Email] [bit] NULL,
	[ActionType] [varchar](6) NULL,
	[ActionDate] [datetime] NULL,
	[ActionUser] [varchar](50) NULL
) ON [PRIMARY]
