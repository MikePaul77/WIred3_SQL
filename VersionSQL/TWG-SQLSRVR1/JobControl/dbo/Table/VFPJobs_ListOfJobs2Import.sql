/****** Object:  Table [dbo].[VFPJobs_ListOfJobs2Import]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_ListOfJobs2Import(
	[JobID] [int] NULL,
	[JOBDESCRIP] [varchar](50) NULL,
	[JOBTYPE] [varchar](6) NULL,
	[CATEGORY] [varchar](8) NULL,
	[CUSTID] [int] NULL,
	[COMPANY] [varchar](50) NULL,
	[PCFNAME] [varchar](20) NULL,
	[PCLNAME] [varchar](20) NULL,
	[DTSETUP] [datetime] NULL,
	[DTMODIFIED] [datetime] NULL,
	[LastComplete] [datetime] NULL,
	[ExtractReport] [varchar](22) NULL,
	[Wired3] [varchar](8) NULL,
	[ImportConfirmed] [bit] NULL
) ON [PRIMARY]
