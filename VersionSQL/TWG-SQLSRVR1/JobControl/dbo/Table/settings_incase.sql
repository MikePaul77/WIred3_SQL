/****** Object:  Table [dbo].[settings_incase]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.settings_incase(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Property] [varchar](50) NULL,
	[Value] [varchar](500) NULL,
	[Note] [varchar](500) NULL
) ON [PRIMARY]
