/****** Object:  Table [dbo].[JobStepsKeyAddrFields]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobStepsKeyAddrFields(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[StepID] [int] NULL,
	[QueryFieldName] [varchar](100) NULL,
	[FieldType] [varchar](50) NULL
) ON [PRIMARY]
