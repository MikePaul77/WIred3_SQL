/****** Object:  Table [dbo].[Reports]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.Reports(
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ReportName] [varchar](200) NULL,
	[Description] [nvarchar](200) NULL,
	[QueryTemplateId] [int] NULL,
	[TransformationTemplateId] [int] NULL,
	[Extension] [varchar](5) NULL,
	[JobType] [varchar](6) NULL,
	[JobCategory] [varchar](6) NULL,
	[SubType] [varchar](10) NULL,
	[OutputType] [varchar](10) NULL,
	[ModiDate] [datetime] NULL,
	[Notes] [nvarchar](max) NULL,
	[DtsxPackageName] [nvarchar](125) NULL,
	[RsReportName] [nvarchar](50) NULL,
	[SSISCommand] [nvarchar](max) NULL,
	[SortOrder] [int] NULL,
	[IsDefault] [bit] NULL,
	[PaperStockTypeId] [int] NULL,
	[disabled] [bit] NULL,
	[VFPReportID] [varchar](50) NULL,
	[BaseID] [int] NULL,
	[DynamicOption] [bit] NULL,
	[CtlDataSQL] [varchar](max) NULL,
	[CTLRep] [bit] NULL,
	[UsesFileTemplate] [bit] NULL,
	[FixedWidth] [bit] NULL,
 CONSTRAINT [PK_Reports] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
