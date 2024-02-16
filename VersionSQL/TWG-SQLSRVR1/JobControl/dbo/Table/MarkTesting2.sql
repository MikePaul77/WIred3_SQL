/****** Object:  Table [dbo].[MarkTesting2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.MarkTesting2(
	[_IndexOrderKey] [int] IDENTITY(1,1) NOT NULL,
	[County] [varchar](100) NULL,
	[Town] [varchar](100) NULL,
	[LastYear] [int] NULL,
	[Category] [varchar](10) NULL,
	[msp1] [varchar](15) NULL,
	[msp2] [varchar](15) NULL,
	[msp3] [varchar](15) NULL,
	[msp4] [varchar](15) NULL,
	[msp5] [varchar](15) NULL,
	[ypc1] [varchar](15) NULL,
	[ypc2] [varchar](15) NULL,
	[ypc3] [varchar](15) NULL,
	[ypc4] [varchar](15) NULL,
	[ypc5] [varchar](15) NULL
) ON [PRIMARY]
