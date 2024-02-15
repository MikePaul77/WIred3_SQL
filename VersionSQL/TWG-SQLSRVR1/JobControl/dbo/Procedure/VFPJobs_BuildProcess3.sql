/****** Object:  Procedure [dbo].[VFPJobs_BuildProcess3]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobs_BuildProcess3
AS
BEGIN
	SET NOCOUNT ON;

	declare @cnt int

	truncate table JobControl..VFPJobs_HoldNotBlankVFPCodeXFormCols
		insert JobControl..VFPJobs_HoldNotBlankVFPCodeXFormCols (ShortTransformationName, OutName, SourceCode)
		select t.ShortTransformationName, tc.OutName, tc.SourceCode
			from JobControl..TransformationTemplates t
				join JobControl..TransformationTemplateColumns tc on t.Id = tc.TransformTemplateID
			where tc.VFPIn = 1 and tc.VFPSourceCode = '' and coalesce(tc.SourceCode,'') > ''

	-- Read VFP Queries to get or update  

		update JobControl..VFPJobs_QueryFromClause set InJobs = 0

		insert JobControl..VFPJobs_QueryFromClause (FromClause, OrigVFPSelect, InJobs)
		select x.FromClause, x.OrigVFPSelect, x.InJobs from (
			select Support.FuncLib.StringFromTo(SELECTEXP1,'from','where',1) FromClause
					, case when Support.FuncLib.StringFromTo(SELECTEXP1,'from','where',1) = '' then SELECTEXP1 else '' end OrigVFPSelect
					, count(distinct JobID) InJobs
				from Dataload..Jobs_MF_query jsq
					join Dataload..Jobs_jobsteps js on js.QUERYID = jsq.QUERY_ID and js.STEPTYPE = 'QUERY'
				group by Support.FuncLib.StringFromTo(SELECTEXP1,'from','where',1)
					, case when Support.FuncLib.StringFromTo(SELECTEXP1,'from','where',1) = '' then SELECTEXP1 else '' end
			) x
				left outer join JobControl..VFPJobs_QueryFromClause fc on fc.FromClause = x.FromClause and fc.OrigVFPSelect = x.OrigVFPSelect
		where fc.InJobs is null

		update fc set InJobs = x.InJobs
		 from (
		select Support.FuncLib.StringFromTo(SELECTEXP1,'from','where',1) FromClause
				, case when Support.FuncLib.StringFromTo(SELECTEXP1,'from','where',1) = '' then SELECTEXP1 else '' end OrigVFPSelect
				, count(distinct JobID) InJobs
			from Dataload..Jobs_MF_query jsq
				join Dataload..Jobs_jobsteps js on js.QUERYID = jsq.QUERY_ID and js.STEPTYPE = 'QUERY'
			group by Support.FuncLib.StringFromTo(SELECTEXP1,'from','where',1)
				, case when Support.FuncLib.StringFromTo(SELECTEXP1,'from','where',1) = '' then SELECTEXP1 else '' end
		) x
			left outer join JobControl..VFPJobs_QueryFromClause fc on fc.FromClause = x.FromClause and fc.OrigVFPSelect = x.OrigVFPSelect
		where fc.InJobs is not null

		update fc set VFPFuncFromClause = Support.FuncLib.StringFromTo(f.FUNCTIONCODE,'from','where',1)
			from JobControl..VFPJobs_QueryFromClause fc
				join Dataload..Jobs_MF_allfunctions f on fc.OrigVFPSelect like '%' + f.FUNNAME + '(%'
			where fc.OrigVFPSelect > ''

		update fc1 set QueryTemplateID = fc2.QueryTemplateID
			from JobControl..VFPJobs_QueryFromClause fc1
				join JobControl..VFPJobs_QueryFromClause fc2 on fc1.FromClause = fc2.FromClause and fc1.OrigVFPSelect = fc2.OrigVFPSelect and fc2.QueryTemplateID is not null
			where fc1.QueryTemplateID is null

-- Clear previous VFP Loaded attempts

	truncate table JobControl..CustomerInfo
	insert JobControl..CustomerInfo (ID, Company, LastName, FirstName, EMail, Address1, Address2, City, State, Zip)
	select custID, Company, PCLNAME, PCFName, PCEMAIL, PCADDRESS1, PCADDRESS2, PCCITY, PCSTATE, PCZIP + case when PCZIPEXT > '' then '-' + PCZIPEXT else '' end
		from [DataLoad].[dbo].[Jobs_customer]

	declare @Tbl varchar(100), @IdentCol varchar(50), @Seq int
	declare @cmd varchar(max)
	declare @UJobID uniqueidentifier

	DECLARE curA CURSOR FOR
		select SQLJobID
			from JobControl..Jobs
			where VFPIn = 1 and SQLJobID is not null

     OPEN curA

     FETCH NEXT FROM curA into @UJobID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

	      EXEC msdb..sp_delete_job @job_id = @UJobID
	
          FETCH NEXT FROM curA into @UJobID
     END
     CLOSE curA
     DEALLOCATE curA

	DECLARE curA CURSOR FOR
		select 'JobControl..TransformationTemplateColumns' Tbl, 'RecID' IdentCol, 10 Seq
		union select 'JobControl..TransformationTemplates', 'ID', 20
		union select 'JobControl..FileLayoutFields','RecID', 30
		union select 'JobControl..FileLayouts', 'Id', 40
		union select 'JobControl..JobStepLog', 'LogRecID', 50
		union select 'JobControl..JobInfo', 'RecID', 50
		union select 'JobControl..JobParameters', 'ParmRecID', 55
		union select 'JobControl..JobSteps', 'StepID', 60
		union select 'JobControl..Jobs', 'JobID', 70
		union select 'JobControl..JobTemplateSteps', 'ID', 80
		union select 'JobControl..JobTemplates', 'TemplateID', 90
		union select 'QueryEditor..QueryLocations', 'ID', 100
		union select 'QueryEditor..QueryMultIDs', 'ID', 110
		union select 'QueryEditor..QueryRanges', 'ID', 120
		union select 'QueryEditor..Queries', 'ID', 130
		order by 3

     OPEN curA

     FETCH NEXT FROM curA into @Tbl, @IdentCol, @Seq
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
		if @Tbl in ('JobControl..JobStepLog','JobControl..JobParameters','JobControl..JobInfo')
			begin
				set @cmd = 'delete ' + @Tbl + ' where JobID in (select JobID from JobControl..Jobs where VFPIn = 1)'
				print @cmd
				exec(@cmd)
			end

		if @Tbl not in ('JobControl..JobStepLog','JobControl..JobInfo')
			begin
				set @cmd = 'delete ' + @Tbl + ' where VFPIn = 1'
				print @cmd
				exec(@cmd)

			end

		set @cmd = 'declare @MaxID int; select @MaxID = coalesce(max(' + @IdentCol + '),100) from ' + @Tbl + '; DBCC CHECKIDENT (''' + @Tbl + ''', RESEED, @MaxID);'
		exec(@cmd)

          FETCH NEXT FROM curA into @Tbl, @IdentCol, @Seq
     END
     CLOSE curA
     DEALLOCATE curA


	select j.JobID into #JobsToDo
		from DataLoad..Jobs_Jobs j
			join (	select j.JOBID, j.JOBTYPE, j.CATEGORY, j.STATUS, j.DTCOMPLETE
						, jc.Code, jc.Description
					from DataLoad..Jobs_Jobs j
						join JobControl..JobCategories jc on jc.Code = j.CATEGORY
						join (
								select q.JOBID
									from (select distinct JOBID from DataLoad..Jobs_jobsteps where steptype = 'Query') q
									 join (select distinct JOBID from DataLoad..Jobs_jobsteps where steptype = 'xform') x on q.JOBID = x.JOBID
									 join (select distinct JOBID from DataLoad..Jobs_jobsteps where steptype = 'REPORTER') r on r.JOBID = q.JOBID
							) QXR on QXR.JOBID = j.JOBID
					where j.STATUS <> 'S'
						and j.DTCOMPLETE >= '1/1/2018'
				) bj on bj.jobID = j.JobID
		--where j.JobID in (145645,141451, 28835)

	truncate table JobControl..VFPJobs_Params

Print '=========================  Creating Jobs and Templates from DataLoad..Jobs_Jobs ================================'

	 declare @NewJobID int, @NewJobTempID int
     declare @JobID int, @JobType varchar(50)

     DECLARE curA CURSOR FOR
		select j.JobID, j.JOBTYPE
			from DataLoad..Jobs_Jobs j
			where j.JobID in (select JobID from #JobsToDo)

     OPEN curA

     FETCH NEXT FROM curA into @JobID, @JobType
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

			print ltrim(str(@JobID)) + ' ' + @JobType

			declare @TemplateExists bit

			select @TemplateExists = case when count(*) > 0 then 1 else 0 end
					, @NewJobTempID = max(wjt.TemplateID)
				from DataLoad..Jobs_JOBSTEMPL jt 
						join JobControl..JobTemplates wjt on wjt.Description = jt.jobdescrip and wjt.VFPIn = 1
					where jt.jobType = @JobType
			
			if @TemplateExists = 0
				begin

	 				insert JobControl..JobTemplates (VFPIn, Type, Description, CategoryID, RunModeID, RecurringTypeID, ProcessTypeID)
						select 1, jt.jobtype, jt.jobdescrip, jc.ID, jm.ID, jrt.ID, 0
							from DataLoad..Jobs_JOBSTEMPL jt 
								join JobControl..JobCategories jc on jc.Code = jt.category
								join JobControl..JobModes jm on jm.Code = jt.jobrunmode
								join JobControl..JobRecurringTypes jrt on jrt.Code = jt.recurring
							where jt.jobType = @JobType
		
					select @NewJobTempID = max(TemplateID) from JobControl..JobTemplates where VFPIn = 1


					--TBD?  RequiresSetup, SpecialId
					--      FileSourcePath, FileSourceExt, AllowMultipleFiles
					--		StepSubProcessID

					insert JobControl..JobTemplateSteps (VFPIn, TemplateID, StepName, StepOrder, StepTypeID, RunModeID
															, StepFileNameAlgorithm
															,VFP_QueryID, VFP_BTCRITID, VFP_LayoutID, VFP_ReportID)
					 select 1, @NewJobTempID, jts.STEPDESC, ROW_NUMBER() OVER(ORDER BY jts.STEPID), coalesce(jst.StepTypeID,0), jm.ID
								, jts.filealgorithm
								, QueryID, BTCRITID, LayoutID, ReportID
						from DataLoad..Jobs_JOBSTEMPL jt
								join DataLoad..Jobs_stepstempl jts on jts.JOBTEMPLID = jt.jobtemplid
								left outer join VFPJobs_Map_StepTypes mst on mst.VFPStepType = jts.STEPTYPE
								left outer join JobControl..JobStepTypes jst on jst.Code = mst.Code
								left outer join JobControl..JobModes jm on jm.Code = jts.STEPRUNMODE
								left outer join JobControl..JobTemplates wjt on wjt.Description = jt.jobdescrip and wjt.VFPIn = 1
							where jt.jobType = @JobType
						order by jts.STEPID

					update js set ReportListID = rm.ReportID
						from JobControl..JobTemplateSteps js
							join JobControl..VFPJobs_Map_Reports rm on rm.VFP_Report_ID = js.VFP_ReportID and coalesce(ReportID,0) > 0
						where js.VFPIn = 1 and js.StepTypeID = 22
							and js.TemplateID = @NewJobTempID

					update jsX set DependsOnStepIDs = jsPr.ID
							from JobControl..JobTemplateSteps jsX 
								join JobControl..JobTemplateSteps jsPr on jsPr.StepOrder = (jsX.StepOrder - 1) and jsPr.TemplateID = jsX.TemplateID
							where jsX.VFPIn = 1
								and jsX.StepTypeID in (29,22,1)	-- 29 Xfrom, 22 Report, 1 Append
								and jsx.TemplateID = @NewJobTempID

					declare @LastTemplateID int = 0
					declare @NewFilePat varchar(2000)
					declare @TemplateID int, @StepID int, @StepTypeID int, @StepFileNameAlgorithm varchar(2000), @OutFileName varchar(2000), @ReportListID int, @Extension varchar(10)

					DECLARE curB CURSOR FOR
 						select x.ID, x.TemplateID, x.StepTypeID, x.StepFileNameAlgorithm
								--, replace(replace(x.OutPath,'''',''),'\redp\output\','R:\Wired3\ReportsOut\') OutPath
								--, x.OutFileName
								, ReportListID
								, Extension
						from (
							select js.ID, js.TemplateID, js.StepOrder, js.StepTypeID
								, js.StepFileNameAlgorithm
								--, substring(ltrim(rtrim(js.StepFileNameAlgorithm)),1,len(ltrim(rtrim(js.StepFileNameAlgorithm))) - charindex('\',reverse(ltrim(rtrim(js.StepFileNameAlgorithm)))) + 1) OutPath
								--, substring(ltrim(rtrim(js.StepFileNameAlgorithm)),len(ltrim(rtrim(js.StepFileNameAlgorithm))) - charindex('\',reverse(ltrim(rtrim(js.StepFileNameAlgorithm)))) + 2,2000) OutFileName
								, js.ReportListID
								, r.Extension
							from JobControl..JobTemplateSteps js
								left outer join JobControl..Reports r on r.Id = js.ReportListId
							where js.VFPIn = 1
							) x
						order by x.TemplateID, x.StepOrder

					 OPEN curB

					 FETCH NEXT FROM curB into @StepID, @TemplateID, @StepTypeID, @StepFileNameAlgorithm, @ReportListID, @Extension
					 WHILE (@@FETCH_STATUS <> -1)
					 BEGIN
							set @StepFileNameAlgorithm = JobControl.dbo.VFPImport_StepFileNameCleanUp(@StepFileNameAlgorithm) 
							--set @StepFileNameAlgorithm = replace(@StepFileNameAlgorithm,'oJC.issweek','!IW6!')
							--set @StepFileNameAlgorithm = replace(@StepFileNameAlgorithm,'oJC.curstate','!ST!')

							--set @StepFileNameAlgorithm = replace(@StepFileNameAlgorithm,'''','')
							--set @StepFileNameAlgorithm = replace(@StepFileNameAlgorithm,'+','')
							--set @StepFileNameAlgorithm = replace(@StepFileNameAlgorithm,' ','')

							if ltrim(rtrim(@StepFileNameAlgorithm)) > ''
								begin
									set @NewFilePat = @StepFileNameAlgorithm
									--update JobControl..JobTemplateSteps set StepFileNameAlgorithm = '' where ID = @StepID
								end
							else
								begin
									if @LastTemplateID = @TemplateID and @ReportListID is not null
										update JobControl..JobTemplateSteps set StepFileNameAlgorithm = @NewFilePat + '.' + @Extension where ID = @StepID
								end

							set @LastTemplateID = @TemplateID
						  FETCH NEXT FROM curB into @StepID, @TemplateID, @StepTypeID, @StepFileNameAlgorithm, @ReportListID, @Extension
					 END
					 CLOSE curB
					 DEALLOCATE curB

					select @cnt = count(*) from DataLoad..Jobs_JOBs where JobID = @JobID and ISSWEEK > ''
					update JobControl..JobTemplates set PromptIssueWeek = case when @cnt = 0 then 0 else 1 end where TemplateID = @NewJobTempID

					insert JobControl..VFPJobs_Params (JobTemplateID, ParamName, ParamVal)
						select @NewJobTempID, 'StateID' ParmName, s.Id ParmVal
								from DataLoad..Jobs_JOBSTEMPL jt
									join Lookups..States s on jt.CURSTATE = s.Code
								where jt.curstate > ''
									and jt.jobType = @JobType

				end

---###############################################

	 				insert JobControl..Jobs (VFPIn, JobName, CategoryID, ModeID, RecurringTypeID, ProcessTypeID, JobTemplateID, VFPJobID, PromptIssueWeek)
						select 1, j.jobdescrip, jc.ID, jm.ID, jrt.ID, 0, @NewJobTempID, @JobID, case when j.ISSWEEK > '' then 1 else 0 end
							from DataLoad..Jobs_JOBS j 
								join JobControl..JobCategories jc on jc.Code = j.category
								join JobControl..JobModes jm on jm.Code = j.jobrunmode
								join JobControl..JobRecurringTypes jrt on jrt.Code = j.recurring
							where j.JOBID = @JobID


					select @NewJobID = max(JobID) from JobControl..Jobs where VFPIn = 1

		
					--TBD?  RequiresSetup, SpecialId
					--      FileSourcePath, FileSourceExt, AllowMultipleFiles
					--		StepSubProcessID

					insert JobControl..JobSteps (VFPIn, JobID, StepName, StepOrder, StepTypeID, RunModeID
															, StepFileNameAlgorithm
															,VFP_QueryID, VFP_BTCRITID, VFP_LayoutID, VFP_ReportID)
					 select 1, @NewJobID, js.STEPDESC, ROW_NUMBER() OVER(ORDER BY js.STEPID), coalesce(jst.StepTypeID,0), jm.ID
								, js.filealgorithm
								, QueryID, BTCRITID, LayoutID, ReportID
						from DataLoad..Jobs_JOBS j
								join DataLoad..Jobs_jobsteps js on js.JOBID = j.jobid
								left outer join VFPJobs_Map_StepTypes mst on mst.VFPStepType = js.STEPTYPE
								left outer join JobControl..JobStepTypes jst on jst.Code = mst.Code
								left outer join JobControl..JobModes jm on jm.Code = js.STEPRUNMODE
								left outer join JobControl..JobTemplates wjt on wjt.Description = j.jobdescrip and wjt.VFPIn = 1
							where j.JOBID = @JobID
								and js.ReportID <> 'nullmailer'
						order by js.STEPID

					update js set ReportListID = rm.ReportID
						from JobControl..JobSteps js
							join JobControl..VFPJobs_Map_Reports rm on rm.VFP_Report_ID = js.VFP_ReportID and coalesce(ReportID,0) > 0
						where js.VFPIn = 1 and js.StepTypeID = 22
							and js.JobID = @NewJobID

					update jsX set DependsOnStepIDs = jsPr.StepID
							from JobControl..JobSteps jsX 
								join JobControl..JobSteps jsPr on jsPr.StepOrder = (jsX.StepOrder - 1) and jsPr.JobID = jsX.JobID
							where jsX.VFPIn = 1
								and jsX.StepTypeID in (29,22,1)	-- 29 Xfrom, 22 Report, 1 Append
								and jsx.JobID = @NewJobID


					insert JobControl..VFPJobs_Params (JobID, ParamName, ParamVal)
						select @NewJobID, 'StateID' ParmName, ltrim(str(s.Id)) ParmVal
								from DataLoad..Jobs_JOBs j
									join Lookups..States s on j.CURSTATE = s.Code
								where j.curstate > ''
									and  j.jobID = @JobID
						union select @NewJobID, 'CountyID' ParmName, ltrim(str(c.Id)) ParmVal
								from DataLoad..Jobs_JOBs j
									join Lookups..States s on j.CURSTATE = s.Code
									join Lookups..Counties c on c.State = s.Code and c.Code = j.CCODE
								where j.CCODE > ''
									and j.jobID = @JobID
						union select @NewJobID, 'IssueWeek' ParmName, j.ISSWEEK
								from DataLoad..Jobs_JOBs j
								where j.ISSWEEK > ''
									and j.jobID = @JobID
						union select @NewJobID, 'LowWeek' ParmName, j.LowWEEK
								from DataLoad..Jobs_JOBs j
								where j.LowWEEK > ''
									and j.jobID = @JobID
						union select @NewJobID, 'HighWeek' ParmName, j.HighWEEK
								from DataLoad..Jobs_JOBs j
								where j.HighWEEK > ''
									and j.jobID = @JobID
						union select @NewJobID, 'LowModDate' ParmName, convert(varchar(50),j.lomodidate,101)
								from DataLoad..Jobs_JOBs j
								where j.lomodidate is not null 
									and j.jobID = @JobID
						union select @NewJobID, 'HiModDate' ParmName, convert(varchar(50),j.himodidate,101)
								from DataLoad..Jobs_JOBs j
								where j.himodidate is not null 
									and j.jobID = @JobID

---###############################################

          FETCH NEXT FROM curA into @JobID, @JobType
     END
     CLOSE curA
     DEALLOCATE curA

					declare @LastJobID int = 0

					DECLARE curB CURSOR FOR
 						select x.StepID, x.JobID, x.StepTypeID, x.StepFileNameAlgorithm
								--, replace(replace(x.OutPath,'''',''),'\redp\output\','R:\Wired3\ReportsOut\') OutPath
								--, replace(replace(replace(replace(replace(replace(x.OutFileName,'right(oJC.issweek,4)','!IW4!'),'oJC.issweek','!IW6!'),'oJC.curstate','!ST!'),'''',''),'+',''),' ','') OutFileName
								, ReportListID
								, Extension
						from (
							select js.StepID, js.JobID, js.StepOrder, js.StepTypeID
								, js.StepFileNameAlgorithm
								--, substring(ltrim(rtrim(js.StepFileNameAlgorithm)),1,len(ltrim(rtrim(js.StepFileNameAlgorithm))) - charindex('\',reverse(ltrim(rtrim(js.StepFileNameAlgorithm)))) + 1) OutPath
								--, substring(ltrim(rtrim(js.StepFileNameAlgorithm)),len(ltrim(rtrim(js.StepFileNameAlgorithm))) - charindex('\',reverse(ltrim(rtrim(js.StepFileNameAlgorithm)))) + 2,2000) OutFileName
								, js.ReportListID
								, r.Extension
							from JobControl..JobSteps js
								left outer join JobControl..Reports r on r.Id = js.ReportListId
							where js.VFPIn = 1
							) x
						order by x.JobID, x.StepOrder

					 OPEN curB

					 FETCH NEXT FROM curB into @StepID, @JobID, @StepTypeID, @StepFileNameAlgorithm, @ReportListID, @Extension
					 WHILE (@@FETCH_STATUS <> -1)
					 BEGIN
							set @StepFileNameAlgorithm = JobControl.dbo.VFPImport_StepFileNameCleanUp(@StepFileNameAlgorithm) 

							if ltrim(rtrim(@StepFileNameAlgorithm)) > ''
								begin
									set @NewFilePat = @StepFileNameAlgorithm
									update JobControl..JobSteps set StepFileNameAlgorithm = '' where StepID = @StepID
								end
							else
								begin
									if @LastJobID = @JobID and @ReportListID is not null
										update JobControl..JobSteps set StepFileNameAlgorithm = @NewFilePat + '.' + @Extension where StepID = @StepID
								end

							set @LastJobID = @JobID
						  FETCH NEXT FROM curB into @StepID, @JobID, @StepTypeID, @StepFileNameAlgorithm, @ReportListID, @Extension
					 END
					 CLOSE curB
					 DEALLOCATE curB

					select @cnt = count(*) from DataLoad..Jobs_JOBs where JobID = @JobID and ISSWEEK > ''
					update JobControl..Jobs set PromptIssueWeek = case when @cnt = 0 then 0 else 1 end where JobID = @NewJobID

	insert VFPJobs_TemplateStatus (ShortTransformationName)
	select jt.ShortTransformationName
		from JobControl..TransformationTemplates jt
			left outer join VFPJobs_TemplateStatus ts on ts.ShortTransformationName = jt.ShortTransformationName
	where jt.VFPin = 1
		and ts.RecID is null

	--	Create Queries from JobTemplates

	-- Build the "And" Conditions

	truncate table JobControl..VFPJobs_Query_Conds 

	declare @NewQueryID int
	declare @WhereClause varchar(max)
	declare @VFP_QueryID varchar(100), @QueryTemplateID int

	DECLARE curB CURSOR FOR
		
		select q.VFP_QueryID, max(coalesce(qtf.QueryTemplateID,fc.QueryTemplateID)), q.JobID, q.TemplateID, q.StepID
			from (
					select VFP_QueryID, JobID, null TemplateID, StepID from JobControl..JobSteps where VFPIn = 1 and VFP_QueryID > ''
					union select VFP_QueryID, null, TemplateID, ID from JobControl..JobTemplateSteps where VFPIn = 1 and VFP_QueryID > ''
					) q
				join Dataload..Jobs_MF_query vq on vq.QUERY_ID = q.VFP_QueryID
				left outer join JobControl..VFPJobs_QueryToQueryTemplateForce qtf on qtf.VFP_QueryID = q.VFP_QueryID
				left outer join JobControl..VFPJobs_QueryFromClause fc on (fc.FromClause = Support.FuncLib.StringFromTo(vq.SELECTEXP1,'from','where',1) and fc.FromClause > '')
																			or fc.OrigVFPSelect = vq.SELECTEXP1
			group by q.VFP_QueryID, q.JobID, q.TemplateID, q.StepID


     OPEN curB

     FETCH NEXT FROM curB into @VFP_QueryID, @QueryTemplateID, @JobID, @TemplateID, @StepID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

			insert QueryEditor..Queries (VFPIn, VFP_QueryID, TemplateID)
				values (1, @VFP_QueryID, @QueryTemplateID)

			select @NewQueryID = max(ID) from QueryEditor..Queries where VFPIn = 1
			
			select @WhereClause = Support.FuncLib.StringFromTo(Support.FuncLib.CleanVFPInfo(SELECTEXP1,'QuerySelect'),'Where','',1) + Support.FuncLib.StringFromTo(Support.FuncLib.CleanVFPInfo(SELECTEXP2,'QuerySelect'),'Where','',1)
				from DataLoad..Jobs_MF_query 
					where QUERY_ID = @VFP_QueryID		

			insert JobControl..VFPJobs_Query_Conds ( QUERY_ID, Cond)
				select @VFP_QueryID, case when ltrim(x.value) like 'where %' then substring(ltrim(x.value), 7,1000) else ltrim(x.value) end
					from Support.FuncLib.SplitString(@WhereClause,' and ') x
						left outer join JobControl..VFPJobs_Query_Conds qc on qc.QUERY_ID = @VFP_QueryID and qc.Cond = case when ltrim(x.value) like 'where %' then substring(ltrim(x.value), 7,1000) else ltrim(x.value) end
					where qc.QUERY_ID is null

			if @TemplateID is not null
				update JobControl..JobTemplateSteps 
					set QueryCriteriaID = @NewQueryID
						, QueryTemplateID = @QueryTemplateID
					 where ID = @StepID

			if @JobID is not null
				update JobControl..JobSteps 
					set QueryCriteriaID = @NewQueryID
						, QueryTemplateID = @QueryTemplateID
					where StepID = @StepID

          FETCH NEXT FROM curB into @VFP_QueryID, @QueryTemplateID, @JobID, @TemplateID, @StepID
     END
     CLOSE curB
     DEALLOCATE curB

		--update jts set QueryCriteriaID = q.ID
		--			, QueryTemplateID = q.TemplateID
		--	from JobControl..JobTemplateSteps jts
		--		join QueryEditor..Queries q on q.VFP_QueryID = jts.VFP_QueryID

		--update js set QueryCriteriaID = q.ID
		--			, QueryTemplateID = q.TemplateID
		--	from JobControl..JobSteps js
		--		join QueryEditor..Queries q on q.VFP_QueryID = js.VFP_QueryID


		insert VFPJobs_Map_TemplatesToConds(TemplateID, cond)
		select distinct q.TemplateID, c.cond
			from QueryEditor..Queries q
				join JobControl..QueryTemplates qt on qt.Id = q.TemplateID
				join JobControl..VFPJobs_Query_Conds c on c.QUERY_ID = q.VFP_QueryID
				left outer join JobControl..VFPJobs_Map_TemplatesToConds x on x.TemplateID = q.TemplateID and x.cond = c.cond
			where VFPIn = 1
				and x.RecID is null

	 --Build the "OR" Conditions from the "And" Conditions

	declare @RecID int, @Cond varchar(max)

	DECLARE curB CURSOR FOR
		
		select RecId, TemplateID, Cond 
			from JobControl..VFPJobs_Map_TemplatesToConds
			where cond like '% or %'

     OPEN curB

     FETCH NEXT FROM curB into @RecID, @TemplateID, @Cond
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
			set @Cond = LTRIM(rtrim(@Cond))

			if left(@Cond,1) = '(' and right(@Cond,1) = ')'
				set @Cond = substring(@Cond,2,len(@Cond)-2)

			update JobControl..VFPJobs_Map_TemplatesToConds set Ignore = 1 where RecId = @RecID
			update JobControl..VFPJobs_Map_TemplatesToConds set Comment = '-- Spit Into Ors --' where RecId = @RecID and coalesce(Comment,'') = ''

			insert JobControl..VFPJobs_Map_TemplatesToConds (OrRecID, Cond, TemplateID)
				select @RecID, x.value, @TemplateID
					from Support.FuncLib.SplitString(@Cond,' or ') x
						left outer join JobControl..VFPJobs_Map_TemplatesToConds xc on xc.cond = x.value and xc.OrRecID = @RecID and xc.TemplateID = @TemplateID
					where xc.recId is null


          FETCH NEXT FROM curB into @RecID, @TemplateID, @Cond
     END
     CLOSE curB
     DEALLOCATE curB

--===============================================================================
--		BitCrit Work
--===============================================================================

--declare @TemplateID int
declare @CmdLine varchar(max), @VFP_BTCRITID varchar(50)
      
     DECLARE CurB CURSOR FOR
          	select distinct q.TemplateID
		, substring(Support.FuncLib.StringFromTo(bc.CMDLINE,'bctv_crit=',null,0),12,4000) CmdLine, x.VFP_BTCRITID, x.VFP_QueryID 
		from (	select null TemplateID, JobID, VFP_BTCRITID, QueryCriteriaID, VFP_QueryID 
					from JobControl..JobSteps js
					where VFP_QueryID  > ''
--						and js.JobID = 6551
				union select TemplateID, null JobID, VFP_QueryID, QueryCriteriaID, VFP_QueryID  
					from JobControl..JobTemplateSteps js
					where VFP_QueryID  > ''
--						and js.TemplateID = 1210
			) x
		join DataLoad..Jobs_MF_btcritss bc on bc.FUNCTIONID = x.VFP_BTCRITID and bc.CMDLINE like '%bctv_crit=%'
		join QueryEditor..Queries q on q.Id = x.QueryCriteriaID

     OPEN CurB

     FETCH NEXT FROM CurB into @TemplateID, @CmdLine, @VFP_BTCRITID, @VFP_QueryID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

			insert JobControl..VFPJobs_Map_BitCritToConds (TemplateID, cond, FullOrigCond)
			select @TemplateID, x.value, @CmdLine 
				from Support.FuncLib.SplitString(@CmdLine,' and ') x
					left outer join JobControl..VFPJobs_Map_BitCritToConds m on m.cond = x.Value and m.TemplateID = @TemplateID
				where m.RecId is null

			insert JobControl..VFPJobs_Query_Conds ( QUERY_ID, Cond)
				select @VFP_BTCRITID, x.value
					from Support.FuncLib.SplitString(@CmdLine,' and ') x
						left outer join JobControl..VFPJobs_Query_Conds qc on qc.QUERY_ID = @VFP_BTCRITID and qc.Cond = x.value
					where qc.QUERY_ID is null

          FETCH NEXT FROM CurB into @TemplateID, @CmdLine, @VFP_BTCRITID, @VFP_QueryID
     END
     CLOSE CurB
     DEALLOCATE CurB



--	declare @RecID int, @Cond varchar(max)

	DECLARE curB CURSOR FOR
		
		select RecId, TemplateID, Cond 
			from JobControl..VFPJobs_Map_BitCritToConds
			where cond like '% or %'

     OPEN curB

     FETCH NEXT FROM curB into @RecID, @TemplateID, @Cond
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
			set @Cond = LTRIM(rtrim(@Cond))

			if left(@Cond,1) = '(' and right(@Cond,1) = ')'
				set @Cond = substring(@Cond,2,len(@Cond)-2)

			update JobControl..VFPJobs_Map_BitCritToConds set Ignore = 1 where RecId = @RecID
			update JobControl..VFPJobs_Map_BitCritToConds set Comment = '-- Spit Into Ors --' where RecId = @RecID and coalesce(Comment,'') = ''

			insert JobControl..VFPJobs_Map_BitCritToConds (OrRecID, Cond, TemplateID)
				select @RecID, x.value, @TemplateID
					from Support.FuncLib.SplitString(@Cond,' or ') x
						left outer join JobControl..VFPJobs_Map_BitCritToConds xc on xc.cond = x.value and xc.OrRecID = @RecID and xc.TemplateID = @TemplateID
					where xc.recId is null


          FETCH NEXT FROM curB into @RecID, @TemplateID, @Cond
     END
     CLOSE curB
     DEALLOCATE curB


	update JobControl..VFPJobs_Map_BitCritToConds
			set NewCondPlace = 'Query'
				, NewCondType = 'Location'
				, NewCondField = 'CountyID'
				, NewCondValue = JobControl.dbo.VFPImport_CodesToIDs(Cond,'County')
		where coalesce(ignore,0) = 0
			and cond like '%ccode%'

	update JobControl..VFPJobs_Map_TemplatesToConds
			set NewCondPlace = 'Query'
				, NewCondType = 'Location'
				, NewCondField = 'CountyID'
				, NewCondValue = JobControl.dbo.VFPImport_CodesToIDs(Cond,'County')
		where coalesce(ignore,0) = 0
			and cond like '%ccode%'

	update JobControl..VFPJobs_Map_BitCritToConds
			set NewCondPlace = 'Query'
				, NewCondType = 'Location'
				, NewCondField = 'TownID'
				, NewCondValue = JobControl.dbo.VFPImport_CodesToIDs(Cond,'Town')
		where coalesce(ignore,0) = 0
			and cond like '%.Town%'

	update JobControl..VFPJobs_Map_TemplatesToConds
			set NewCondPlace = 'Query'
				, NewCondType = 'Location'
				, NewCondField = 'TownID'
				, NewCondValue = JobControl.dbo.VFPImport_CodesToIDs(Cond,'Town')
		where coalesce(ignore,0) = 0
			and cond like '%.Town%'

	update JobControl..VFPJobs_Map_BitCritToConds
			set NewCondPlace = 'Query'
				, NewCondType = 'MultiVal'
				, NewCondField = case when TemplateID = 1 then 'SalesPropUsageID'
									else null end
				, NewCondValue = JobControl.dbo.VFPImport_CodesToIDs(Cond,'Use')
		where coalesce(ignore,0) = 0
			and Cond like '%inlist%'
			and cond like '%StateUse%'

	update JobControl..VFPJobs_Map_TemplatesToConds
			set NewCondPlace = 'Query'
				, NewCondType = 'MultiVal'
				, NewCondField = case when TemplateID = 1 then 'SalesPropUsageID'
									else null end
				, NewCondValue = JobControl.dbo.VFPImport_CodesToIDs(Cond,'Use')
		where coalesce(ignore,0) = 0
			and Cond like '%inlist%'
			and cond like '%StateUse%'

	update JobControl..VFPJobs_Map_BitCritToConds
			set NewCondPlace = 'Query'
				, NewCondType = 'Location'
				, NewCondField = 'ZipCode'
				, NewCondValue = JobControl.dbo.VFPImport_CodesToIDs(Cond,'Zip')
		where coalesce(ignore,0) = 0
			and Cond like '%inlist%'
			and cond like '%zipcode%'

	update JobControl..VFPJobs_Map_TemplatesToConds
			set NewCondPlace = 'Query'
				, NewCondType = 'Location'
				, NewCondField = 'ZipCode'
				, NewCondValue = JobControl.dbo.VFPImport_CodesToIDs(Cond,'Zip')
		where coalesce(ignore,0) = 0
			and Cond like '%inlist%'
			and cond like '%zipcode%'

--===============================================================================

	 -- TBD Build Template Queries turning Conds into Wired3 conds using

		declare @NewCondPlace varchar(50), @NewCondType varchar(50), @NewCondField varchar(50)
				, @NewCondNot bit, @NewCondSymbol varchar(100), @NewCondValue varchar(100), @OrRecID int, @OrigCond Varchar(max), @COrRecID int, @XRecID int

		DECLARE curB CURSOR FOR

		select TemplateID, NewCondPlace, NewCondType, NewCondField, NewCondNot, NewCondSymbol, NewCondValue, OrRecID, Cond, COALESCE (OrRecID, RecId), RecId
			from JobControl..VFPJobs_Map_TemplatesToConds
			where coalesce(ignore,0) = 0
		union 	
		select TemplateID, NewCondPlace, NewCondType, NewCondField, NewCondNot, NewCondSymbol, NewCondValue, OrRecID, Cond, COALESCE (OrRecID, RecId), RecId
			from JobControl..VFPJobs_Map_BitCritToConds
			where coalesce(ignore,0) = 0
		ORDER BY TemplateID, COALESCE (OrRecID, RecId), RecId

		 OPEN curB

		 FETCH NEXT FROM curB into @TemplateID, @NewCondPlace, @NewCondType, @NewCondField, @NewCondNot, @NewCondSymbol, @NewCondValue, @OrRecID, @OrigCond, @COrRecID, @XRecID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				-- TBD JobParam		Skipped becuse these will be added after the cloned queries
				-- TBD Join			Noe yet
				if @NewCondPlace = 'Query'
				begin
					if @NewCondType = 'Range'
						begin
							insert QueryEditor..QueryRanges (VFPIn, QueryID, RangeSource, MinValue, MaxValue, Exclude)
							select distinct 1, q.ID, @NewCondField
													, JobControl.dbo.VFPImport_RangeSplit(@NewCondValue,'left')
													, JobControl.dbo.VFPImport_RangeSplit(@NewCondValue,'right')
									, coalesce(@NewCondNot,0)
								from QueryEditor..Queries q
									join JobControl..QueryTemplates qt on qt.Id = q.TemplateID
									join JobControl..VFPJobs_Query_Conds c on c.QUERY_ID = q.VFP_QueryID and c.Cond = @OrigCond
									left outer join QueryEditor.. QueryRanges m on m.VFPIn = 1 and m.QueryID = q.ID 
																					and m.RangeSource = @NewCondField
																					and m.MinValue = JobControl.dbo.VFPImport_RangeSplit(@NewCondValue,'left')
																					and m.MaxValue = JobControl.dbo.VFPImport_RangeSplit(@NewCondValue,'right')
																					and m.Exclude = coalesce(@NewCondNot,0)
								where TemplateID = @TemplateID and q.VFPIn = 1
									--and m.ID is null

							insert QueryEditor..QueryRanges (VFPIn, QueryID, RangeSource, MinValue, MaxValue, Exclude)
							select distinct 1, q.ID, @NewCondField
													, JobControl.dbo.VFPImport_RangeSplit(@NewCondValue,'left')
													, JobControl.dbo.VFPImport_RangeSplit(@NewCondValue,'right')
									, coalesce(@NewCondNot,0)
								from QueryEditor..Queries q
									join JobControl..JobSteps js on js.QueryCriteriaID = q.ID
									join JobControl..VFPJobs_Query_Conds c on (c.QUERY_ID = js.VFP_QueryID or c.QUERY_ID = js.VFP_BTCRITID) and c.Cond = @OrigCond
									left outer join QueryEditor.. QueryRanges m on m.VFPIn = 1 and m.QueryID = q.ID 
																					and m.RangeSource = @NewCondField
																					and m.MinValue = JobControl.dbo.VFPImport_RangeSplit(@NewCondValue,'left')
																					and m.MaxValue = JobControl.dbo.VFPImport_RangeSplit(@NewCondValue,'right')
																					and m.Exclude = coalesce(@NewCondNot,0)
								where TemplateID = @TemplateID and q.VFPIn = 1
									--and m.ID is null
						end
					if @NewCondType = 'Location'
						begin
							insert QueryEditor.. QueryLocations (VFPIn, QueryID, ZipCode, CountyID, TownID, StateID, Exclude)
							select distinct 1, q.ID , case when @NewCondField = 'ZipCode' then x.Value else null end
													, case when @NewCondField = 'CountyID' then x.Value else null end
													, case when @NewCondField = 'TownID' then x.Value else null end
													, case when @NewCondField = 'StateID' then x.Value else null end
									, coalesce(@NewCondNot,0)
								from QueryEditor..Queries q
									join JobControl..QueryTemplates qt on qt.Id = q.TemplateID
									join JobControl..VFPJobs_Query_Conds c on c.QUERY_ID = q.VFP_QueryID and c.Cond = @OrigCond
									join Support.FuncLib.SplitString(@NewCondValue,',') x on 1=1
									left outer join QueryEditor.. QueryLocations m on m.VFPIn = 1 and m.QueryID = q.ID 
																					and ZipCode = case when @NewCondField = 'ZipCode' then x.Value else null end
																					and CountyID = case when @NewCondField = 'CountyID' then x.Value else null end
																					and TownID = case when @NewCondField = 'TownID' then x.Value else null end
																					and StateID = case when @NewCondField = 'StateID' then x.Value else null end
																					and m.Exclude = coalesce(@NewCondNot,0)
								where TemplateID = @TemplateID and q.VFPIn = 1
									--and m.ID is null

							insert QueryEditor.. QueryLocations (VFPIn, QueryID, ZipCode, CountyID, TownID, StateID, Exclude)
							select distinct 1, q.ID , case when @NewCondField = 'ZipCode' then x.Value else null end
													, case when @NewCondField = 'CountyID' then x.Value else null end
													, case when @NewCondField = 'TownID' then x.Value else null end
													, case when @NewCondField = 'StateID' then x.Value else null end
									, coalesce(@NewCondNot,0)
								from QueryEditor..Queries q
									join JobControl..JobSteps js on js.QueryCriteriaID = q.ID
									join JobControl..VFPJobs_Query_Conds c on (c.QUERY_ID = js.VFP_QueryID or c.QUERY_ID = js.VFP_BTCRITID) and c.Cond = @OrigCond
									join Support.FuncLib.SplitString(@NewCondValue,',') x on 1=1
									left outer join QueryEditor.. QueryLocations m on m.VFPIn = 1 and m.QueryID = q.ID 
																					and ZipCode = case when @NewCondField = 'ZipCode' then x.Value else null end
																					and CountyID = case when @NewCondField = 'CountyID' then x.Value else null end
																					and TownID = case when @NewCondField = 'TownID' then x.Value else null end
																					and StateID = case when @NewCondField = 'StateID' then x.Value else null end
																					and m.Exclude = coalesce(@NewCondNot,0)
								where TemplateID = @TemplateID and q.VFPIn = 1
									--and m.ID is null
						end
					if @NewCondType = 'MultiVal'
						begin
							insert QueryEditor.. QueryMultIDs (VFPIn, QueryID, ValueSource, ValueID, Exclude)
							select distinct 1, q.ID, @NewCondField, x.Value, coalesce(@NewCondNot,0)
								from QueryEditor..Queries q
									join JobControl..QueryTemplates qt on qt.Id = q.TemplateID
									join JobControl..VFPJobs_Query_Conds c on c.QUERY_ID = q.VFP_QueryID and c.Cond = @OrigCond
									join Support.FuncLib.SplitString(@NewCondValue,',') x on 1=1
									left outer join QueryEditor.. QueryMultIDs m on m.VFPIn = 1 and m.QueryID = q.ID 
																					and m.ValueSource = @NewCondField
																					and m.ValueID = x.Value
																					and m.Exclude = coalesce(@NewCondNot,0)
								where TemplateID = @TemplateID and q.VFPIn = 1
									--and m.ID is null

							insert QueryEditor.. QueryMultIDs (VFPIn, QueryID, ValueSource, ValueID, Exclude)
							select distinct 1, q.ID, @NewCondField, x.Value, coalesce(@NewCondNot,0)
								from QueryEditor..Queries q
									join JobControl..JobSteps js on js.QueryCriteriaID = q.ID
									join JobControl..VFPJobs_Query_Conds c on (c.QUERY_ID = js.VFP_QueryID or c.QUERY_ID = js.VFP_BTCRITID) and c.Cond = @OrigCond
									join Support.FuncLib.SplitString(@NewCondValue,',') x on 1=1
									left outer join QueryEditor.. QueryMultIDs m on m.VFPIn = 1 and m.QueryID = q.ID 
																					and m.ValueSource = @NewCondField
																					and m.ValueID = x.Value
																					and m.Exclude = coalesce(@NewCondNot,0)
								where TemplateID = @TemplateID and q.VFPIn = 1
									--and m.ID is null

						end
					if @NewCondType = 'Field'
						begin
							set @cmd = 'update QueryEditor..Queries set ' + @NewCondField + ' = ' + @NewCondValue + ' where TemplateID = ' + ltrim(str(@TemplateID)) + ' and VFPIn = 1'
							exec(@cmd)
						end
				end
			  FETCH NEXT FROM curB into @TemplateID, @NewCondPlace, @NewCondType, @NewCondField, @NewCondNot, @NewCondSymbol, @NewCondValue, @OrRecID, @OrigCond, @COrRecID, @XRecID
		 END
		 CLOSE curB
		 DEALLOCATE curB

	------------------------------------------------------------------------------------------------

	 -- For every job Clone Query of JobTemplate into new query in Job
	 -- Add Job State Location to Query (JobParam)
	 -- Add Job County Location to Query (JobParam)
	 -- Add Issueweek to Query (JobParam)

		declare @QueryCriteriaId int, @QueryTypeID int, @JobTemplateID int

		DECLARE curB CURSOR FOR
		
		select jts.QueryCriteriaId, qt.QueryTypeID, jt.TemplateID, null
			from JobControl..JobTemplates jt 
				join JobControl..JobTemplateSteps jts on jts.TemplateID = jt.TemplateID
				join QueryEditor..Queries q on q.ID = jts.QueryCriteriaId
				join JobControl..QueryTemplates qt on qt.Id = q.TemplateID
			where jts.QueryCriteriaId is not null
				and jt.VFPIn = 1
		union 
		select js.QueryCriteriaId, qt.QueryTypeID, null, j.JobID
			from JobControl..Jobs j
				join JobControl..JobSteps js on js.jobID = j.JobID
				join QueryEditor..Queries q on q.ID = js.QueryCriteriaId
				join JobControl..QueryTemplates qt on qt.Id = q.TemplateID
			where js.QueryCriteriaId is not null
				and j.VFPIn = 1


		 OPEN curB

		 FETCH NEXT FROM curB into @QueryCriteriaId, @QueryTypeID, @JobTemplateID, @JobID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

				insert QueryEditor..QueryLocations (QueryID, StateID, CountyID, VFPIn)
				select @QueryCriteriaId
						, case when ParamName = 'StateID' then ParamVal else null end
						, case when ParamName = 'CountyID' then ParamVal else null end
						, 1
					from JobControl..VFPJobs_Params

					where JobTemplateID = @JobTemplateID and ParamName in ('StateID','CountyID')

				insert QueryEditor..QueryLocations (QueryID, StateID, CountyID, VFPIn)
				select @QueryCriteriaId
						, case when ParamName = 'StateID' then ParamVal else null end
						, case when ParamName = 'CountyID' then ParamVal else null end
						, 1
					from JobControl..VFPJobs_Params
					where JobID = @JobID and ParamName in ('StateID','CountyID')

				insert QueryEditor..QueryRanges (QueryID, RangeSource, MinValue, MaxValue, VFPIn)
				select @QueryCriteriaId
						, case when @QueryTypeID = 1 then 'BankruptcyTransProcessWeekRange'	--Bankruptcies
								when @QueryTypeID = 2 then '' --BuildingPermits
								when @QueryTypeID = 3 then '' --DistressedProperty
								when @QueryTypeID = 4 then 'LienTransProcessWeekRange' --Liens
								when @QueryTypeID = 5 then '' --MaintainAddresses
								when @QueryTypeID = 6 then 'MtgAssignTransProcessWeekRange' --MortgageAssignments
								when @QueryTypeID = 7 then 'MtgDischargeTransProcessWeekRange' --MortgageDischarges
								when @QueryTypeID = 8 then 'TransProcessWeekRange' --Mtgs
								when @QueryTypeID = 9 then 'PreForTransProcessWeekRange' --PreForeclosures
								when @QueryTypeID = 10 then 'TransProcessWeekRange' --Properties
								when @QueryTypeID = 11 then 'TransProcessWeekRange' --PropertiesExtended
								when @QueryTypeID = 12 then 'TransProcessWeekRange' --Sales
								when @QueryTypeID = 13 then 'TransProcessWeekRange' --SalesAndMtgs
								else 'TransProcessWeekRange' end
						, PLW.ParamVal, PHW.ParamVal, 1 
				from (select distinct JobID from JobControl..VFPJobs_Params) p
					left outer join JobControl..VFPJobs_Params PIW on p.JobID = PIW.JobID and PIW.ParamVal > '' and PIW.ParamName = 'IssueWeek'
					left outer join JobControl..VFPJobs_Params PLW on p.JobID = PLW.JobID and PLW.ParamVal > '' and PLW.ParamName = 'LowWeek'
					left outer join JobControl..VFPJobs_Params PHW on p.JobID = PHW.JobID and PHW.ParamVal > '' and PHW.ParamName = 'HighWeek'
				where coalesce(PIW.ParamVal, PLW.ParamVal, PHW.ParamVal) is not null
					and p.JobID = @JobID

				insert QueryEditor..QueryRanges (QueryID, RangeSource, MinValue, MaxValue, VFPIn)
				select @QueryCriteriaId
						, 'ModificationDate'
						, PLD.ParamVal, PHD.ParamVal, 1 
				from (select distinct JobID from JobControl..VFPJobs_Params) p
					left outer join JobControl..VFPJobs_Params PLD on p.JobID = PLD.JobID and PLD.ParamVal > '' and PLD.ParamName = 'LowModDate'
					left outer join JobControl..VFPJobs_Params PHD on p.JobID = PHD.JobID and PHD.ParamVal > '' and PHD.ParamName = 'HiModDate'
				where coalesce(PLD.ParamVal, PHD.ParamVal) is not null
					and p.JobID = @JobID

			  FETCH NEXT FROM curB into @QueryCriteriaId, @QueryTypeID, @JobTemplateID, @JobID
		 END
		 CLOSE curB
		 DEALLOCATE curB


	 -- TBD Merge multiple appended county steps into 1 job step
	 -- TBD Merge multiple appended state Jobs into 1 job
	 -- TBD Deal with Customer ID (Maybe not here but need to be addressed)

	 declare @NewXFromID int, @NewLayoutID int, @VFPXFormShell varchar(100)
	 declare @VFPLayoutID varchar(50)

		DECLARE curB CURSOR FOR
		
		select jtsX.VFP_LayoutID, Q.TemplateID
			from JobControl..JobTemplateSteps jtsQ
				join JobControl..JobTemplateSteps jtsX on jtsX.StepTypeID = 29 and (jtsQ.StepOrder + 1) = jtsX.StepOrder and jtsQ.TemplateID = jtsX.TemplateID
				join QueryEditor..Queries Q on Q.ID = jtsQ.QueryCriteriaID
			where jtsQ.VFPIn = 1
				and jtsQ.StepTypeID = 21
				and ltrim(rtrim(jtsX.VFP_LayoutID)) > ''
		union 
		select jsX.VFP_LayoutID, Q.TemplateID
			from JobControl..JobSteps jsQ
				join JobControl..JobSteps jsX on jsX.StepTypeID = 29 and (jsQ.StepOrder + 1) = jsX.StepOrder and jsQ.QueryTemplateID = jsX.QueryTemplateID
				join QueryEditor..Queries Q on Q.ID = jsQ.QueryCriteriaID
			where jsQ.VFPIn = 1
				and jsQ.StepTypeID = 21
				and ltrim(rtrim(jsX.VFP_LayoutID)) > ''
		 OPEN curB

		 FETCH NEXT FROM curB into @VFPLayoutID, @QueryTemplateID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

				insert JobControl..TransformationTemplates (VFPIn, ShortTransformationName, Description, QueryTemplateID)
					values (1, @VFPLayoutID, @VFPLayoutID + ' Imported from VFP', @QueryTemplateID)
				
				set @NewXFromID = SCOPE_IDENTITY()
				
				insert JobControl..TransformationTemplateColumns (VFPIn, TransformTemplateID, OutName, VFPSourceCode)
					select 1, @NewXFromID, OutName, VFPSource
						from (
							select SEQ, CMDLINE
									, ltrim(rtrim(replace(replace(Support.FuncLib.StringFromTo(CMDLINE,'xfom_makeout(','),6]=*',0),'xfom_makeout(''',''),'''',''))) OutName
									, ltrim(rtrim(replace(Support.FuncLib.StringFromTo(CMDLINE,'),6]=*','',0),'),6]=*',''))) VFPSource
								from DataLoad..Jobs_MF_xformdbf
								where FUNCTIONID = @VFPLayoutID
							) x
						where OutName > '' or VFPSource > ''
						order by SEQ				 

				--Insert VFPCode and QueryTempaleID into Distinct Map Table if does not exist
				insert JobControl..VFPJObs_Map_XForm_VFPCode (VFPSourceCode, SQLCode)
					select distinct ttc.VFPSourceCode, null
						from JobControl..TransformationTemplateColumns ttc
							left outer join JobControl..VFPJObs_Map_XForm_VFPCode pc on pc.VFPSourceCode = ttc.VFPSourceCode
--																						and pc.TransformTemplateID = ttc.TransformTemplateID
						where ttc.VFPIn = 1
							and pc.RecID is null
							and ttc.VFPSourceCode > ''

				update u set SQLCode = case when VFPSourceCode like '''%''' then VFPSourceCode
									when VFPSourceCode like '"%"' then replace(VFPSourceCode,'"','''')
									else null end
				from JobControl..VFPJObs_Map_XForm_VFPCode u
					where SQLCode is null

				
				--Update SourceCode from Map Table based on TemplateID
				update ttc set SourceCode = coalesce(pc.SQLCode, pc2.SQLCode)
					from JobControl..TransformationTemplateColumns ttc
						join JobControl..TransformationTemplates tt on ttc.TransformTemplateID = tt.Id
						left outer join JobControl..VFPJObs_Map_XForm_VFPCode pc on pc.VFPSourceCode = ttc.VFPSourceCode and pc.VFPLayoutID = tt.ShortTransformationName
						left outer join JobControl..VFPJObs_Map_XForm_VFPCode pc2 on pc2.VFPSourceCode = ttc.VFPSourceCode and pc2.VFPLayoutID is null
--																						and pc.TransformTemplateID = ttc.TransformTemplateID
					where ttc.VFPIn = 1

				select @VFPXFormShell = XFORMSHELL
					from (
						select replace(replace(Support.FuncLib.StringFromTo(Support.FuncLib.StringFromTo(CMDLINE,'xfop_outfile=*','',0),'REDP\DBC\JOBS\XFORMSHELLS\','',0),'REDP\DBC\JOBS\XFORMSHELLS\',''),'.DBF','') XFORMSHELL
							from DataLoad..Jobs_MF_xformdbf
							where FUNCTIONID = @VFPLayoutID
						) x
					where XFORMSHELL > ''

				-- Insert New Layout with Default set true
				insert JobControl..FileLayouts (VFPIn, TransformationTemplateID, DefaultLayout, ShortFileLayoutName, Description)
					select 1, @NewXFromID, 1, @VFPXFormShell, @VFPXFormShell + ' Imported from VFP'

				select @NewLayoutID = max(ID) from JobControl..FileLayouts where TransformationTemplateID = @NewXFromID

				-- Insert Layout Fields
				insert JobControl..FileLayoutFields (VFPIn, FileLayoutID, OutOrder
													, SortOrder, SortDir, Disabled, CaseChange,DoNotTrim,Padding, PaddingLength, PaddingChar
													, OutWidth
													, SrcName
													, OutName)
				select 1, @NewLayoutID, s.FieldOrder
						, 0, 0, 0, 'None', 0, 'None', 0, null
						, case when s.FieldType in ('char') then s.FieldLength else 0 end
						, 'XF_' + s.FieldName
						, s.FieldName
					from DataLoad..Jobs_XFormShells s  
					where s.tablename = @VFPXFormShell

			  FETCH NEXT FROM curB into @VFPLayoutID, @QueryTemplateID
		 END
		 CLOSE curB
		 DEALLOCATE curB

		 --Update Sort Order with default of PropID or first Field
			update z set SortOrder = 1, z.SortDir = 'asc'
				from JobControl..FileLayoutFields z
					join (
							select * 
									, rowid = ROW_NUMBER() OVER (PARTITION BY FileLayoutID ORDER BY PriorityField)
								from (
									select FileLayoutID, RecID, case when SrcName = 'propid' then 1
															when OutOrder = 1 then 2 else 3 end PriorityField
										from JobControl..FileLayoutFields
										where VFPIn = 1
								) x
							) y on z.RecID = y.RecID and y.rowid = 1

			-- Manual add Xform Columns
				insert JobControl..TransformationTemplateColumns (TransformTemplateID, OutName, SourceCode, VFPIn)
					select id, 'IsCondo', 'case when x.SalesPropUsage = 102 then 1 else 0 end', 1
						  from JobControl..TransformationTemplates where ShortTransformationName = 'XPMTD'

			-- Manual add Layout Columns
				insert JobControl..FileLayoutFields (FileLayoutID, VFPIn, OutOrder, SortDir, SrcName, OutName, OutWidth, Disabled, CaseChange, DoNotTrim, Padding, PaddingLength)
					select lf.FileLayoutID, 1, max(OutOrder)+1, '0', 'XF_IsCondo', 'IsCondo',0,0,'None',0,'None',0
						from JobControl..FileLayoutFields lf
							join JobControl..FileLayouts l on l.Id = lf.FileLayoutID
						where l.ShortFileLayoutName = 'OUTMTD'
						group by lf.FileLayoutID

			--Layout Sort Exceptions
					update lf set SortOrder = case when OutName = 'town' then 1
													when OutName = 'IsCondo' then 2
													when OutName = 'STREET' then 3
													when OutName = 'STNUM' then 4
													else 0 end
								, SortDir = case when OutName in ('town','IsCondo','STREET','STNUM') then 'asc'
													else '0' end
	
						from JobControl..FileLayoutFields lf
							join JobControl..FileLayouts l on l.Id = lf.FileLayoutID
						where l.ShortFileLayoutName = 'OUTMTD'


		 -- Update Transform Steps of Jobs with Correct new TransformID and LayoutID

			update jts set jts.TransformationId = tt.id, jts.FileLayoutId = fl.ID
				from JobControl..JobTemplateSteps jts
					join JobControl..TransformationTemplates tt on tt.VFPin = 1 and tt.ShortTransformationName = jts.VFP_LayoutID
					join JobControl..FileLayouts fl on tt.ID = fl.TransformationTemplateId and fl.DefaultLayout = 1
					where jts.StepTypeID = 29 and jts.VFPin = 1

			update js set js.TransformationId = tt.id, js.FileLayoutId = fl.ID
				from JobControl..JobSteps js
					join JobControl..TransformationTemplates tt on tt.VFPin = 1 and tt.ShortTransformationName = js.VFP_LayoutID
					join JobControl..FileLayouts fl on tt.ID = fl.TransformationTemplateId and fl.DefaultLayout = 1 
					where js.StepTypeID = 29 and js.VFPin = 1

			insert JobControl..VFPJobs_Map_Reports (VFP_REPORT_ID, DESCRIP, CATEGORY, Outtype, FILEEXT, notes, XFORMID)
			select distinct x.REPORT_ID, x.DESCRIP, x.CATEGORY, x.Outtype, x.FILEEXT, x.notes, x.XFORMID
				from DataLoad..Jobs_MF_reportdf x
					left outer join JobControl..VFPJobs_Map_Reports m on x.REPORT_ID = m.VFP_REPORT_ID
				where m.RECID is null

			update jts set ReportListID = rm.ReportID
				from JobControl..JobTemplateSteps jts
					join JobControl..VFPJobs_Map_Reports rm on rm.VFP_Report_ID = jts.VFP_ReportID and coalesce(ReportID,0) > 0
				where jts.VFPIn = 1 and jts.StepTypeID = 22

			update js set ReportListID = rm.ReportID
				from JobControl..JobSteps js
					join JobControl..VFPJobs_Map_Reports rm on rm.VFP_Report_ID = js.VFP_ReportID and coalesce(ReportID,0) > 0
				where js.VFPIn = 1 and js.StepTypeID = 22

	DECLARE curA CURSOR FOR
		select jt.TemplateID
			from JobControl..JobTemplates jt 
			where jt.VFPIn = 1

     OPEN curA

     FETCH NEXT FROM curA into @JobTemplateID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

			exec JobControl..VFPJobs_AddXFormSteps_ForDeletedSelects @JobTemplateID, null

          FETCH NEXT FROM curA into @JobTemplateID
     END
     CLOSE curA
     DEALLOCATE curA

	DECLARE curA CURSOR FOR
		select j.JobID
			from JobControl..Jobs j
			where j.VFPIn = 1

     OPEN curA

     FETCH NEXT FROM curA into @JobID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

			exec JobControl..VFPJobs_AddXFormSteps_ForDeletedSelects null, @JobID

          FETCH NEXT FROM curA into @JobID
     END
     CLOSE curA
     DEALLOCATE curA

		update tc set SourceCode = x.SourceCode
			from JobControl..TransformationTemplates t
				join JobControl..TransformationTemplateColumns tc on t.Id = tc.TransformTemplateID
				join JobControl..VFPJobs_HoldNotBlankVFPCodeXFormCols x on x.ShortTransformationName = t.ShortTransformationName
																		and x.OutName = tc.OutName
			where tc.VFPIn = 1 

	--#############################################################################################
	--	 Update Jobs with Sequentual Multiple Report Steps to use the same Depends on Step ID's
	--###############################  Start  #####################################################

			declare @LastStepTypeID int, @LastStepOrder int, @FirstRepStepID int, @FirstDependsOnStepIDs varchar(50)

			set @LastJobID = -1
			set @LastStepTypeID = -1
			set @LastStepOrder = -1
			set @FirstRepStepID = -1
			set @FirstDependsOnStepIDs = ''

			declare @StepOrder int, @VFP_ReportID varchar(100), @DependsOnStepIDs varchar(500)

			 DECLARE curRepSteps CURSOR FOR
				select JobID, StepOrder, StepTypeID, VFP_ReportID, DependsOnStepIDs, StepID
					from JobControl..JobSteps
					--where jobid in (2101,2102,2764)
					order by JobID, StepOrder

			 OPEN curRepSteps

			FETCH NEXT FROM curRepSteps into @JobID, @StepOrder, @StepTypeID, @VFP_ReportID, @DependsOnStepIDs, @StepID
			WHILE (@@FETCH_STATUS <> -1)
			BEGIN
		
				if @LastJobID = @JobID
					begin
						--if @LastStepOrder = @StepOrder -1 and @StepTypeID = 22
						--begin
				
						--end
						if @StepTypeID = 22
							begin
								if @FirstRepStepID = -1
									begin
										set @FirstRepStepID = @StepID
										set @FirstDependsOnStepIDs = @DependsOnStepIDs
										--print @StepID
									end
								else
									begin
										update JobSteps set DependsOnStepIDs = @FirstDependsOnStepIDs where StepID = @StepID
										--print ltrim(str(@JobID)) + ' update ' + ltrim(str(@StepID)) + ' with ' + @FirstDependsOnStepIDs
									end
							end
						else
							begin
								set @FirstRepStepID = -1
								set @FirstDependsOnStepIDs = ''
							end
					end
				else
					begin
						set @FirstRepStepID = -1
						set @FirstDependsOnStepIDs = ''
					end

				set @LastJobID = @JobID
				set @LastStepTypeID = @StepTypeID
				set @LastStepOrder = @StepOrder

				FETCH NEXT FROM curRepSteps into @JobID, @StepOrder, @StepTypeID, @VFP_ReportID, @DependsOnStepIDs, @StepID
			END
			CLOSE curRepSteps
			DEALLOCATE curRepSteps

	--###############################   END   #####################################################

	update nj set CustID = oj.CUSTID
		from JobControl..Jobs nj
			left outer join DataLoad..Jobs_Jobs oj on oj.JOBID = VFPJobID
		where nj.VFPIn = 1

  --   DECLARE curA CURSOR FOR
		--select j.JobID, j.JOBTYPE, jt.TemplateID
		--	from DataLoad..Jobs_Jobs j
		--		join JobControl..JobTemplates jt on jt.Type = j.JOBTYPE
		--	where j.JobID in (select JobID from #JobsToDo)

  --   OPEN curA

  --   FETCH NEXT FROM curA into @JobID, @JobType, @NewJobTempID
  --   WHILE (@@FETCH_STATUS <> -1)
  --   BEGIN

		--	exec JobControl..CreateNewJob @NewJobTempID

		--	select @NewJobID = max(JobID) from JobControl..Jobs

		--	update JobControl..Jobs set VFPJobID = @JobID where JobID = @NewJobID

  --        FETCH NEXT FROM curA into @JobID, @JobType, @NewJobTempID
  --   END
  --   CLOSE curA
  --   DEALLOCATE curA



		drop table #JobsToDo

print ' MUST RUN!!! this to update Query SQLCmds'
print 'R:\Wired3\Devel\Runable\QueryEditorSQLUpdate\QueryEditorSQLUpdate.exe' 

end
