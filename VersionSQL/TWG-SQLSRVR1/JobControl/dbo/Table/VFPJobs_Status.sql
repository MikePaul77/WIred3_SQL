/****** Object:  Table [dbo].[VFPJobs_Status]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFPJobs_Status(
	[JobID] [int] NULL,
	[Developer] [varchar](50) NULL,
	[AllStepsRun] [bit] NULL,
	[DataIsGood] [bit] NULL,
	[RecordCountMatch] [bit] NULL,
	[ReportWritten] [bit] NULL,
	[FileNamesMatch] [bit] NULL,
	[SpeedInMinutes] [int] NULL,
	[OnHold] [bit] NULL,
	[Grouping] [varchar](100) NULL,
	[Comment] [varchar](max) NULL,
	[LastUpdated] [datetime] NULL,
	[LastUpdatedBy] [varchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

CREATE TRIGGER ChangeStamp 
   ON  dbo.VFPJobs_Status
   AFTER UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    update JobControl..VFPJobs_Status 
		set LastUpdated = getdate(), LastUpdatedBy = SYSTEM_USER
		where JobID in (select JobID from inserted)

END

ALTER TABLE dbo.VFPJobs_Status ENABLE TRIGGER [ChangeStamp]
