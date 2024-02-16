/****** Object:  Table [dbo].[InCase_TransformationTemplateColumns]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.InCase_TransformationTemplateColumns(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[TransformTemplateID] [int] NULL,
	[OutName] [varchar](200) NULL,
	[SourceCode] [varchar](max) NULL,
	[Disabled] [bit] NULL,
	[VFPSourceCode] [varchar](max) NULL,
	[VFPIn] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
