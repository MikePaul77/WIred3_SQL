/****** Object:  Table [dbo].[StatsType]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.StatsType(
	[StatsTypeID] [int] IDENTITY(1,1) NOT NULL,
	[StatsDescription] [varchar](100) NULL,
	[disabled] [bit] NULL,
	[SCT] [varchar](6) NULL
) ON [PRIMARY]

ALTER TABLE dbo.StatsType ADD  CONSTRAINT [DF_StatsType_disabled]  DEFAULT ((0)) FOR [disabled]
