/****** Object:  Table [dbo].[TestXFormCustValidation_DELETEFEB102021]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.TestXFormCustValidation_DELETEFEB102021(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[LayoutID] [int] NULL,
	[Disabled] [bit] NULL,
	[CodeDescription] [varchar](500) NULL,
	[Code] [varchar](max) NULL,
	[UseXForm] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
