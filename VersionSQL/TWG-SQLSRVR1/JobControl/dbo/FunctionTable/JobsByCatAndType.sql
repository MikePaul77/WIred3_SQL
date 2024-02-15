/****** Object:  TableFunction [dbo].[JobsByCatAndType]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION JobsByCatAndType (
    @cat varchar(10),
	@jt varchar(10)
)
RETURNS TABLE
AS
RETURN
    select JobId
	from JobControl..Jobs
	where VFPJobID in (	select JobID
							from JobControl..VFPJobs_ListOfJobs2Import
							where category=@cat
								and JobType=@jt)
		and JobName not like 'zz%';
