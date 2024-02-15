/****** Object:  Table [dbo].[VFPJobs_FileLayoutFields_Corrections]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_FileLayoutFields_Corrections(
	[ShortFileLayoutName] [nvarchar](100) NULL,
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
	[DecimalPlaces] [int] NULL,
	[CreateDate] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE dbo.VFPJobs_FileLayoutFields_Corrections ADD  CONSTRAINT [DF_VFPJobs_FileLayoutFields_Corrections_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
