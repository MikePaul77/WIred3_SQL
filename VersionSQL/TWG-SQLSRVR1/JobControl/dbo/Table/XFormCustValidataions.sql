/****** Object:  Table [dbo].[XFormCustValidataions]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.XFormCustValidataions(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[LayoutID] [int] NULL,
	[Disabled] [bit] NULL,
	[CodeDescription] [varchar](500) NULL,
	[Code] [varchar](max) NULL,
	[UseXForm] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
