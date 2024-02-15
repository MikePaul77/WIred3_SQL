/****** Object:  Table [dbo].[VFPJobs_ZippedFiles]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_ZippedFiles(
	[RecID] [int] IDENTITY(100,1) NOT NULL,
	[ZipFilePath] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
