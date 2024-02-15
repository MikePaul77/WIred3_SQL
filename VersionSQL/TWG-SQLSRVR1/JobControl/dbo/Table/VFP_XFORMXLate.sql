/****** Object:  Table [dbo].[VFP_XFORMXLate]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFP_XFORMXLate(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[OrigOrd] [int] NULL,
	[XForm] [varchar](50) NULL,
	[src] [varchar](4000) NULL,
	[OutName] [varchar](50) NULL,
	[OutSrc] [varchar](4000) NULL
) ON [PRIMARY]
