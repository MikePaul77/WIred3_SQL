/****** Object:  Table [dbo].[JobRecurringTypes]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobRecurringTypes(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Code] [varchar](10) NOT NULL,
	[Description] [varchar](255) NOT NULL,
 CONSTRAINT [PK_JobRecurringTypes] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
