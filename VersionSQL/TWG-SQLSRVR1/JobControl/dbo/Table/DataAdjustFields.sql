/****** Object:  Table [dbo].[DataAdjustFields]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DataAdjustFields(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ShowFieldName] [varchar](200) NULL,
	[UseFieldName] [varchar](200) NULL,
	[disabled] [bit] NULL
) ON [PRIMARY]
