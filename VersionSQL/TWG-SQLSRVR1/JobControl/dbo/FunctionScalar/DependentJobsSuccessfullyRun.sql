/****** Object:  ScalarFunction [dbo].[DependentJobsSuccessfullyRun]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION DependentJobsSuccessfullyRun
(
	@JobID int
)
RETURNS bit
AS
BEGIN
	DECLARE @Result bit

		Declare @TotalJobs int = 0
		Declare @FailedSinceJobs int
		Declare @CompletedSinceJobs int

		select @TotalJobs = count(*) 
			, @CompletedSinceJobs = sum(case when j2.FailedStamp > j1.CompletedStamp then 1 else 0 end) 
			, @CompletedSinceJobs = sum(case when j2.CompletedStamp > j1.CompletedStamp then 1 else 0 end) 
		from JobControl..JobDepends jd
			join JobControl..Jobs j1 on j1.JobID = jd.JobID
			join JobControl..Jobs j2 on j2.JobID = jd.DependsOnJobID
		where jd.JobID = @JobID


		set @Result = case when @TotalJobs = 0 then 1
							when @TotalJobs = @CompletedSinceJobs and @CompletedSinceJobs = 0 then 1
							else 0 end

	RETURN @Result

END
