/****** Object:  Table [dbo].[QueryTypes]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.QueryTypes(
	[QueryTypeID] [int] IDENTITY(1,1) NOT NULL,
	[QueryTypeName] [nvarchar](50) NULL,
	[QuerySourceID] [int] NULL,
	[ReqDataType] [varchar](100) NULL,
	[DefaultID] [int] NULL,
	[DefaultXFormID] [int] NULL,
	[ShortDataType] [varchar](10) NULL,
	[EarlyRun] [bit] NULL,
 CONSTRAINT [PK_QueryTypes] PRIMARY KEY CLUSTERED 
(
	[QueryTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
