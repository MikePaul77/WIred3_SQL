/****** Object:  Table [dbo].[XFormOtherValidataions]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.XFormOtherValidataions(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[LayoutID] [int] NULL,
	[Disabled] [bit] NULL,
	[LocationWarnRecs] [int] NULL,
	[LocationFailRecs] [int] NULL,
	[AllLocationsTotal] [bit] NULL,
	[NoDups] [bit] NULL
) ON [PRIMARY]
