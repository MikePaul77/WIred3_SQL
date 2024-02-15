/****** Object:  Table [dbo].[VFPJobs_Map_Reports]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_Map_Reports(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[ReportID] [int] NULL,
	[Verified] [bit] NULL,
	[VFP_REPORT_ID] [varchar](10) NULL,
	[DESCRIP] [varchar](80) NULL,
	[CATEGORY] [varchar](10) NULL,
	[Outtype] [varchar](3) NULL,
	[FILEEXT] [varchar](3) NULL,
	[notes] [varchar](max) NULL,
	[XFORMID] [varchar](10) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
