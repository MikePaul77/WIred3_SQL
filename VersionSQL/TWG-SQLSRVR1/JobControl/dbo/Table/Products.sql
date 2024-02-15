/****** Object:  Table [dbo].[Products]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.Products(
	[Id] [int] NOT NULL,
	[ProductCode] [nvarchar](15) NOT NULL,
	[ProductCategory] [nvarchar](50) NULL,
	[ProductName] [nvarchar](50) NOT NULL,
	[QBItem] [nvarchar](50) NULL,
	[JobType] [varchar](12) NOT NULL,
	[JobCategoryCode] [nvarchar](10) NULL,
	[Recurring] [varchar](2) NOT NULL,
	[QueryTemplateId] [int] NULL,
	[TransformationId] [int] NULL,
	[FileLayoutId] [int] NULL,
	[WIREDproduct] [bit] NULL
) ON [PRIMARY]
