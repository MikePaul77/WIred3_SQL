/****** Object:  Table [dbo].[TransformationTemplateColumns_Prev]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.TransformationTemplateColumns_Prev(
	[RecID] [int] NULL,
	[TransformTemplateID] [int] NULL,
	[OutName] [varchar](200) NULL,
	[SourceCode] [varchar](max) NULL,
	[Disabled] [bit] NULL,
	[VFPSourceCode] [varchar](max) NULL,
	[VFPIn] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
