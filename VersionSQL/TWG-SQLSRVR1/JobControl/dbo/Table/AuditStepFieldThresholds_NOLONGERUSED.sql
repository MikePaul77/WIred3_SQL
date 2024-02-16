/****** Object:  Table [dbo].[AuditStepFieldThresholds_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.AuditStepFieldThresholds_NOLONGERUSED(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[JobStepID] [int] NULL,
	[FieldName] [varchar](50) NULL,
	[FieldSource] [varchar](10) NULL,
	[disabled] [bit] NULL,
	[SuccessPct] [int] NULL,
	[CautionPct] [int] NULL,
	[AbovePct] [bit] NULL,
	[DataCheck] [varchar](50) NULL,
	[SpecificValue] [varchar](50) NULL
) ON [PRIMARY]
