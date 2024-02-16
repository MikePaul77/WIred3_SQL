/****** Object:  Table [dbo].[TransformationTemplateColumns_InCase_01292024]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.TransformationTemplateColumns_InCase_01292024(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[TransformTemplateID] [int] NULL,
	[OutName] [varchar](200) NULL,
	[SourceCode] [varchar](max) NULL,
	[Disabled] [bit] NULL,
	[VFPSourceCode] [varchar](max) NULL,
	[VFPIn] [bit] NULL,
	[VFPIn_Status] [varchar](100) NULL,
	[LogKeyCol] [bit] NULL,
	[GroupCountCol] [bit] NULL,
	[GroupByCol] [bit] NULL,
	[CalcMaxCol] [bit] NULL,
	[CalcMinCol] [bit] NULL,
	[CalcAvgCol] [bit] NULL,
	[CalcCountCol] [bit] NULL,
	[CalcSumCol] [bit] NULL,
	[CalcMedianCol] [bit] NULL,
	[PivotValCol] [bit] NULL,
	[PivotCalcCol] [varchar](50) NULL,
	[PivotCalcType] [varchar](20) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
