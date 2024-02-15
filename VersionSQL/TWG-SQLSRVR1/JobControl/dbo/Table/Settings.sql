/****** Object:  Table [dbo].[Settings]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.Settings(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Property] [varchar](50) NULL,
	[Value] [varchar](500) NULL,
	[Note] [varchar](500) NULL,
	[Group] [varchar](50) NULL,
	[Disabled] [bit] NULL
) ON [PRIMARY]
