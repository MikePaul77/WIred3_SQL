/****** Object:  Table [dbo].[DeliveryLog]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DeliveryLog(
	[DeliveryID] [int] IDENTITY(1,1) NOT NULL,
	[DeliveryType] [int] NULL,
	[JobID] [int] NULL,
	[JobStepID] [int] NULL,
	[FileCount] [int] NULL,
	[Errors] [int] NULL,
	[JobSummary] [varchar](max) NULL,
	[JobTime] [datetime] NOT NULL,
	[AddressedBy] [int] NULL,
	[AddressedDate] [datetime] NULL,
	[AddressedComments] [varchar](max) NULL,
	[TestMode] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE dbo.DeliveryLog ADD  CONSTRAINT [DF_DeliveryLog_JobTime]  DEFAULT (getdate()) FOR [JobTime]
