/****** Object:  Table [dbo].[XFormChangeLog]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.XFormChangeLog(
	[DocType] [varchar](50) NULL,
	[DocID] [int] NULL,
	[DocRecID] [int] NULL,
	[DocProperty] [varchar](100) NULL,
	[BeforeValue] [varchar](max) NULL,
	[AfterValue] [varchar](max) NULL,
	[ChangeStamp] [datetime] NULL,
	[userID] [int] NULL,
	[Note] [varchar](500) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
