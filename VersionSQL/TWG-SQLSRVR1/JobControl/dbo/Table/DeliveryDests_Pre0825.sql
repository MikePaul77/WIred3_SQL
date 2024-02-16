/****** Object:  Table [dbo].[DeliveryDests_Pre0825]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DeliveryDests_Pre0825(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DestType] [varchar](10) NULL,
	[DestAddress] [varchar](500) NULL,
	[FTPUserName] [varchar](100) NULL,
	[FTPPassword] [varchar](50) NULL,
	[FTPPath] [varchar](500) NULL,
	[FTPKey] [varchar](500) NULL,
	[SourceType] [varchar](20) NULL,
	[SourceID] [int] NULL,
	[CreatedStamp] [datetime] NULL,
	[CreatedByUser] [varchar](100) NULL,
	[DisabledStamp] [datetime] NULL,
	[DisabledByUser] [varchar](100) NULL,
	[CreatedNote] [varchar](max) NULL,
	[DisabledNote] [varchar](max) NULL,
	[DestName] [varchar](100) NULL,
	[ContactEmail] [varchar](500) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
