/****** Object:  Table [dbo].[TransformationTemplates]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.TransformationTemplates(
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[DtsxPackage] [nvarchar](255) NULL,
	[XFormTable] [nvarchar](50) NULL,
	[ShortTransformationName] [nvarchar](255) NULL,
	[Description] [nvarchar](255) NULL,
	[JobStepActionCommand] [varchar](max) NULL,
	[JobStepActionType] [varchar](50) NULL,
	[TransformJoinClause] [varchar](max) NULL,
	[QueryTemplateID] [int] NULL,
	[VFPIn] [bit] NULL,
	[TransformWhereClause] [varchar](max) NULL,
	[Locked] [bit] NULL,
	[InUseUser] [varchar](50) NULL,
	[InUseStamp] [datetime] NULL,
	[MasterXForm] [bit] NULL,
	[SourceMasterXFormID] [int] NULL,
	[UsageGroupType] [int] NULL,
	[CustNamePart] [varchar](100) NULL,
	[AutoName] [varchar](200) NULL,
	[MasterVersion] [int] NULL,
	[SourceMasterXFormVersion] [int] NULL,
 CONSTRAINT [PK_TransformationTemplates] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
