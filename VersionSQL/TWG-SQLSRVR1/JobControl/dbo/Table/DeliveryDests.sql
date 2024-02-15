/****** Object:  Table [dbo].[DeliveryDests]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DeliveryDests(
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

CREATE NONCLUSTERED INDEX [DeliveryDests_IDDisabledStamp] ON dbo.DeliveryDests
(
	[ID] ASC,
	[DisabledStamp] ASC
)
INCLUDE([DestAddress]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
