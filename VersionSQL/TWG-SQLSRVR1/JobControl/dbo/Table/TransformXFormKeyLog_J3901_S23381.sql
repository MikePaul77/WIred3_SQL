/****** Object:  Table [dbo].[TransformXFormKeyLog_J3901_S23381]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.TransformXFormKeyLog_J3901_S23381(
	[XF_STATE] [nvarchar](2) NULL,
	[XF_TRANID] [bigint] NULL,
	[XF_MortgageTransactionId] [bigint] NULL,
	[XF_SalesTransactionId] [bigint] NULL,
	[Param_IssueWeek] [varchar](6) NOT NULL,
	[LogStamp] [datetime] NOT NULL
) ON [PRIMARY]
