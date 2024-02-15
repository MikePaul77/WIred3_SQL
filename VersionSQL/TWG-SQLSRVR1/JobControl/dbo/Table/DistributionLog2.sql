/****** Object:  Table [dbo].[DistributionLog2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DistributionLog2(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[Email] [varchar](75) NULL,
	[ListID] [int] NULL,
	[DocumentID] [int] NULL,
	[Errors] [bit] NULL,
	[ErrorData] [varchar](max) NULL,
	[DeliveryTime] [datetime] NULL,
	[DistributionDestID] [int] NULL,
 CONSTRAINT [PK_DistributionLog2] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

CREATE NONCLUSTERED INDEX [DistributionLog2_JobIDwDeliveryTime] ON dbo.DistributionLog2
(
	[JobID] ASC
)
INCLUDE([DeliveryTime]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE dbo.DistributionLog2 ADD  CONSTRAINT [DF_DistributionLog2_DeliveryTime]  DEFAULT (getdate()) FOR [DeliveryTime]
