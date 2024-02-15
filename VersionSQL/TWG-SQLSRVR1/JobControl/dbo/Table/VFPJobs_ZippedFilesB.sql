/****** Object:  Table [dbo].[VFPJobs_ZippedFilesB]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_ZippedFilesB(
	[JobID] [int] NOT NULL,
	[JobName] [nvarchar](100) NOT NULL,
	[OUTTABLE] [varchar](max) NULL,
	[ZipFilePath] [varchar](max) NULL,
	[ZipMatch] [varchar](max) NULL,
	[TgtMatch] [varchar](max) NULL,
	[ZipName] [varchar](max) NULL,
	[TgtName] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
