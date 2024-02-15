/****** Object:  Table [dbo].[VFPJobs_QueryFromClause]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_QueryFromClause(
	[FromClause] [varchar](max) NULL,
	[VFPFuncFromClause] [varchar](max) NULL,
	[QueryTemplateID] [int] NULL,
	[InJobs] [int] NULL,
	[OrigVFPSelect] [varchar](max) NULL,
	[verified] [bit] NULL,
	[RecID] [int] IDENTITY(100,1) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
