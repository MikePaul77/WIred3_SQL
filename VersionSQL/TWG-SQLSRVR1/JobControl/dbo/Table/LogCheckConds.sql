/****** Object:  Table [dbo].[LogCheckConds]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.LogCheckConds(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[JobStepID] [int] NULL,
	[Disabled] [bit] NULL,
	[CondDescription] [varchar](100) NULL,
	[CondLogic] [varchar](max) NULL,
	[DetailType] [varchar](20) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
