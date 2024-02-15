/****** Object:  Table [dbo].[DeliveryJobSteps]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DeliveryJobSteps(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[DeliveryDestID] [int] NULL,
	[JobStepID] [int] NULL,
	[CreatedStamp] [datetime] NULL,
	[CreatedByUser] [varchar](100) NULL,
	[DisabledStamp] [datetime] NULL,
	[DisabledByUser] [varchar](100) NULL,
	[CreatedNote] [varchar](max) NULL,
	[DisabledNote] [varchar](max) NULL,
	[EmailCC] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
