/****** Object:  Table [dbo].[SpecialTemplates]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.SpecialTemplates(
	[SpecialId] [int] NOT NULL,
	[DtsxPackagePath] [varchar](255) NULL,
	[OutputType] [nchar](3) NOT NULL,
	[Description] [varchar](255) NULL
) ON [PRIMARY]
