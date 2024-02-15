/****** Object:  Table [dbo].[VFPJobs_Map_BitCritToConds]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_Map_BitCritToConds(
	[RecId] [int] IDENTITY(1,1) NOT NULL,
	[TemplateID] [int] NULL,
	[OrRecID] [int] NULL,
	[Ignore] [bit] NULL,
	[cond] [varchar](max) NULL,
	[NewCondPlace] [varchar](50) NULL,
	[NewCondType] [varchar](50) NULL,
	[NewCondField] [varchar](100) NULL,
	[NewCondNot] [bit] NULL,
	[NewCondSymbol] [varchar](10) NULL,
	[NewCondValue] [varchar](max) NULL,
	[Comment] [varchar](max) NULL,
	[FullOrigCond] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
