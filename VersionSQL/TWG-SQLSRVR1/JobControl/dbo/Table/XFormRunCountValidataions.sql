/****** Object:  Table [dbo].[XFormRunCountValidataions]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.XFormRunCountValidataions(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[LayoutID] [int] NULL,
	[LastRuns] [int] NULL,
	[PctFail] [int] NULL,
	[PctWarn] [int] NULL,
	[Disabled] [bit] NULL
) ON [PRIMARY]
