/****** Object:  Table [dbo].[VFPJObs_Map_XForm_VFPCode_WithCompleteXLFARESVS]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJObs_Map_XForm_VFPCode_WithCompleteXLFARESVS(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[TransformTemplateID] [int] NULL,
	[VFPSourceCode] [varchar](max) NULL,
	[SQLCode] [varchar](max) NULL,
	[Confirmed] [bit] NULL,
	[VFPLayoutID] [varchar](100) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
