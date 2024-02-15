/****** Object:  Table [dbo].[JobRunHold]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobRunHold(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[HoldStart] [datetime] NULL,
	[HoldUser] [int] NULL,
	[ReleaseDate] [datetime] NULL,
	[ReleaseUser] [int] NULL,
	[HoldReason] [varchar](100) NULL,
 CONSTRAINT [PK_JobRunHold] PRIMARY KEY CLUSTERED 
(
	[RecID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
