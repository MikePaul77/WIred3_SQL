/****** Object:  Table [dbo].[FileLayouts_PreClean06232023]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.FileLayouts_PreClean06232023(
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TransformationTemplateId] [int] NULL,
	[ShortFileLayoutName] [nvarchar](100) NULL,
	[Description] [nvarchar](255) NULL,
	[Custom] [bit] NULL,
	[DefaultLayout] [bit] NULL,
	[ModifiedByUser] [nvarchar](50) NULL,
	[VFPIn] [bit] NULL,
	[ForceOutColsToUppercase] [bit] NULL,
	[FieldMode] [varchar](25) NULL,
	[CustNamePart] [varchar](100) NULL,
	[AutoName] [varchar](200) NULL
) ON [PRIMARY]
