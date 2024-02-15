/****** Object:  Table [dbo].[FileAlgorithmCodes]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.FileAlgorithmCodes(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Code] [varchar](50) NULL,
	[Description] [varchar](500) NULL,
	[Active] [bit] NULL,
	[Comment] [varchar](2000) NULL,
	[Example] [varchar](500) NULL,
	[Sample] [varchar](20) NULL,
	[Coded] [bit] NULL
) ON [PRIMARY]
