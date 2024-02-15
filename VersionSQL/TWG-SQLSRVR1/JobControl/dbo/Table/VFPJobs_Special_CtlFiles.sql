/****** Object:  Table [dbo].[VFPJobs_Special_CtlFiles]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_Special_CtlFiles(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[VFP_CallProc] [varchar](2000) NULL,
	[ReportID] [int] NULL,
	[ControlID] [int] NULL,
	[FileExt] [varchar](50) NULL
) ON [PRIMARY]
