/****** Object:  Table [dbo].[Before4_TransformationTemplates]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.Before4_TransformationTemplates(
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DtsxPackage] [nvarchar](255) NULL,
	[XFormTable] [nvarchar](50) NULL,
	[ShortTransformationName] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
	[JobStepActionCommand] [varchar](max) NULL,
	[JobStepActionType] [varchar](50) NULL,
	[TransformJoinClause] [varchar](max) NULL,
	[QueryTemplateID] [int] NULL,
	[VFPIn] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
