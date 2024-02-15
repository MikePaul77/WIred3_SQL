/****** Object:  Table [dbo].[DeliveryTypes]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DeliveryTypes(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](200) NULL,
	[Code] [varchar](200) NULL,
	[qbdesc] [varchar](200) NULL,
	[deldesc] [varchar](200) NULL,
	[Disabled] [bit] NULL,
	[ElectronicType] [bit] NULL
) ON [PRIMARY]
