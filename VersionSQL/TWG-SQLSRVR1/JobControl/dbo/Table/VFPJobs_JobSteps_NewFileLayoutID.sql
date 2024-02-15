/****** Object:  Table [dbo].[VFPJobs_JobSteps_NewFileLayoutID]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_JobSteps_NewFileLayoutID(
	[VFPJobID] [int] NULL,
	[StepOrder] [int] NULL,
	[ShortFileLayoutName] [nvarchar](100) NULL,
	[CreateDate] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE dbo.VFPJobs_JobSteps_NewFileLayoutID ADD  CONSTRAINT [DF_VFPJobs_JobSteps_NewFileLayoutID_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
