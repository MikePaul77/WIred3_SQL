/****** Object:  Procedure [dbo].[QueueJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE procedure dbo.QueueJob @JobID int, @ParamName varchar(10), @ParamValue varchar(50), @UserName varchar(50) 
AS
BEGIN
	SET NOCOUNT ON;

	Declare @ParamComb varchar(50)
	set @ParamComb = @ParamValue
	if @ParamName > '' and @ParamValue > ''
		set @ParamComb = @ParamName + ':' + @ParamValue

	--Insert into JobControl..JobLog (JobID, RunPriority, SQLJobID, CreateUser, QueueJobParams)
	--select j.JobID, coalesce(JobControl.dbo.GetJobPriority(j.JobID),5)
	--		, sj.Job_ID, coalesce(mu.UserID,0), @ParamComb
	--	FROM JobControl..Jobs j
	--		left outer join msdb.dbo.sysjobs sj  on j.SQLJobID = sj.job_id 
	--		left outer join Support..MasterUser mu on mu.UserName = @UserName
	--	where j.JobID = @JobID;

	update JobControl..JobLog 
		set PrebuildStarted = 0
		where JobID = @JobID
			and QueueJobParams = @ParamComb
			and PrebuildStarted = 1

	Insert into JobControl..JobLog (JobID, RunPriority, CreateUser, QueueJobParams)
	select j.JobID, coalesce(JobControl.dbo.GetJobPriority(j.JobID),3)
			, coalesce(mu.UserID,0), @ParamComb
		FROM JobControl..Jobs j
			left outer join Support..MasterUser mu on mu.UserName = @UserName
		where j.JobID = @JobID;

	update JobControl..JobSteps
        set StartedStamp = null, CompletedStamp = null, FailedStamp = null
			, RunAtStamp = getdate()
			, UpdatedStamp = getdate()
        where JobID = @JobID
			and StartedStamp is not null and (CompletedStamp is not null or FailedStamp is not null)


END
