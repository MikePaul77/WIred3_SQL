/****** Object:  Table [dbo].[InCase_QueryRanges]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.InCase_QueryRanges(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[QueryID] [int] NULL,
	[RangeSource] [varchar](50) NULL,
	[MinValue] [varchar](50) NULL,
	[MaxValue] [varchar](50) NULL,
	[VFPIn] [bit] NULL,
	[Exclude] [bit] NULL
) ON [PRIMARY]
