/****** Object:  Procedure [dbo].[JobFilter_Phase1]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JobFilter_Phase1 @Mode varchar(10), @ShowDisabled bit
AS
BEGIN
	SET NOCOUNT ON;

--- All MTDE Comp Jobs for MA


	select s.jobID SQLJObID, s.JobName SQLJobName, case when s.disabled = 1 then 'Y' else '' end SQLDisabled
			, s.EmailAddress1 SQLEmail1, s.EMailName1 SQLName1
			, s.EmailAddress2 SQLEmail2, s.EMailName2 SQLName2
			, s.EmailAddress3 SQLEmail3, s.EMailName3 SQLName3
			, s.EmailAddress4 SQLEmail4, s.EMailName4 SQLName4
			, s.EmailAddress5 SQLEmail5, s.EMailName5 SQLName5
			, v.JOBID VFPJobID, v.JOBDESCRIP VFPJobDesc, v.Status VFPStatus, v.CURSTATE VFPState , v.PCEMAIL VFPEmail, v.PCFNAME + ' ' + v.PCLNAME VFPName
			, 'update W:\REDP\DBC\JOBS\jobs.dbf set JOBDESCRIP = ''InSQL-'' + JOBDESCRIP where JobID = ' + ltrim(str(v.JOBID)) + ' AND ''InSQL-''$JOBDESCRIP = .F.' VFPNameChgCmd
		into #PhaseTbl
		from (
			select j.jobID, j.JobName, j.disabled, j.vfpJobID
				, vdl1.EMailName EmailName1, vdl1.EmailAddress EmailAddress1
				, vdl2.EMailName EmailName2, vdl2.EmailAddress EmailAddress2
				, vdl3.EMailName EmailName3, vdl3.EmailAddress EmailAddress3
				, vdl4.EMailName EmailName4, vdl4.EmailAddress EmailAddress4
				, vdl5.EMailName EmailName5, vdl5.EmailAddress EmailAddress5
				from  JobControl..Jobs j 
					left outer join JobControl..Jobs jt on jt.IsTemplate = 1 and jt.jobid = j.JobTemplateID
					join ( select distinct j.JobID, ql.stateID
								from QueryEditor..QueryLocations ql
									join JobSteps js on js.QueryCriteriaID = ql.QueryID
									join JobControl..Jobs j on j.JobID = js.JobID
									left outer join Lookups..States s on s.Id = ql.StateID
								where ql.stateID > 0
									and s.Code = 'MA') js on js.JobID = j.JobID

					left outer join JobControl..vDistList vdl1 on vdl1.JobID = j.JobID and vdl1.DLSeq = 1
					left outer join JobControl..vDistList vdl2 on vdl2.JobID = j.JobID and vdl2.DLSeq = 2
					left outer join JobControl..vDistList vdl3 on vdl3.JobID = j.JobID and vdl3.DLSeq = 3
					left outer join JobControl..vDistList vdl4 on vdl4.JobID = j.JobID and vdl4.DLSeq = 4
					left outer join JobControl..vDistList vdl5 on vdl5.JobID = j.JobID and vdl5.DLSeq = 5
				where coalesce(j.IsTemplate,0) = 0 
				--	and isnull(j.disabled,0)=0
					and jt.type='MTDE'
					--and j.jobname like '% MA%'
					and (' '  + replace(j.jobname,'-',' ') like '% Comp %' or ' '  + replace(j.jobname,'-',' ') like '% zzComp %'   )
			) s
		full outer join (
			select j.JOBID, j.JOBDESCRIP, j.Status, CURSTATE, c.PCEMAIL, c.PCFNAME, c.PCLNAME
				from DataLoad..Jobs_jobs j
					left outer join DataLoad..Jobs_customer c on c.CUSTID = j.CUSTID
				where (' '  + replace(JOBDESCRIP,'-',' ') like '% Comp %' or ' '  + replace(JOBDESCRIP,'-',' ') like '% zzComp %'   ) 
						--and JOBDESCRIP like '% MA%'
						and JOBTYPE = 'MTDE'
						--and JOBDESCRIP not like 'zz%'
						and CURSTATE = 'MA'
		) v on v.JOBID = s.VFPJobID
	


 if @Mode = 'IDList'
	select distinct SQLJObID JobID
		from #PhaseTbl
	 Where case when @ShowDisabled = 1 then 1
				when ltrim(SQLDisabled) = '' and @ShowDisabled = 0 then 1 else 0 end = 1
		and SQLJObID is not null

if @Mode = 'Details'
	select *
		from #PhaseTbl
	 Where case when @ShowDisabled = 1 then 1
				when ltrim(SQLDisabled) = '' and @ShowDisabled = 0 then 1 else 0 end = 1
		and SQLJObID is not null
	order by VFPState, SQLJobName 

if @Mode = 'Count'
	select count(*)
		from #PhaseTbl
	 Where case when @ShowDisabled = 1 then 1
				when ltrim(SQLDisabled) = '' and @ShowDisabled = 0 then 1 else 0 end = 1
		and SQLJObID is not null

END
