/****** Object:  Procedure [dbo].[StartWiredJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.StartWiredJob @JobID int, @JobLogID int
AS
BEGIN
	SET NOCOUNT ON;

	if @JobID > 0 and @JobLogID > 0
	begin

		update jl set StartTime=getdate()
				, PrebuildStarted = case when js.JobID > 0 then 1 else 0 end
			from JobLog jl
				left outer join (select distinct js.jobID
								from JobControl..JobSteps js 
									join JobControl..Jobs j on j.JobID=js.JobID
									join JobControl..JobLog jl on jl.JobID = js.JobID
											and jl.QueueTime > dateadd(HOUR, -24, getdate())
								where isnull(js.PrebuildQuery,0) = 1
									and coalesce(j.disabled,0) = 0 ) js on js.JobID = jl.JobID
			WHERE jl.ID = @JobLogID

		declare @SQLJobID varchar(36)

		exec JobControl..RebuildSQLAgentJob @JobID

		select @SQLJobID = sj.Job_ID
			FROM JobControl..Jobs j
				left outer join msdb.dbo.sysjobs sj  on j.SQLJobID = sj.job_id 
			where j.JobID = @JobID;

		update jl set SQLJobID = @SQLJobID
			from JobControl..JobLog jl
			where jl.ID = @JobLogID
				and jl.SQLJobID is null

		update JobControl..Jobs 
			set LastRunFullJob = 1 
				, StartedStamp = null, CompletedStamp = null, FailedStamp = null, RunAtStamp = getdate()
			where JobID = @JobID

		update JobControl..JobSteps
			set StartedStamp = null, CompletedStamp = null, FailedStamp = null
				, RunAtStamp = getdate()
				, UpdatedStamp = getdate()
			where JobID = @JobID


		Declare @BatchID int
		declare @JobParameters varchar(25)
	
		insert JobControl..JobRunBatch (createdStamp) values(getDate())

		select @BatchID = max(BatchID) from JobControl..JobRunBatch

		insert JobControl..JobRunBatchJobs (batchID, jobid) values (@BatchID, @JobID)
    
		exec JobControl..CleanUpPreviousJobRunRemnantsByBatch @BatchID

		exec JobControl..SetJobParamsFromQueueParams @JobLogID

		exec JobControl..RefreshAllQueryParams @JobID

		set @JobParameters='';
		exec GetJobParamText @JobID, @JobParameters OUTPUT;  --Get the job's parameters

		declare @JobStepName nvarchar(200)

		Select @JobStepName=js.step_name
			from msdb.dbo.sysjobsteps js
				join msdb.dbo.sysjobs j on j.job_id=js.job_id
			where js.job_id=@SQLJobID
				and js.step_id=1

		update jl set JobParameters = @JobParameters
			, TestMode = j.TestMode
			, InProduction = j.InProduction
		from JobLog jl
			join Jobs j on j.JobID = jl.JobID
		WHERE ID = @JobLogID

		Exec msdb.dbo.sp_start_job @job_id = @SQLJobID, @step_name = @JobStepName

		update j set LastJobLogID = @JobLogID
			, LastJobParameters = @JobParameters
		from Jobs j
		where j.JobID = @JobID

	end

END
