/****** Object:  Procedure [dbo].[SetJobStepParam]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.SetJobStepParam
	@JobStepID int, @ParamName varchar(100), @ParamValue varchar(500), @LogSourceName varchar(100)
AS
BEGIN
	SET NOCOUNT ON;

	update jp set ParamValue = @ParamValue
		from JobParameters jp
				join Jobs j on jp.JobID = j.JobID
				join JobSteps js on j.JobID = js.JobID
			where js.StepID = @JobStepID
				and ParamName = @ParamName

	if @@ROWCOUNT = 0
		insert JobParameters (JobID, ParamName, ParamValue, StepID)
			select j.JobID, @ParamName, @ParamValue, @JobStepID
				from Jobs j
					join JobSteps js on j.JobID = js.JobID
				where js.StepID = @JobStepID

	declare @LogInfo varchar(500) = 'Param Set: ' + @ParamName + ' = ' + @ParamValue;
		
	exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;
END
