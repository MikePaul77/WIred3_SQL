/****** Object:  Table [dbo].[VFPJobs_FileLayouts_Corrections]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_FileLayouts_Corrections(
	[TransformationTemplateID] [int] NULL,
	[ShortFileLayoutName] [nvarchar](100) NULL,
	[Description] [nvarchar](255) NULL,
	[Custom] [bit] NULL,
	[DefaultLayout] [bit] NULL,
	[ModifiedByUser] [nvarchar](50) NULL,
	[VFPIn] [bit] NULL
) ON [PRIMARY]
