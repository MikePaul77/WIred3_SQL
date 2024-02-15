/****** Object:  Procedure [dbo].[CopyExtractFiles]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE CopyExtractFiles @JobID int, @Dest varchar(500)
AS
BEGIN
	SET NOCOUNT ON;

	select distinct 'xcopy ' + replace(jslr.LogInformation,'R:\Wired3\ReportsOut\','\\TWGWired\WIRED\redp\output\') + ' C:\Users\mikep\Desktop\RepWork\VFP\' + replace(jslr.LogInformation,'R:\Wired3\ReportsOut\','') CopyCmd
	from JobControl..JobSteps js  
		join JobControl..JobStepLog jsl on jsl.JobStepID = js.StepID and Jsl.LogInfoSource = 'StepRecordCount'
		join JobControl..JobStepLog jslr on jslr.JobID = js.JobID and Jslr.LogInfoSource = 'ReportFileName'
	where js.JobID = @JobID

	union select distinct 'xcopy ' + replace(jslr.LogInformation,'R:\Wired3\ReportsOut\','\\TB12\r$\Wired3\ReportsOut\') + ' C:\Users\mikep\Desktop\RepWork\SQL\' + replace(jslr.LogInformation,'R:\Wired3\ReportsOut\','')
	from JobControl..JobSteps js  
		join JobControl..JobStepLog jsl on jsl.JobStepID = js.StepID and Jsl.LogInfoSource = 'StepRecordCount'
		join JobControl..JobStepLog jslr on jslr.JobID = js.JobID and Jslr.LogInfoSource = 'ReportFileName'
	where js.JobID = @JobID
END
