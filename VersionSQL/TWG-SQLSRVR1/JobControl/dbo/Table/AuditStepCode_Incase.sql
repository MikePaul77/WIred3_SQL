/****** Object:  Table [dbo].[AuditStepCode_Incase]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.AuditStepCode_Incase(
	[AuditID] [int] IDENTITY(1,1) NOT NULL,
	[JobStepID] [int] NULL,
	[ResultsOutput] [int] NULL,
	[CodeDescription] [varchar](max) NULL,
	[Code] [varchar](max) NULL,
	[XFormA] [bit] NULL,
	[Disabled] [bit] NULL,
	[DateCreated] [datetime] NULL,
	[CreatedBy] [int] NULL,
	[LastUpdated] [datetime] NULL,
	[LastUpdatedBy] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
