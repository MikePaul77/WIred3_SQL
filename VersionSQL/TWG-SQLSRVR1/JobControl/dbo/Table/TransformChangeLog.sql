/****** Object:  Table [dbo].[TransformChangeLog]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.TransformChangeLog(
	[RecID] [int] NULL,
	[TransformTemplateID] [int] NULL,
	[OrigOutName] [varchar](200) NULL,
	[OrigSourceCode] [varchar](max) NULL,
	[OrigDisabled] [bit] NULL,
	[NewOutName] [varchar](200) NULL,
	[NewSourceCode] [varchar](max) NULL,
	[NewDisabled] [bit] NULL,
	[ChangedByUser] [varchar](100) NULL,
	[ChangedStamp] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
