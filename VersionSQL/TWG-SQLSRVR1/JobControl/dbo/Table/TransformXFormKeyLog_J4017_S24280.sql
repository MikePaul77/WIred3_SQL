/****** Object:  Table [dbo].[TransformXFormKeyLog_J4017_S24280]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.TransformXFormKeyLog_J4017_S24280(
	[XF_STATE] [nvarchar](2) NULL,
	[XF_TRANID] [bigint] NULL,
	[XF_MortgageTransactionId] [bigint] NULL,
	[Param_CalPeriod] [varchar](1) NOT NULL,
	[LogStamp] [datetime] NOT NULL
) ON [PRIMARY]
