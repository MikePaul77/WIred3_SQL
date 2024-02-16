/****** Object:  Table [dbo].[InCase_FileLayoutFields]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.InCase_FileLayoutFields(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[FileLayoutID] [int] NULL,
	[OutOrder] [int] NULL,
	[SortOrder] [int] NULL,
	[SortDir] [varchar](10) NULL,
	[OutType] [varchar](50) NULL,
	[OutWidth] [int] NULL,
	[SrcName] [varchar](200) NULL,
	[OutName] [varchar](200) NULL,
	[Disabled] [bit] NULL,
	[CaseChange] [varchar](50) NULL,
	[DoNotTrim] [bit] NULL,
	[Padding] [varchar](20) NULL,
	[PaddingLength] [int] NULL,
	[PaddingChar] [varchar](5) NULL,
	[VFPIn] [bit] NULL,
	[DecimalPlaces] [int] NULL
) ON [PRIMARY]
