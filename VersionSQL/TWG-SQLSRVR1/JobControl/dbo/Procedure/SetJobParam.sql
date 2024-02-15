/****** Object:  Procedure [dbo].[SetJobParam]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.SetJobParam
	@JobID int, @ParamName varchar(100), @ParamValue varchar(500), @LogSourceName varchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	update jp set ParamValue = @ParamValue
		from JobParameters jp
			where jp.JobID = @JobID
				and ParamName = @ParamName

	if @@ROWCOUNT = 0
		insert JobParameters (JobID, ParamName, ParamValue, StepID)
			select @JobID, @ParamName, @ParamValue, null


	declare @LogInfo varchar(500) = 'Param Set: ' + @ParamName + ' = ' + @ParamValue;
		
	exec JobControl.dbo.JobStepLogInsert @JobID, 1, @LogInfo, @LogSourceName;
END
