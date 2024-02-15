/****** Object:  Procedure [dbo].[MoveJobDistOrder]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE MoveJobDistOrder @FromJobID int, @ToJobID int  
AS
BEGIN
	SET NOCOUNT ON;

	update dls set JobStepID = (select distinct JobStepID 
									from JobControl..DistListJobSteps dls
										join JobControl..JobSteps js on js.StepID = dls.JobStepID
									where js.JobID = @ToJobID)
		 from JobControl..DistListJobSteps dls
			join JobControl..JobSteps js on js.StepID = dls.JobStepID
		where js.JobID = @FromJobID

	update JobControl..Jobs
		set disabled = 1 
		where JobID = @FromJobID

	update JobControl..Jobs
		set JobName = ltrim(rtrim(replace(replace(replace(replace(JobName,'Assessor',''),'Order',''),'Town Clerk',''),'- 05/08/2017-CT',''))) 
						+ case when JobName like '% CT %' then '' else ' CT' end 
		where JobID = @ToJobID

	update OrderControl..Orders 
		set JobID = @ToJobID
		where JobID = @FromJobID

END
