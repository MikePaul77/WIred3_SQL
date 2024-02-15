/****** Object:  Table [dbo].[UserSearchHistory]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.UserSearchHistory(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NULL,
	[Value] [varchar](500) NULL
) ON [PRIMARY]
