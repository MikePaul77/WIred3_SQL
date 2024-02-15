/****** Object:  Table [dbo].[VFPJobs_FinalForceQueryTemplateID]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_FinalForceQueryTemplateID(
	[JobID] [int] NULL,
	[js_QueryTemplateID] [int] NULL,
	[Q_TemplateID] [int] NULL,
	[XF_QueryTemplateID] [int] NULL,
	[VFPJobID] [int] NULL,
	[VFP_BTCRITID] [varchar](50) NULL,
	[ForceTemplateID] [int] NULL,
	[JobName] [nvarchar](100) NULL,
	[StepName] [nvarchar](100) NULL,
	[VFP_QueryID] [varchar](50) NULL
) ON [PRIMARY]
