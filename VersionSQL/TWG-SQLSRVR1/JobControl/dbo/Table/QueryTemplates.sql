/****** Object:  Table [dbo].[QueryTemplates]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.QueryTemplates(
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[QueryTypeName_DELETE] [nvarchar](50) NULL,
	[TemplateName] [nvarchar](255) NULL,
	[FieldList] [nvarchar](max) NULL,
	[FromPart] [nvarchar](max) NULL,
	[InitWhereClause] [nvarchar](max) NULL,
	[DtsxPackagePath] [nvarchar](255) NULL,
	[JobStepCommand] [nvarchar](1000) NULL,
	[TestQueryCriteriaId] [uniqueidentifier] NULL,
	[QueryTypeID] [int] NULL,
	[disabled] [bit] NULL,
	[AlternateDB] [varchar](100) NULL,
	[Phase1Source] [varchar](max) NULL,
	[Phase2KeyFieldNames] [varchar](1000) NULL,
	[SourceCompany] [varchar](50) NULL,
	[QueryVersion] [int] NULL,
	[HasNoModiType] [bit] NULL,
	[DataGroupTypeID] [int] NULL,
	[FullLoadCond] [varchar](2000) NULL,
	[MultiLiftKeyFields] [varchar](500) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
