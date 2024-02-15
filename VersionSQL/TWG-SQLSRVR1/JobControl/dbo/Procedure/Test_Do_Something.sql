/****** Object:  Procedure [dbo].[Test_Do_Something]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.Test_Do_Something @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	
	declare @LogSourceName varchar(100) = 'SP JobControl.Test_Do_Something';
	declare @LogInfo varchar(500) = '';
	declare @goodparams bit = 1;

	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

	declare @ForceFailure bit = JobControl.dbo.GetJobStepParamBit(@JobStepID,'ForceFailure')
	if @ForceFailure is null
		set @goodparams = 0
	else
		begin
			set @LogInfo = 'SP Param Get: ForceFailure = ' + convert(varchar(1),@ForceFailure);
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;
		end

	if @goodparams = 1
	begin
		-- Start of working code

			WAITFOR DELAY '00:00:10';

			if @ForceFailure = 1
				begin
--					exec JobControl.dbo.SetJobStepParam @JobStepID, 'ForceFailure', 0, @LogSourceName;
					select * from nonexistanttable
				end
			else
				begin
					select * from JobSteps where StepID = @JobStepID
--					exec JobControl.dbo.SetJobStepParam @JobStepID, 'ForceFailure', 1, @LogSourceName;
				end

		-- End of working code
	end
	else
		begin
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, 'Missing Parameters in JobParameters', @LogSourceName;
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
			THROW 77777, 'Missing Parameters in JobParameters', 1;
		end


	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

END
