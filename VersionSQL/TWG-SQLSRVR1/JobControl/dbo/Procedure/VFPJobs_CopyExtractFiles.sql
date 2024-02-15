/****** Object:  Procedure [dbo].[VFPJobs_CopyExtractFiles]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE VFPJobs_CopyExtractFiles @JobID int, @Dest varchar(500)
AS
BEGIN
	SET NOCOUNT ON;

	select distinct 'xcopy ' + replace(jslr.LogInformation,'R:\Wired3\ReportsOut\','\\TB12\r$\Wired3\ReportsOut\') + ' ' + replace(JobControl.dbo.VFPJobs_AltFileName4Compare(jslr.LogInformation, 'SQL'),'\\TB12\r$\Wired3\ReportsOut\',@Dest) + '* /Y' CopyCmd
	from JobControl..JobSteps js  
		join JobControl..JobStepLog jslr on jslr.JobID = js.JobID and Jslr.LogInfoSource = 'ReportFileName'
	where js.JobID = @JobID

	union select distinct 'xcopy ' + replace(jslr.LogInformation,'R:\Wired3\ReportsOut\','\\TWGWired\WIRED\redp\output\') + ' ' + replace(JobControl.dbo.VFPJobs_AltFileName4Compare(jslr.LogInformation, 'VFP'),'\\TWGWired\WIRED\redp\output\',@Dest) + '* /Y'
	from JobControl..JobSteps js  
		join JobControl..JobStepLog jslr on jslr.JobID = js.JobID and Jslr.LogInfoSource = 'ReportFileName'
	where js.JobID = @JobID
END
