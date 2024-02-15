/****** Object:  TableFunction [dbo].[fnJobFilter_Phase1_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.fnJobFilter_Phase1()
RETURNS TABLE 
AS
RETURN 
(
	select distinct s.jobID
	from (	select j.jobID, j.JobName, j.disabled, j.vfpJobID, vdl.EMailName, vdl.EmailAddress 
				from  JobControl..Jobs j 
					left outer join JobControl..Jobs jt on jt.IsTemplate = 1 and jt.jobid = j.JobTemplateID
					join ( select distinct j.JobID, ql.stateID
								from QueryEditor..QueryLocations ql
									join JobSteps js on js.QueryCriteriaID = ql.QueryID
									join JobControl..Jobs j on j.JobID = js.JobID
									left outer join Lookups..States s on s.Id = ql.StateID
								where ql.stateID > 0
									and s.Code = 'MA') js on js.JobID = j.JobID
					left outer join JobControl..vDistList vdl on vdl.JobID = j.JobID
				where coalesce(j.IsTemplate,0) = 0 
					and jt.type='MTDE'
					and (' '  + replace(j.jobname,'-',' ') like '% Comp %' or ' '  + replace(j.jobname,'-',' ') like '% zzComp %'   )
			) s
		full outer join (
			select j.JOBID, j.JOBDESCRIP, j.Status, CURSTATE, c.PCEMAIL, c.PCFNAME, c.PCLNAME
				from DataLoad..Jobs_jobs j
					left outer join DataLoad..Jobs_customer c on c.CUSTID = j.CUSTID
				where (' '  + replace(JOBDESCRIP,'-',' ') like '% Comp %' or ' '  + replace(JOBDESCRIP,'-',' ') like '% zzComp %'   ) 
						and JOBTYPE = 'MTDE'
						and CURSTATE = 'MA'
		) v on v.JOBID = s.VFPJobID
	where s.JobID is not null
)
