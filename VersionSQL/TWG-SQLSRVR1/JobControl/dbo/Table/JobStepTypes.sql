/****** Object:  Table [dbo].[JobStepTypes]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobStepTypes(
	[StepTypeID] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](10) NULL,
	[StepName] [nvarchar](255) NULL,
	[StepDescription] [nvarchar](100) NULL,
	[xJobStepCommand] [nvarchar](max) NULL,
	[Notes] [nvarchar](max) NULL,
	[RequiresSetup] [bit] NULL,
	[SetPostableBitAuto] [bit] NULL,
	[SetPostableBitManual] [bit] NULL,
	[xRunMode] [nchar](1) NULL,
	[IsUserVisible] [bit] NULL,
	[xDtsxPackagePath] [varchar](255) NULL,
	[StepActionType] [varchar](50) NULL,
	[StepActionCommand] [nvarchar](max) NULL,
	[SSIS32bit] [bit] NULL,
	[RunModeID] [int] NULL,
	[ManStdizStep] [bit] NULL,
	[Disabled] [bit] NULL,
	[StepTypeGroupID] [int] NULL,
	[ManualTypeVersion] [int] NULL,
	[SP2ExecComplete] [bit] NULL,
	[DependsOnNumSteps] [int] NULL,
 CONSTRAINT [PK_JobStepTypes] PRIMARY KEY CLUSTERED 
(
	[StepTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE dbo.JobStepTypes ADD  CONSTRAINT [DF_JobStepTypes_SSIS32bit]  DEFAULT ((0)) FOR [SSIS32bit]
