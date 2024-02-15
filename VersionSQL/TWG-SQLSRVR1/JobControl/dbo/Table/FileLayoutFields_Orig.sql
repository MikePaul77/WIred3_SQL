/****** Object:  Table [dbo].[FileLayoutFields_Orig]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.FileLayoutFields_Orig(
	[Id] [int] NOT NULL,
	[FileLayoutId] [int] NULL,
	[OwnFileLayoutId] [uniqueidentifier] NULL,
	[InputFieldName] [nvarchar](50) NULL,
	[OutputFieldName] [nvarchar](50) NULL,
	[Group] [nvarchar](50) NULL,
	[IsSelected] [bit] NOT NULL,
	[ColumnOrder] [int] NOT NULL,
	[SortOrder] [int] NULL,
	[SortAsc] [bit] NULL,
	[IsUpperCase] [bit] NOT NULL,
	[DataType] [nvarchar](20) NULL,
	[Length] [int] NULL
) ON [PRIMARY]
