/****** Object:  Table [dbo].[JobModes]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobModes(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Code] [varchar](50) NOT NULL,
	[Description] [varchar](255) NOT NULL,
	[Job] [bit] NULL,
	[JobStep] [bit] NULL,
 CONSTRAINT [PK_JobModes] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
