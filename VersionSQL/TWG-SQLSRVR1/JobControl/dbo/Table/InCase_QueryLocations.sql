/****** Object:  Table [dbo].[InCase_QueryLocations]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.InCase_QueryLocations(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[QueryID] [int] NULL,
	[StateID] [int] NULL,
	[ZipCode] [varchar](50) NULL,
	[CountyID] [int] NULL,
	[TownID] [int] NULL,
	[Exclude] [bit] NULL,
	[VFPIn] [bit] NULL
) ON [PRIMARY]
