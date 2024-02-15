/****** Object:  Procedure [dbo].[JobStepLogInfoUpdate]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JobStepLogInfoUpdate(@JobStepID int, @LogInfoSource varchar(100), @LogInfoTSQL varchar(max))
AS
BEGIN
	SET NOCOUNT ON;

		declare @SQLCmdCount varchar(max)

		set @SQLCmdCount = 'Update jobControl..JobStepLog set LogInformation = (' + @LogInfoTSQL + ')
							Where LogRecID = (Select Max(LogRecId) From JobControl..JobStepLog Where LogInfoSource = ''' + @LogInfoSource + ''' And jobStepId = '+ ltrim(str(@JobStepID)) +')'
		Print @SQLCmdCount;
		exec (@SQLCmdCount)

		set @SQLCmdCount = 'Update jobControl..JobStepLogHist set LogInformation = (' + @LogInfoTSQL + ')
							Where LogRecID = (Select Max(LogRecId) From JobControl..JobStepLogHist Where LogInfoSource = ''' + @LogInfoSource + ''' And jobStepId = '+ ltrim(str(@JobStepID)) +')'
		Print @SQLCmdCount;
		exec (@SQLCmdCount)

		--insert JobStepLogHist (JobId, JobStepID, LogStamp, LogInformation, LogInfoType, LogInfoSource )
		--select JobID, @JobStepID, getdate(), '(' + @LogInfoTSQL + ')', null, @LogInfoSource
		--	from JobSteps 
		--	where StepID = @JobStepID

	if (@LogInfoSource = 'StepRecordCount')
		Update JobControl..JobSteps set StepRecordCount = TRY_CONVERT(int,@LogInfoTSQL) where StepID = @JobStepID;


END
