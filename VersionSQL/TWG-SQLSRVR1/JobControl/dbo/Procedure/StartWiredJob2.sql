/****** Object:  Procedure [dbo].[StartWiredJob2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.StartWiredJob2 @JobID int, @JobLogID int
AS
BEGIN
	SET NOCOUNT ON;

	if @JobID > 0 and @JobLogID > 0
	begin

		declare @RunServer varchar(50)

		select @RunServer = coalesce(jrs.SQLName,jcs.SQLName,@@Servername)
			from JobControl..Jobs j
				join WiredJobControlRun..Servers jcs on jcs.SQLName = @@Servername
				left outer join WiredJobControlRun..Servers jrs on jrs.ID = J.RunSrvrID
			where J.JobID = @JobID

		exec JobControl..AdjustForFullLoad @JobLogID

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

		declare @SQLCmd varchar(Max)

		--exec JobControl..RebuildSQLAgentJob2 @JobID
		set @SQLCmd = '[' + @RunServer + '].WiredJobControlRun.dbo.RebuildSQLAgentJob ' + ltrim(str(@JobID)) + ', ''' + @@Servername + ''''
		print @SQLCmd
		exec(@SQLCmd)

		--select @SQLJobID = sj.Job_ID
		--	FROM JobControl..Jobs j
		--		left outer join msdb.dbo.sysjobs sj  on j.SQLJobID = sj.job_id 
		--	where j.JobID = @JobID;

		print 'Start Updates'

		select @SQLJobID = j.SQLJobID
			FROM JobControl..Jobs j
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

		if 1=2 -- not good here moved back to JobControlStepUpdate and into JobControl..CleanUpPreviousJobRunRemnants2 
		begin
	
			insert JobControl..JobRunBatch (createdStamp) values(getDate())

			select @BatchID = max(BatchID) from JobControl..JobRunBatch

			insert JobControl..JobRunBatchJobs (batchID, jobid) values (@BatchID, @JobID)
    
			print 'Start Cleanup'
			-- This can be removed once we are solid with no more JobControlWork
			exec JobControl..CleanUpPreviousJobRunRemnantsByBatch @BatchID
			print 'Local Cleanup Done'

			set @SQLCmd = '[' + @RunServer + '].WiredJobControlRun.dbo.CleanUpPreviousJobRunRemnantsByBatch ' + ltrim(str(@BatchID)) + ', ''' + @@Servername + ''''
			print @SQLCmd
			exec(@SQLCmd)

			print 'Remote Cleanup Done'

			delete ji
				from JobControl..JobInfo ji
					join JobControl..JobRunBatchJobs bj on ji.JobID = bj.JobID and bj.BatchID = @BatchID
	
			delete jsl
				from JobControl..JobStepLog jsl
					join JobControl..JobRunBatchJobs bj on jsl.JobID = bj.JobID and bj.BatchID = @BatchID

		end

		exec JobControl..SetJobParamsFromQueueParams @JobLogID

		exec JobControl..RefreshAllQueryParams @JobID

		set @JobParameters='';
		exec GetJobParamText @JobID, @JobParameters OUTPUT;  --Get the job's parameters

		--declare @JobStepName nvarchar(200)

		--Select @JobStepName=js.step_name
		--	from msdb.dbo.sysjobsteps js
		--		join msdb.dbo.sysjobs j on j.job_id=js.job_id
		--	where js.job_id=@SQLJobID
		--		and js.step_id=1

		update jl set JobParameters = @JobParameters
			, TestMode = j.TestMode
			, InProduction = j.InProduction
		from JobLog jl
			join Jobs j on j.JobID = jl.JobID
		WHERE ID = @JobLogID

		print '@RunServer: ' + @RunServer
		print '@SQLJobID: ' + @SQLJobID

		--Exec msdb.dbo.sp_start_job @job_id = @SQLJobID, @step_name = @JobStepName
		set @SQLCmd = '[' + @RunServer + '].WiredJobControlRun.dbo.StartSQLAgentJob ''' + @SQLJobID + ''', 1'
		print @SQLCmd
		exec(@SQLCmd)

		update j set LastJobLogID = @JobLogID
			, LastJobParameters = @JobParameters
		from Jobs j
		where j.JobID = @JobID

	end

END
