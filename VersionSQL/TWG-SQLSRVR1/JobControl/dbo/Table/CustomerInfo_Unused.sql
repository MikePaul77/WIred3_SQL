/****** Object:  Table [dbo].[CustomerInfo_Unused]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.CustomerInfo_Unused(
	[ID] [int] NULL,
	[Company] [varchar](50) NULL,
	[LastName] [varchar](50) NULL,
	[FirstName] [varchar](50) NULL,
	[EMail] [varchar](500) NULL,
	[Address1] [varchar](100) NULL,
	[Address2] [varchar](100) NULL,
	[City] [varchar](100) NULL,
	[State] [nchar](10) NULL,
	[Zip] [varchar](20) NULL,
	[FTPLOGIN] [varchar](max) NULL,
	[FTPPASSWRD] [varchar](max) NULL,
	[FTPPATH] [varchar](max) NULL,
	[ELECADDR] [varchar](max) NULL,
	[QBCUSTID] [varchar](max) NULL,
	[LSREPID] [int] NULL,
	[Phone] [varchar](50) NULL,
	[BEMail] [varchar](500) NULL,
	[BAddress1] [varchar](100) NULL,
	[BAddress2] [varchar](100) NULL,
	[BCity] [varchar](100) NULL,
	[BState] [varchar](10) NULL,
	[BZip] [varchar](20) NULL,
	[BPhone] [varchar](50) NULL,
	[BName] [varchar](100) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
