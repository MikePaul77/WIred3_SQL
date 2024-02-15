/****** Object:  Table [dbo].[VFP_XFORMShells]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFP_XFORMShells(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Src] [varchar](4000) NULL,
	[XFORM] [varchar](50) NULL,
	[FieldOrder] [int] NULL,
	[FieldName] [varchar](100) NULL,
	[FieldType] [varchar](50) NULL,
	[width] [int] NULL,
	[Dec] [int] NULL
) ON [PRIMARY]
