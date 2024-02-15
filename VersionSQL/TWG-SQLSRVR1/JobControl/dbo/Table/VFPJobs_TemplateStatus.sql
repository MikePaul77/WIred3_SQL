/****** Object:  Table [dbo].[VFPJobs_TemplateStatus]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_TemplateStatus(
	[ShortTransformationName] [varchar](100) NULL,
	[MappingComplete] [bit] NULL,
	[RecID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
