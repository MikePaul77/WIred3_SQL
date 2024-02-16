/****** Object:  Table [dbo].[QueryParamTypes_MOVEDTOQEDB]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.QueryParamTypes_MOVEDTOQEDB(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NULL,
	[ReplaceValName] [varchar](20) NULL,
	[ReplaceRangeName] [varchar](20) NULL,
	[AllowPreviousPeriods] [bit] NULL
) ON [PRIMARY]
