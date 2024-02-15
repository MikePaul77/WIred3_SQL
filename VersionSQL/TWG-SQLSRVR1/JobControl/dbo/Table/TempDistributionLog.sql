/****** Object:  Table [dbo].[TempDistributionLog]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.TempDistributionLog(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[Destination] [varchar](max) NULL,
	[Documents] [varchar](max) NULL,
	[DeliveryTime] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE dbo.TempDistributionLog ADD  CONSTRAINT [DF_TempDistributionLog_DeliveryTime]  DEFAULT (getdate()) FOR [DeliveryTime]
