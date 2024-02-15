/****** Object:  Procedure [dbo].[JobLogInsert]    Committed by VersionSQL https://www.versionsql.com ******/

create PROCEDURE dbo.JobLogInsert(@JobID int, @InfoType int, @LogInformation varchar(max), @LogInfoSource varchar(100))
AS
BEGIN
	SET NOCOUNT ON;

	--if @LogInfoSource in ('StepRecordCount', 'StepErrorCount', 'StepFileCount') and @InfoType = 1
	--begin
	--	delete JobStepLog 
	--		where JobStepID = @JobStepID 
	--			and LogInfoSource = @LogInfoSource 
	--			and LogInfoType = @InfoType
	--end

	insert JobStepLog (JobId, LogStamp, LogInformation, LogInfoType, LogInfoSource )
		select @JobID, getdate(), @LogInformation, @InfoType, @LogInfoSource

	insert JobStepLogHist (JobId, LogStamp, LogInformation, LogInfoType, LogInfoSource )
		select @JobID, getdate(), @LogInformation, @InfoType, @LogInfoSource

END
