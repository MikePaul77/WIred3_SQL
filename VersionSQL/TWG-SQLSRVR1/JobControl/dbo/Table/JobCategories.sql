/****** Object:  Table [dbo].[JobCategories]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobCategories(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](10) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[Disabled] [bit] NULL,
	[DefaultOpenFilterCat] [bit] NULL,
 CONSTRAINT [PK_JobCategories] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE dbo.JobCategories ADD  CONSTRAINT [DF_JobCategories_Disabled]  DEFAULT ((0)) FOR [Disabled]
