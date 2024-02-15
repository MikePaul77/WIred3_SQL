/****** Object:  Table [dbo].[QuerySources]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.QuerySources(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SourceName] [varchar](50) NULL,
	[AllStdStates] [bit] NULL,
	[SrcPriority] [int] NULL,
	[DisplayName] [varchar](100) NULL,
	[ShortName] [varchar](10) NULL,
	[PublicShortName] [varchar](20) NULL
) ON [PRIMARY]
