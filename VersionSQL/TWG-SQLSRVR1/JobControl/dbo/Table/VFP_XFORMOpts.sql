/****** Object:  Table [dbo].[VFP_XFORMOpts]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFP_XFORMOpts(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[XForm] [varchar](50) NULL,
	[Opt] [varchar](50) NULL,
	[Val] [varchar](4000) NULL
) ON [PRIMARY]
