/****** Object:  Table [dbo].[JobParameters]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobParameters(
	[ParmRecID] [bigint] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[ParamName] [varchar](500) NULL,
	[ParamValue] [varchar](1000) NULL,
	[StepID] [int] NULL,
	[VFPIn] [bit] NULL,
 CONSTRAINT [PK_JobParameters] PRIMARY KEY CLUSTERED 
(
	[ParmRecID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [ParamValueStepID] ON dbo.JobParameters
(
	[JobID] ASC,
	[ParamName] ASC
)
INCLUDE([ParamValue],[StepID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
