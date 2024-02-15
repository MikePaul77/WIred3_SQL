/****** Object:  Table [dbo].[VFPJobs_HoldNotBlankVFPCodeXFormCols]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_HoldNotBlankVFPCodeXFormCols(
	[ShortTransformationName] [nvarchar](255) NOT NULL,
	[OutName] [varchar](200) NULL,
	[SourceCode] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
