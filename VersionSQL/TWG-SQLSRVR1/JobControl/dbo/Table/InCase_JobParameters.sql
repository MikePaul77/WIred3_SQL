/****** Object:  Table [dbo].[InCase_JobParameters]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.InCase_JobParameters(
	[ParmRecID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[ParamName] [varchar](500) NULL,
	[ParamValue] [varchar](1000) NULL,
	[StepID] [int] NULL,
	[VFPIn] [bit] NULL
) ON [PRIMARY]
