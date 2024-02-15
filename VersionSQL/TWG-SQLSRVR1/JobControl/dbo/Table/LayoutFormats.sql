/****** Object:  Table [dbo].[LayoutFormats]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.LayoutFormats(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[FormatGroup] [varchar](20) NULL,
	[FormatExample] [varchar](20) NULL,
	[Disabled] [bit] NULL,
	[DisplayOrder] [int] NULL,
	[DBDecimals] [int] NULL
) ON [PRIMARY]
