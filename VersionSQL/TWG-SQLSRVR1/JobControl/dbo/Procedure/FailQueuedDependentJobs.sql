/****** Object:  Procedure [dbo].[FailQueuedDependentJobs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE FailQueuedDependentJobs @FaildJobID int
AS
BEGIN
	SET NOCOUNT ON;

	create table #IDs (JobID int)

	insert #IDs (JobID)
		select distinct jd.JobID 
			from jobcontrol..JobDepends jd
				join jobcontrol..JobLog jl on jl.JobID = jd.JobID
											 and jl.QueueTime > dateadd(HOUR, -24, getdate())
											 and jl.StartTime is null and jl.CancelTime is null and jl.EndTime is null
			where jd.DependsOnJobID = @FaildJobID


    update jl set CancelTime = getdate()
		from JobLog jl
			join #IDs ids on ids.JobID = jl.JobID


	insert JobControl..HoldJobQueue (JobID, HoldStamp)
		select distinct jl.JobID, getdate()
			from JobLog jl
				join #IDs ids on ids.JobID = jl.JobID


END
