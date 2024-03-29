﻿/****** Object:  Table [dbo].[Before4_JobSteps]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.Before4_JobSteps(
	[StepID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NOT NULL,
	[StepName] [nvarchar](100) NOT NULL,
	[StepOrder] [int] NULL,
	[StepTypeID] [int] NOT NULL,
	[RunAtStamp] [datetime] NULL,
	[StartedStamp] [datetime] NULL,
	[CompletedStamp] [datetime] NULL,
	[FailedStamp] [datetime] NULL,
	[SQLJobStepID] [int] NULL,
	[WaitStamp] [datetime] NULL,
	[RunModeID] [int] NULL,
	[RequiresSetup] [bit] NULL,
	[QueryCriteriaID] [int] NULL,
	[ReportListID] [int] NULL,
	[TransformationID] [int] NULL,
	[FileLayoutID] [int] NULL,
	[SpecialID] [int] NULL,
	[DependsOnStep] [int] NULL,
	[StepFileNameAlgorithm] [varchar](max) NULL,
	[FileSourcePath] [varchar](500) NULL,
	[FileSourceExt] [varchar](10) NULL,
	[AllowMultipleFiles] [bit] NULL,
	[StepSubProcessID] [int] NULL,
	[QueryTemplateID] [int] NULL,
	[DependsOnStepID] [int] NULL,
	[VFPIn] [bit] NULL,
	[VFP_QueryID] [varchar](50) NULL,
	[VFP_BTCRITID] [varchar](50) NULL,
	[VFP_LayoutID] [varchar](50) NULL,
	[VFP_ReportID] [varchar](50) NULL,
	[DependsOnStepIDs] [varchar](500) NULL,
	[UpdatedStamp] [datetime] NULL,
	[CreatedStamp] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
