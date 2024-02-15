/****** Object:  Table [dbo].[FileLayouts]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.FileLayouts(
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
	[AutoName] [varchar](200) NULL,
	[CommonName] [varchar](100) NULL,
 CONSTRAINT [PK_FileLayouts] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE dbo.FileLayouts ADD  CONSTRAINT [DF_FileLayouts_ModifiedByUser]  DEFAULT (suser_sname()) FOR [ModifiedByUser]
