/****** Object:  Table [dbo].[QueryCriteria_2BDel]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.QueryCriteria_2BDel(
	[Id] [int] NOT NULL,
	[QueryCriteriaId] [uniqueidentifier] NULL,
	[ParameterName] [nvarchar](50) NOT NULL,
	[ValueLowerBound] [nvarchar](50) NULL,
	[ValueHigherBound] [nvarchar](50) NULL,
	[State] [nvarchar](2) NULL,
	[Exclude] [bit] NOT NULL,
	[Active] [bit] NULL,
	[IsStatic] [bit] NULL,
	[IsQueryParameter] [bit] NULL,
	[ParameterGroup] [nvarchar](25) NULL,
	[ModificationDate] [datetime] NULL,
	[ModifiedByUser] [nvarchar](255) NULL,
	[IsTemplate] [bit] NOT NULL,
	[IsCommonGroup] [bit] NULL
) ON [PRIMARY]
