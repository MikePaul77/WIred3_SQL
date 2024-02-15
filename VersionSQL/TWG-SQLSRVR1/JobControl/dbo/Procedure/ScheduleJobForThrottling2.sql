/****** Object:  Procedure [dbo].[ScheduleJobForThrottling2]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 10-13-2018
-- Description:	Schedule a job to run via throttling
-- =============================================
Create PROCEDURE dbo.ScheduleJobForThrottling2 
	@JobID int,
	@RunPriority int,
	@UserName varchar(50),  -- UserName added 3/1/2019 - Mark W.
	@JobStepID int,			-- JobStepID added 6/6/2019 - Mark W.
	@QueueParams varchar(50)
AS
BEGIN
	SET NOCOUNT ON;

	Declare @SQLJobID varchar(36)='', @LJP varchar(25);

	Select @SQLJobID=sj.Job_ID, @LJP=j.LastJobParameters 
		FROM msdb.dbo.sysjobs sj 
			join JobControl..Jobs j on j.SQLJobID = sj.job_id 
		where j.JobID = @JobID;

	Declare @UserID int = 0;
	Select @UserID=UserID from Support..MasterUser where UserName=@UserName

	if @SQLJobID is not null
		Begin
			if @JobStepID=0
				Begin 
					if not exists(	Select ID 
										from JobControl..JobLog
										where StartTime is null
											and CancelTime is null
											and JobID=@JobID
											and SQLJobID=@SQLJobID)
						Insert into JobControl..JobLog(JobID, RunPriority, SQLJobID, CreateUser, QueueJobParams)
							values(@JobID, @RunPriority, @SQLJobID, @UserID, @QueueParams)
				End
			else
				Begin
					if not exists(	Select ID 
										from JobControl..JobLog
										where StartTime is null
											and CancelTime is null
											and JobID=@JobID
											and JobStepID=@JobStepID
											and SQLJobID=@SQLJobID)
						Insert into JobControl..JobLog(JobID, RunPriority, SQLJobID, CreateUser, JobStepID)
							values(@JobID, @RunPriority, @SQLJobID, @UserID, @JobStepID)
				End
		End
END
