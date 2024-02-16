/****** Object:  Table [dbo].[TransformationTemplates_Prev]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.TransformationTemplates_Prev(
	[Id] [int] NULL,
	[DtsxPackage] [nvarchar](255) NULL,
	[XFormTable] [nvarchar](50) NULL,
	[ShortTransformationName] [nvarchar](255) NULL,
	[Description] [nvarchar](255) NULL,
	[JobStepActionCommand] [varchar](max) NULL,
	[JobStepActionType] [varchar](50) NULL,
	[TransformJoinClause] [varchar](max) NULL,
	[QueryTemplateID] [int] NULL,
	[VFPIn] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
