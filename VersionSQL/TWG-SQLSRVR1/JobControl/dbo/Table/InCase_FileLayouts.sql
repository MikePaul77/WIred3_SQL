/****** Object:  Table [dbo].[InCase_FileLayouts]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.InCase_FileLayouts(
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TransformationTemplateId] [int] NULL,
	[ShortFileLayoutName] [nvarchar](100) NULL,
	[Description] [nvarchar](255) NULL,
	[Custom] [bit] NULL,
	[DefaultLayout] [bit] NULL,
	[ModifiedByUser] [nvarchar](50) NULL,
	[VFPIn] [bit] NULL
) ON [PRIMARY]
