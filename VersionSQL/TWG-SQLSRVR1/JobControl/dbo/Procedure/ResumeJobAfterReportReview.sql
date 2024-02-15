/****** Object:  Procedure [dbo].[ResumeJobAfterReportReview]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 03-21-2019
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE dbo.ResumeJobAfterReportReview
	@UserID int,
	@ReportStepId int
AS
BEGIN
	SET NOCOUNT ON;
	-- Check to see if Automatic Report Review is enabled for this user
	if Exists(	Select UserID 
					from Support..UserSettings
					where UserID=@UserID
						and SettingID=7 
						and SettingValue='1')
		BEGIN
			-- Get the StepID of the Review step, the Step Order and the SQL JobID
			Declare @StepOrder int,
				@StepID int,
				@JobID int,
				@SQLJobID varchar(50),
				@StepName varchar(200)

			Select @JobID=JobID from JobSteps where StepID=@ReportStepID;

			Select @StepID=js.StepID, @StepOrder=js.StepOrder, @SQLJobID=j.SQLJobID
				from JobSteps js
					Join Jobs j on js.JobID=j.JobID
				where js.JobID=@JobID 
					and js.StepTypeID=1102 
					and js.DependsOnStepIDs like '%' + Convert(varchar, @ReportStepID) + '%'

			--Run the Report Review step
			Print 'Executing JobControl..JC_ReportReview ' + convert(varchar,@StepID);
			Exec JobControl..JC_ReportReview @StepID
			Print 'JobControl..JC_ReportReview complete';


			----If the Report Review completes normal, restart the job on the next step
			if exists(Select JobStepID from JobControl..JobStepLog where JobStepID=@StepID and LogInformation='SP Complete')
				BEGIN

					-- Get the next job step after the current Report Review Step
					set @StepOrder = @StepOrder + 1
	
					-- Get the step name from the SQL Job
					Select @StepName=Step_name 
						from msdb.dbo.sysjobsteps 
						where Job_ID=@SQLJobID
							and Step_id=@StepOrder

					-- Resume the job
					Exec msdb.dbo.sp_start_job @job_id=@SQLJobID, @step_name=@StepName;
				END
		END
END
