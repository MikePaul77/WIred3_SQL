/****** Object:  Table [dbo].[ValsOtherCount]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.ValsOtherCount(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[GroupRecID] [int] NULL,
	[ValPass] [bit] NULL,
	[ValLevel] [int] NULL,
	[ValResult] [varchar](2000) NULL,
	[ValType] [varchar](50) NULL,
	[GroupStamp] [datetime] NULL
) ON [PRIMARY]
