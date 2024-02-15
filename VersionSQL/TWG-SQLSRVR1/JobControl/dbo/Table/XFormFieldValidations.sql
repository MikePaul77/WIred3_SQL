/****** Object:  Table [dbo].[XFormFieldValidations]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.XFormFieldValidations(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[LayoutID] [int] NULL,
	[XFormFieldID] [int] NULL,
	[LayoutFieldID] [int] NULL,
	[Disabled] [bit] NULL,
	[ValidationType] [varchar](20) NULL,
	[SuccessPct] [int] NULL,
	[CautionPct] [int] NULL,
	[AbovePct] [bit] NULL,
	[DataCheck] [varchar](50) NULL,
	[SpecificValue] [varchar](50) NULL,
	[Note] [varchar](100) NULL
) ON [PRIMARY]
