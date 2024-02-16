/****** Object:  Table [dbo].[InCase_QueryMultIDs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.InCase_QueryMultIDs(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[QueryID] [int] NULL,
	[ValueSource] [varchar](50) NULL,
	[ValueID] [int] NULL,
	[Exclude] [bit] NULL,
	[VFPIn] [bit] NULL
) ON [PRIMARY]
