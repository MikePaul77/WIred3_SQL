/****** Object:  Table [dbo].[JobTemplateSteps_2BDel]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobTemplateSteps_2BDel(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TemplateID] [int] NOT NULL,
	[StepName] [nvarchar](100) NOT NULL,
	[StepOrder] [int] NULL,
	[StepTypeID] [int] NOT NULL,
	[CreatedStamp] [datetime] NULL,
	[UpdatedStamp] [datetime] NULL,
	[RunModeID] [int] NULL,
	[RequiresSetup] [bit] NULL,
	[QueryTemplateId] [int] NULL,
	[ReportListId] [int] NULL,
	[TransformationId] [int] NULL,
	[FileLayoutId] [int] NULL,
	[SpecialId] [int] NULL,
	[QueryCriteriaId] [int] NULL,
	[DependsOnStep] [int] NULL,
	[StepFileNameAlgorithm] [varchar](max) NULL,
	[FileSourcePath] [varchar](500) NULL,
	[FileSourceExt] [varchar](10) NULL,
	[AllowMultipleFiles] [bit] NULL,
	[StepSubProcessID] [int] NULL,
	[DependsOnStepID] [int] NULL,
	[VFPIn] [bit] NULL,
	[VFP_QueryID] [varchar](50) NULL,
	[VFP_BTCRITID] [varchar](50) NULL,
	[VFP_LayoutID] [varchar](50) NULL,
	[VFP_ReportID] [varchar](50) NULL,
	[DependsOnStepIDs] [varchar](500) NULL,
 CONSTRAINT [PK_JobTemplateSteps] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE dbo.JobTemplateSteps_2BDel ADD  CONSTRAINT [DF_JobTemplateSteps_CreatedStamp]  DEFAULT (getdate()) FOR [CreatedStamp]
