/****** Object:  Table [dbo].[DeliveryJobs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DeliveryJobs(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[DeliveryDestID] [int] NULL,
	[JobID] [int] NULL,
	[CreatedStamp] [datetime] NULL,
	[CreatedByUser] [varchar](100) NULL,
	[DisabledStamp] [datetime] NULL,
	[DisabledByUser] [varchar](100) NULL,
	[CreatedNote] [varchar](max) NULL,
	[DisabledNote] [varchar](max) NULL,
	[EmailCC] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
