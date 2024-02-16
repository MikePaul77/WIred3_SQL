/****** Object:  Table [dbo].[AuditStepCode_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.AuditStepCode_NOLONGERUSED(
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
	[LastUpdatedBy] [int] NULL,
 CONSTRAINT [PK_AuditStepCode] PRIMARY KEY CLUSTERED 
(
	[AuditID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE dbo.AuditStepCode_NOLONGERUSED ADD  CONSTRAINT [DF_AuditStepCode_DateCreated]  DEFAULT (getdate()) FOR [DateCreated]
