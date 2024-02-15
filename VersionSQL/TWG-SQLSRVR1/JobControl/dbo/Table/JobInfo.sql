/****** Object:  Table [dbo].[JobInfo]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobInfo(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[StepID] [int] NULL,
	[InfoName] [varchar](500) NULL,
	[InfoValue] [int] NULL,
 CONSTRAINT [PK_JobInfo] PRIMARY KEY CLUSTERED 
(
	[RecID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
