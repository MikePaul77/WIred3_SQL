/****** Object:  Table [dbo].[JobProcessTypes]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobProcessTypes(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Code] [varchar](10) NULL,
	[Description] [varchar](100) NULL,
 CONSTRAINT [PK_JobProcessTypes] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
