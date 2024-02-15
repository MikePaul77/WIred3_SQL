﻿/****** Object:  Table [dbo].[FileLayoutFields]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.FileLayoutFields(
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
	[FutureUse] [bit] NULL,
	[DataTypeID] [int] NULL,
	[LookupID] [int] NULL,
 CONSTRAINT [PK_FileLayoutFields] PRIMARY KEY CLUSTERED 
(
	[RecID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
