/****** Object:  Table [dbo].[TransformationTemplates_InCase_01292024]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.TransformationTemplates_InCase_01292024(
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
	[SourceMasterXFormVersion] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
