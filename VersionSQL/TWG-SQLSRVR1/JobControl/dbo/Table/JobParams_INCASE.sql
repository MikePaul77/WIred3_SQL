/****** Object:  Table [dbo].[JobParams_INCASE]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobParams_INCASE(
	[ParmRecID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[ParamName] [varchar](500) NULL,
	[ParamValue] [varchar](1000) NULL,
	[StepID] [int] NULL,
	[VFPIn] [bit] NULL
) ON [PRIMARY]
