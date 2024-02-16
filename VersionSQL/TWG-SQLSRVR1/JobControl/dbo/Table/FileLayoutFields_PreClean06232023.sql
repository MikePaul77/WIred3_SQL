﻿/****** Object:  Table [dbo].[FileLayoutFields_PreClean06232023]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.FileLayoutFields_PreClean06232023(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[FileLayoutID] [int] NULL,
	[OutOrder] [int] NULL,
	[SortOrder] [int] NULL,
	[SortDir] [varchar](10) NULL,
	[OutType_NOLONGERUSED] [varchar](50) NULL,
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
	[DecimalPlaces_NOLONGERUSED] [int] NULL,
	[XLNoFormat] [bit] NULL,
	[XLAlign] [varchar](7) NULL,
	[Hide] [bit] NULL,
	[FieldDescrip] [varchar](max) NULL,
	[LayoutFormatID] [int] NULL,
	[ConformToWidth] [bit] NULL,
	[IgnoreDataTruncation] [bit] NULL,
	[DBFType] [varchar](100) NULL,
	[DBFNotNull] [bit] NULL,
	[FutureUse] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]