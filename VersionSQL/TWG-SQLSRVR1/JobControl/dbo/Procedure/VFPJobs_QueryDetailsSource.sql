/****** Object:  Procedure [dbo].[VFPJobs_QueryDetailsSource]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobs_QueryDetailsSource @JobID int, @JobTemplateID int, @VFP_QueryID varchar(20), @QueryID int
AS
BEGIN
	SET NOCOUNT ON;

	create table #Opts (
			JobID int null
			, JobTemplateID int null
			, VFP_QueryID varchar(20) null
			, QueryID int null
			, VFPJobID int null
			, VFPJobTemplateID int null
		)

	insert #Opts (VFP_QueryID
			, JobID
			, JobTemplateID
			, QueryID
			, VFPJobID
			, VFPJobTemplateID )
	select distinct base.VFP_QueryID
				, base.JobID JobID
				, base.JobTemplateID JobTemplateID
				, base.QueryCriteriaId QueryID
				, coalesce(vj.jobID,vjs.JOBID) VFPJobID
				, coalesce(vjt.jobtemplid,vjt.jobtemplid) VFPJobTemplateID
		from (
			select distinct q.VFP_QueryID, q.JobID, q.JobTemplateID, q.QueryCriteriaId
				from (
						select VFP_QueryID, null JobID, TemplateID JobTemplateID, QueryCriteriaId
							from JobControl..JobTemplateSteps 
							where VFPIn = 1 and VFP_QueryID > ''
						union select VFP_QueryID, JobID, null, QueryCriteriaId 
							from JobControl..JobSteps
							where VFPIn = 1 and VFP_QueryID > ''
						) q
					join Dataload..Jobs_MF_query vq on vq.QUERY_ID = q.VFP_QueryID
			) base
		left outer join JobControl..JobSteps js on js.StepTypeID = 21 and js.JobID = base.JobID and js.QueryCriteriaID = base.QueryCriteriaId
		left outer join JobControl..Jobs j on j.JobID = js.JobID
		left outer join JobControl..JobTemplateSteps jts on jts.StepTypeID = 21 and jts.TemplateID = base.JobTemplateID and jts.QueryCriteriaID = base.QueryCriteriaId
		left outer join JobControl..JobTemplates jt on jt.TemplateID = jts.TemplateID
		left outer join DataLoad..Jobs_JOBs vj on vj.JOBDESCRIP = j.JobName
		left outer join DataLoad..Jobs_jobsteps vjs on vjs.steptype = 'Query' and vjs.QUERYID = base.VFP_QueryID
		left outer join DataLoad..Jobs_JOBSTEMPL vjt on vjt.JOBType = jt.Type
		left outer join DataLoad..Jobs_stepstempl vjts on vjts.steptype = 'Query' and vjts.QUERYID = base.VFP_QueryID
		where base.JobID = @JobID
			or base.JobTemplateID = @JobTemplateID
			or base.VFP_QueryID = @VFP_QueryID
			or base.QueryCriteriaId = @QueryID

	select * from #Opts

	select distinct * 
		from JobControl..VFPJobs_Query_Conds qc 
		where QUERY_ID in (select distinct VFP_QueryID from #Opts)

	select 'StateID' ParmName, s.Id ParmVal, j.JobID, null TemplateID
			from DataLoad..Jobs_JOBs j
				join Lookups..States s on j.CURSTATE = s.Code
			where j.curstate > ''
				and j.JobID in (select distinct VFPJobID from #Opts)
	union select 'CountyID' ParmName, c.Id ParmVal,j.JobID, null TemplateID
			from DataLoad..Jobs_JOBs j
				join Lookups..States s on j.CURSTATE = s.Code
				join Lookups..Counties c on c.State = s.Code and c.Code = j.CCODE
			where j.CCODE > ''
				and j.JobID in (select distinct VFPJobID from #Opts)
	union select 'StateID' ParmName, s.Id ParmVal, null JobID, jt.jobtemplid
			from DataLoad..Jobs_JOBSTEMPL jt
				join Lookups..States s on jt.CURSTATE = s.Code
			where jt.curstate > ''
				and jt.jobtemplid in (select distinct VFPJobTemplateID from #Opts)


END
