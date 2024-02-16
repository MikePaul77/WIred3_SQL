/****** Object:  Table [dbo].[ControlFileSQL_Unused]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.ControlFileSQL_Unused(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](200) NULL,
	[CtlDataSQL] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
