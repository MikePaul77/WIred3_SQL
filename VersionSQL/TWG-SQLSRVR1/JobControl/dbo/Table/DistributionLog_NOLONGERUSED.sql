﻿/****** Object:  Table [dbo].[DistributionLog_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DistributionLog_NOLONGERUSED(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[Email] [varchar](75) NULL,
	[ListID] [int] NULL,
	[Documents] [varchar](max) NULL,
	[Errors] [bit] NULL,
	[ErrorData] [varchar](max) NULL,
	[DeliveryTime] [datetime] NULL,
	[DistributionDestID] [int] NULL,
 CONSTRAINT [PK__Distribu__3214EC27E7373D3E] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

CREATE NONCLUSTERED INDEX [DistributionLog_JobIDwDocumentsDeliveryTime] ON dbo.DistributionLog_NOLONGERUSED
(
	[JobID] ASC
)
INCLUDE([Documents],[DeliveryTime]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE dbo.DistributionLog_NOLONGERUSED ADD  CONSTRAINT [DF_DistributionLog_DeliveryTime]  DEFAULT (getdate()) FOR [DeliveryTime]
