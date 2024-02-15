/****** Object:  Procedure [dbo].[VFPJobs_BuildProcess4]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobs_BuildProcess4
AS
BEGIN
	SET NOCOUNT ON;

	--truncate table JobControl..TransformationTemplates_Prev
	--	insert JobControl..TransformationTemplates_Prev
	--	select * 
	--		from JobControl..TransformationTemplates

	--	truncate table JobControl..TransformationTemplateColumns_Prev
	--	insert JobControl..TransformationTemplateColumns_Prev
	--	select * 
	--		from JobControl..TransformationTemplateColumns


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
	insert JobControl..CustomerInfo (ID, Company, LastName, FirstName, EMail, Address1, Address2, City, State, Zip, FTPLOGIN, FTPPASSWRD, FTPPATH, ELECADDR, QBCUSTID, LSREPID)
	select custID, Company, PCLNAME, PCFName, PCEMAIL, PCADDRESS1, PCADDRESS2, PCCITY, PCSTATE, PCZIP + case when PCZIPEXT > '' then '-' + PCZIPEXT else '' end, FTPLOGIN, FTPPASSWRD, FTPPATH, ELECADDR, QBCUSTID, LSREPID
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

     declare @CatID int, @CatName varchar(250)
     DECLARE curA CURSOR FOR
			select category_id, name
				from msdb.dbo.syscategories  
			   WHERE category_class = 1  
				   AND category_type = 1  
				   and name like 'Wired Job %'

     OPEN curA

     FETCH NEXT FROM curA into @CatID, @CatName
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
		EXEC msdb.dbo.sp_delete_category @name = @CatName, @class = 'JOB'
		FETCH NEXT FROM curA into @CatID, @CatName
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

	 truncate table DocumentLibrary..DocumentMaster
	 truncate table DocumentLibrary..Documents

	 exec Support..Wired3Housekeeping

	 exec JobControl..CreateSimpleJobTemplate

select distinct JobID
	into #JobsToDo
	from (
		select j.JobID, j.CATEGORY 
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
			union select JobID, Category
				from JobControl..VFPJobs_ListOfJobs2Import
				where JobType not like 'SEXT%C'
		) x
--	where Category not in ('XPROD','XSTAT')


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
					, @NewJobTempID = max(wjt.JobID)
				from DataLoad..Jobs_JOBSTEMPL jt 
						join JobControl..Jobs wjt on wjt.IsTemplate = 1 and wjt.JobName = jt.jobdescrip and wjt.VFPIn = 1
					where jt.jobType = @JobType
			
			if @TemplateExists = 0
				begin

	 				insert JobControl..Jobs (VFPIn, Type, JobName, CategoryID, ModeID, RecurringTypeID, ProcessTypeID, IsTemplate)
						select 1, jt.jobtype, jt.jobdescrip, jc.ID, jm.ID, jrt.ID, 4, 1
							from DataLoad..Jobs_JOBSTEMPL jt 
								join JobControl..JobCategories jc on jc.Code = jt.category
								join JobControl..JobModes jm on jm.Code = jt.jobrunmode
								join JobControl..JobRecurringTypes jrt on jrt.Code = jt.recurring
							where jt.jobType = @JobType
		
					select @NewJobTempID = max(JObID) from JobControl..Jobs


					--TBD?  RequiresSetup, SpecialId
					--      FileSourcePath, FileSourceExt, AllowMultipleFiles
					--		StepSubProcessID

					insert JobControl..JobSteps (VFPIn, JobID, StepName, StepOrder, StepTypeID, RunModeID
															, StepFileNameAlgorithm
															,VFP_QueryID, VFP_BTCRITID, VFP_LayoutID, VFP_ReportID, VFP_CALLPROC)
					 select 1, @NewJobTempID, jts.STEPDESC, ROW_NUMBER() OVER(ORDER BY jts.STEPID), coalesce(jst.StepTypeID,0), jm.ID
								, jts.filealgorithm
								, QueryID, BTCRITID, LayoutID, ReportID, CALLPROC
						from DataLoad..Jobs_JOBSTEMPL jt
								join DataLoad..Jobs_stepstempl jts on jts.JOBTEMPLID = jt.jobtemplid
								left outer join VFPJobs_Map_StepTypes mst on mst.VFPStepType = jts.STEPTYPE
								left outer join JobControl..JobStepTypes jst on jst.Code = mst.Code
								left outer join JobControl..JobModes jm on jm.Code = case when jts.STEPRUNMODE = '' then case when jt.JOBRUNMODE = '' then 'M' else jt.JOBRUNMODE end else jts.STEPRUNMODE end
								left outer join JobControl..Jobs wjt on wjt.IsTemplate = 1 and wjt.JobName = jt.jobdescrip and wjt.VFPIn = 1
							where jt.jobType = @JobType
								and case when jts.CALLPROC like '%SetInTable%' and jst.StepTypeID = 24 then 1
										when jts.CALLPROC like '%lpsmtgstats%' and jst.StepTypeID = 24 then 1
										else 0 end  = 0
						order by jts.STEPID

					update js set ReportListID = rm.ReportID
						from JobControl..JobSteps js
							join JobControl..VFPJobs_Map_Reports rm on rm.VFP_Report_ID = js.VFP_ReportID and coalesce(ReportID,0) > 0
						where js.VFPIn = 1 and js.StepTypeID = 22
							and js.JobID = @NewJobTempID

					update jsX set DependsOnStepIDs = jsPr.StepID
							from JobControl..JobSteps jsX 
								join JobControl..JobSteps jsPr on jsPr.StepOrder = (jsX.StepOrder - 1) and jsPr.JobID = jsX.JobID
						where jsX.VFPIn = 1
								and jsX.StepTypeID in (29,22,1)	-- 29 Xfrom, 22 Report, 1 Append
								and jsx.JobID = @NewJobTempID

					declare @LastTemplateID int = 0
					declare @NewFilePat varchar(2000)
					declare @TemplateID int, @StepID int, @StepTypeID int, @StepFileNameAlgorithm varchar(2000), @OutFileName varchar(2000), @ReportListID int, @Extension varchar(10)

					DECLARE curB CURSOR FOR
 						select x.StepID, x.JobID, x.StepTypeID, x.StepFileNameAlgorithm
								--, replace(replace(x.OutPath,'''',''),'\redp\output\','R:\Wired3\ReportsOut\') OutPath
								--, x.OutFileName
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
								join JobControl..Jobs j on j.JobID = js.JobID and j.IsTemplate = 1
								left outer join JobControl..Reports r on r.Id = js.ReportListId
							where js.VFPIn = 1
							) x
						order by x.JobID, x.StepOrder

					 OPEN curB

					 FETCH NEXT FROM curB into @StepID, @TemplateID, @StepTypeID, @StepFileNameAlgorithm, @ReportListID, @Extension
					 WHILE (@@FETCH_STATUS <> -1)
					 BEGIN
							set @StepFileNameAlgorithm = JobControl.dbo.VFPImport_StepFileNameCleanUp(@StepFileNameAlgorithm) 

							if ltrim(rtrim(@StepFileNameAlgorithm)) > ''
								begin
									set @NewFilePat = @StepFileNameAlgorithm
								end
							else
								begin
									if @LastTemplateID = @TemplateID and @ReportListID is not null
										update JobControl..JobSteps set StepFileNameAlgorithm = @NewFilePat + '.' + @Extension where StepID = @StepID
								end

							set @LastTemplateID = @TemplateID
						  FETCH NEXT FROM curB into @StepID, @TemplateID, @StepTypeID, @StepFileNameAlgorithm, @ReportListID, @Extension
					 END
					 CLOSE curB
					 DEALLOCATE curB

					select @cnt = count(*) from DataLoad..Jobs_JOBs where JobID = @JobID and ISSWEEK > ''
					update JobControl..Jobs set PromptIssueWeek = case when @cnt = 0 then 0 else 1 end where JobID = @NewJobTempID

					insert JobControl..VFPJobs_Params (JobTemplateID, ParamName, ParamVal)
						select @NewJobTempID, 'StateID' ParmName, s.Id ParmVal
								from DataLoad..Jobs_JOBSTEMPL jt
									join Lookups..States s on jt.CURSTATE = s.Code
									left outer join JobControl..VFPJobs_Params p on p.JobTemplateID = @NewJobTempID
															and p.ParamName = 'StateID'
															and p.ParamVal = s.Id
								where p.ParamVal is null
									and jt.curstate > ''
									and jt.jobType = @JobType

				end

---###############################################

	 				insert JobControl..Jobs (VFPIn, JobName, CategoryID, ModeID, RecurringTypeID, ProcessTypeID, JobTemplateID, VFPJobID
										, PromptState
										, PromptIssueWeek
										, PromptIssueMonth
										, PromptCalYear
										, PromptCalPeriod )
						select 1, j.jobdescrip, jc.ID, jm.ID, jrt.ID, 4, @NewJobTempID, @JobID
										, case when j.CURSTATE > '' then 1 else 0 end
										, case when j.ISSWEEK > '' then 1 else 0 end
										, case when j.ISSMONTH > '' then 1 else 0 end
										, case when j.CALYEAR > '' then 1 else 0 end
										, case when j.CALPERIOD > '' then 1 else 0 end
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
															,VFP_QueryID, VFP_BTCRITID, VFP_LayoutID, VFP_ReportID, VFP_CALLPROC)
					 select 1, @NewJobID, js.STEPDESC, ROW_NUMBER() OVER(ORDER BY js.STEPID), coalesce(jst.StepTypeID,0), jm.ID
								, js.filealgorithm
								, QueryID, BTCRITID, LayoutID, ReportID, CALLPROC
						from DataLoad..Jobs_JOBS j
								join DataLoad..Jobs_jobsteps js on js.JOBID = j.jobid
								left outer join VFPJobs_Map_StepTypes mst on mst.VFPStepType = js.STEPTYPE
								left outer join JobControl..JobStepTypes jst on jst.Code = mst.Code
								left outer join JobControl..JobModes jm on jm.Code = case when js.STEPRUNMODE = '' then case when j.JOBRUNMODE = '' then 'M' else j.JOBRUNMODE end else js.STEPRUNMODE end
								left outer join JobControl..Jobs wjt on wjt.IsTemplate = 1 and wjt.JobName = j.jobdescrip and wjt.VFPIn = 1
							where j.JOBID = @JobID
								and js.ReportID <> 'nullmailer'
								and case when js.CALLPROC like '%SetInTable%' and jst.StepTypeID = 24 then 1
										 when js.CALLPROC like '%lpsmtgstats%' and jst.StepTypeID = 24 then 1
										else 0 end  = 0
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
						union select @NewJobID, 'TownID' ParmName, ltrim(str(t.Id)) ParmVal
								from DataLoad..Jobs_JOBs j
									join Lookups..States s on j.CURSTATE = s.Code
									join Lookups..Towns t on t.State = s.Code and t.Code = j.TOWN
								where j.TOWN > ''
									and j.jobID = @JobID
						union select @NewJobID, 'IssueWeek' ParmName, j.ISSWEEK
								from DataLoad..Jobs_JOBs j
								where j.ISSWEEK > ''
									and j.jobID = @JobID
						union select @NewJobID, 'IssueMonth' ParmName, j.ISSMONTH
								from DataLoad..Jobs_JOBs j
								where j.ISSMONTH > ''
									and j.jobID = @JobID
						union select @NewJobID, 'CalPeriod' ParmName, j.CALPERIOD
								from DataLoad..Jobs_JOBs j
								where j.CALPERIOD > ''
									and j.jobID = @JobID
						union select @NewJobID, 'CalYear' ParmName, j.CALYEAR
								from DataLoad..Jobs_JOBs j
								where j.CALYEAR> ''
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
									update JobControl..JobSteps set StepFileNameAlgorithm = @StepFileNameAlgorithm + '.' + @Extension where StepID = @StepID
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
	select distinct jt.ShortTransformationName
		from JobControl..TransformationTemplates jt
			left outer join VFPJobs_TemplateStatus ts on ts.ShortTransformationName = jt.ShortTransformationName
	where jt.VFPin = 1
		and ts.RecID is null


	truncate table JobControl..VFPJobs_Query_Conds 

	declare @NewQueryID int
	declare @WhereClause varchar(max)
	declare @VFP_QueryID varchar(100), @QueryTemplateID int

	DECLARE curB CURSOR FOR
		
		select q.VFP_QueryID, max(coalesce(qtf.QueryTemplateID,fc.QueryTemplateID)), q.JobID, q.TemplateID, q.StepID
			from (
					select VFP_QueryID, JobID, null TemplateID, StepID from JobControl..JobSteps where VFPIn = 1 and VFP_QueryID > ''
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
			
			select @WhereClause = Support.FuncLib.StringFromTo(Support.FuncLib.CleanVFPInfo(SELECTEXP1,'QuerySelect'),'Where','',1) 
								+ Support.FuncLib.StringFromTo(Support.FuncLib.CleanVFPInfo(SELECTEXP2,'QuerySelect'),'Where','',1) 
								+ Support.FuncLib.StringFromTo(Support.FuncLib.CleanVFPInfo(SELECTEXP2,'QuerySelect'),'and','',1)
				from DataLoad..Jobs_MF_query 
					where QUERY_ID = @VFP_QueryID		

			insert JobControl..VFPJobs_Query_Conds ( QUERY_ID, Cond)
				select @VFP_QueryID, case when ltrim(x.value) like 'where %' then substring(ltrim(x.value), 7,1000) else ltrim(x.value) end
					from Support.FuncLib.SplitString(@WhereClause,' and ') x
						left outer join JobControl..VFPJobs_Query_Conds qc on qc.QUERY_ID = @VFP_QueryID and qc.Cond = case when ltrim(x.value) like 'where %' then substring(ltrim(x.value), 7,1000) else ltrim(x.value) end
					where qc.QUERY_ID is null

			update JobControl..JobSteps 
				set QueryCriteriaID = @NewQueryID
					, QueryTemplateID = @QueryTemplateID
				where StepID = @StepID

          FETCH NEXT FROM curB into @VFP_QueryID, @QueryTemplateID, @JobID, @TemplateID, @StepID
     END
     CLOSE curB
     DEALLOCATE curB

	update QueryEditor..Queries 
	set TransTypeSales = case when TemplateID in (1,2,1056) then 1 else 0 end 
		, TransTypeMortgages = case when TemplateID in (1,3,1056) then 1 else 0 end
	where VFPIn = 1

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

	  insert JobControl..JobParameters (JobID, ParamName, ParamValue, VFPIn)
	   select distinct np.JobID, np.ParamName, np.ParamVal, 1 
			from JobControl..VFPJobs_Params np
				left outer join JobControl..JobParameters jp on np.JobID = jp.JobID
																and np.ParamName = jp.ParamName
																and np.ParamVal = jp.ParamValue
																and jp.VFPIn = 1
			where np.ParamName in ('StateID','TownID','CountyID','IssueWeek', 'IssueMonth', 'CalPeriod', 'CalYear')
				and jp.ParmRecID is null

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
			) x
		join DataLoad..Jobs_MF_btcritss bc on bc.FUNCTIONID = x.VFP_BTCRITID and bc.CMDLINE like '%bctv_crit=%'
		join QueryEditor..Queries q on q.Id = x.QueryCriteriaID

     OPEN CurB

     FETCH NEXT FROM CurB into @TemplateID, @CmdLine, @VFP_BTCRITID, @VFP_QueryID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

		print 'A: ' + ltrim(str(@TemplateID)) + '|' + @CmdLine + '|' + @VFP_BTCRITID + '|' + @VFP_QueryID

			insert JobControl..VFPJobs_Map_BitCritToConds (TemplateID, cond, FullOrigCond)
			select @TemplateID, case when charindex(' and ',@CmdLine) = 0 then @CmdLine else x.value end, @CmdLine 
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

			print 'B: ' + ltrim(str(@RecID)) + '|' + ltrim(str(@TemplateID)) + '|' + @Cond

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
				-- TBD Join			Not yet
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
								union
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
							if isnumeric(@NewCondValue) = 1
								set @cmd = 'update QueryEditor..Queries set ' + @NewCondField + ' = ' + @NewCondValue + ' where TemplateID = ' + ltrim(str(@TemplateID)) + ' and VFPIn = 1'
							else
								set @cmd = 'update QueryEditor..Queries set ' + @NewCondField + ' = ''' + @NewCondValue + ''' where TemplateID = ' + ltrim(str(@TemplateID)) + ' and VFPIn = 1'

							exec(@cmd)
						end
				end
			  FETCH NEXT FROM curB into @TemplateID, @NewCondPlace, @NewCondType, @NewCondField, @NewCondNot, @NewCondSymbol, @NewCondValue, @OrRecID, @OrigCond, @COrRecID, @XRecID
		 END
		 CLOSE curB
		 DEALLOCATE curB

		 -- Force delete Moditype for some listed VFPJObs
			insert QueryEditor.. QueryMultIDs (VFPIn, QueryID, ValueSource, ValueID, Exclude)
			select distinct 1, q.ID, 'ModificationType', 3, 0
				from QueryEditor..Queries q 
				where VFP_QueryID in ('XLFADelAsn','XLFADelDIS')


	------------------------------------------------------------------------------------------------

	 -- For every job Clone Query of JobTemplate into new query in Job
	 -- Add Job State Location to Query (JobParam)
	 -- Add Job County Location to Query (JobParam)
	 -- Add Issueweek to Query (JobParam)

		declare @QueryCriteriaId int, @QueryTypeID int, @JobTemplateID int

		DECLARE curB CURSOR FOR
		
		select js.QueryCriteriaId, qt.QueryTypeID, j.JobTemplateID, j.JobID
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

				insert QueryEditor..QueryLocations (QueryID, StateID, TownID, VFPIn)
				select @QueryCriteriaId
						, case when ParamName = 'StateID' then ParamVal else null end
						, case when ParamName = 'TownID' then ParamVal else null end
						, 1
					from JobControl..VFPJobs_Params
					where JobTemplateID = @JobTemplateID and ParamName in ('StateID','TownID')

				insert QueryEditor..QueryLocations (QueryID, StateID, TownID, VFPIn)
				select @QueryCriteriaId
						, case when ParamName = 'StateID' then ParamVal else null end
						, case when ParamName = 'TownID' then ParamVal else null end
						, 1
					from JobControl..VFPJobs_Params
					where JobID = @JobID and ParamName in ('StateID','TownID')

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

		 insert QueryEditor..QueryLocations (QueryID, townID, VFPIn)
			select njs.QueryCriteriaID, t.Id, 1
				from JobControl..Jobs nj
					join JobControl..JobSteps njs on njs.jobID = nj.JobID and njs.StepTypeID = 21
					join DataLoad..Jobs_jobsteps ojs on nj.VFPJobID = ojs.JOBID
					join DataLoad..Jobs_jobs oj on oj.JOBID = ojs.JOBID
					join DataLoad..Jobs_MF_query q on q.QUERY_ID = ojs.QUERYID
					join Lookups..Towns t on t.Code = oj.TOWN
				where SELECTEXP2 = 'select2mtdtwn()'

		 insert QueryEditor..QueryRanges (QueryID, RangeSource, MinValue, MaxValue, VFPIn)
			select njs.QueryCriteriaID, 'TransPriceRange', '1000', null, 1
				from JobControl..Jobs nj
					join JobControl..JobSteps njs on njs.jobID = nj.JobID and njs.StepTypeID = 21
					join DataLoad..Jobs_jobsteps ojs on nj.VFPJobID = ojs.JOBID
					join DataLoad..Jobs_jobs oj on oj.JOBID = ojs.JOBID
					join DataLoad..Jobs_MF_query q on q.QUERY_ID = ojs.QUERYID
					join Lookups..Towns t on t.Code = oj.TOWN
				where SELECTEXP2 = 'select2mtdtwn()'


	 -- TBD Merge multiple appended county steps into 1 job step
	 -- TBD Merge multiple appended state Jobs into 1 job
	 -- TBD Deal with Customer ID (Maybe not here but need to be addressed)

	 declare @NewXFromID int, @NewLayoutID int, @VFPXFormShell varchar(100)
	 declare @VFPLayoutID varchar(50)

		DECLARE curB CURSOR FOR
		
		select jsX.VFP_LayoutID, Max(Q.TemplateID)
			from JobControl..JobSteps jsQ
				join JobControl..JobSteps jsX on jsX.StepTypeID = 29 and (jsQ.StepOrder + 1) = jsX.StepOrder 
													and jsQ.JobID = jsX.JobID 
				join QueryEditor..Queries Q on Q.ID = jsQ.QueryCriteriaID
			where jsQ.VFPIn = 1
				and jsQ.StepTypeID = 21
				and ltrim(rtrim(jsX.VFP_LayoutID)) > ''
			group by jsX.VFP_LayoutID

		 OPEN curB

		 FETCH NEXT FROM curB into @VFPLayoutID, @QueryTemplateID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

				insert JobControl..TransformationTemplates (VFPIn, ShortTransformationName, Description, QueryTemplateID)
					values (1, @VFPLayoutID, @VFPLayoutID + ' Imported from VFP'
						, case when @VFPLayoutID in ('XPGalley') then 1056
								when @VFPLayoutID in ('XSCrBkLn') then 1057
								when @VFPLayoutID in ('XLDTPreFc','XLFADTPf','XLNICPreFc','XPGalleyCr','XSCrFrcls') then 6 
								else @QueryTemplateID end)
				
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
													, OutType
													, OutWidth, DecimalPlaces
													, SrcName
													, OutName)
				select 1, @NewLayoutID, s.FieldOrder
						, 0, 0, 0, 'None', 0, 'None', 0, null
						, s.FieldType
						, case when s.FieldType in ('char') then s.FieldLength 
								when s.FieldType in ('decimal') then s.FieldPrecision
								else 0 end
						, s.FieldScale
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
				insert JobControl..FileLayoutFields (FileLayoutID, VFPIn, OutOrder, SortDir, SrcName, OutName, OutType, OutWidth, Disabled, CaseChange, DoNotTrim, Padding, PaddingLength)
					select lf.FileLayoutID, 1, max(OutOrder)+1, '0', 'XF_IsCondo', 'IsCondo','bit',0,0,'None',0,'None',0
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

			update js set ReportListID = rm.ReportID
				from JobControl..JobSteps js
					join JobControl..VFPJobs_Map_Reports rm on rm.VFP_Report_ID = js.VFP_ReportID and coalesce(ReportID,0) > 0
				where js.VFPIn = 1 and js.StepTypeID = 22

drop table JobControl..JobSteps_Test
select * 
	into JobControl..JobSteps_Test
	from JobControl..JobSteps
	--where JobID in (208,209,210,211,213,214,217)


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

		update tc set SourceCode = 'case when x.MtgPropUsage = ''102'' then 1 else 0 end'
			from JobControl..TransformationTemplates tt
				join JobControl..TransformationTemplateColumns tc on tt.Id = tc.TransformTemplateID
			where tt.ShortTransformationName = 'XPMTD'
				and OutName = 'IsCondo'

		drop table #JobsToDo

-- Clean up blank step names

	update JobControl..JobSteps
			set StepName = '--Blank Step Name--'
		 where ltrim(coalesce(StepName,'')) = ''

-- Specal Steps Control file Convert to Report
 
	update jss set StepTypeID = 1101, StepFileNameAlgorithm = JobControl.dbo.VFPImport_FileExtSwap(jsr.StepFileNameAlgorithm, cf.FileExt)
			, StepName = case when jss.StepName not like 'AutoChg-%' then 'AutoChg-' + jss.StepName else jss.StepName end
			, DependsOnStepIDs = jst.stepID
			, SpecialID = cf.ControlID
			, ReportListID = cf.ReportID
		from JobControl..JobSteps jss
			join JobControl..JobSteps jsr on jss.JOBID = jsr.JOBID and jsr.StepTypeID = 22 and jss.StepOrder = (jsr.StepOrder + 1)
			join JobControl..JobSteps jst on jss.JOBID = jst.JOBID and jst.StepTypeID = 29 and jsr.StepOrder = (jst.StepOrder + 1)
			join JobControl..JobSteps jsq on jss.JOBID = jsq.JOBID and jsq.StepTypeID = 21 and jst.StepOrder = (jsq.StepOrder + 1)
			join JobControl..VFPJobs_Special_CtlFiles cf on cf.VFP_Callproc = jss.VFP_CALLPROC
		where jss.StepTypeID in (24,1101)

exec JobControl..VFPJobs_AdjustMergeJobs

-- Add Zip Steps

	insert JobControl..JobSteps (JobID, StepName, StepOrder, StepTypeID, RunModeID, StepFileNameAlgorithm, VFPIn, UpdatedStamp, CreatedStamp)
		select z.JobID, 'Zip File(s)', MaxStep + 1, 1079, 1, z.ZipName, 1, getdate(), getdate()
			from (
				select x.JobID, max(ZipName) ZipName
					from (
						select j.JobID, JobControl.dbo.VFPImport_StepFileNameCleanUp(jd.zipname) ZipName
							from JobControl..Jobs j
								join DataLoad..Jobs_delivery jd on jd.jobid = j.VFPJobID
							where zipped = 'True'
							) x

					group by x.JobID
				) z
			join (select max(StepOrder) MaxStep, JobID from JobControl..JobSteps Group By JobID) ms on ms.JobID = z.JobID

	update s set StepFileNameAlgorithm = NewZipName
		from JobControl..JobSteps s
			join (
				select distinct zs.JobID, zs.StepID
						, case when ltrim(js.StepFileNameAlgorithm) = '' then 'R:\Wired3\ReportsOut\J' + ltrim(str(zs.JobID)) + '_S' + ltrim(str(zs.StepID)) + '.ZIP' 
								when ltrim(zs.StepFileNameAlgorithm) = '' then left(js.StepFileNameAlgorithm,charindex('.',js.StepFileNameAlgorithm)-1) + '.ZIP'
							else left(js.StepFileNameAlgorithm,(len(js.StepFileNameAlgorithm) - charindex('\',reverse(js.StepFileNameAlgorithm)))+1) + zs.StepFileNameAlgorithm + '.ZIP' end NewZipName
					from JobControl..JobSteps js
						join JobControl..JobSteps zs on zs.JobID = js.JobID and zs.StepTypeID = 1079
					where js.StepTypeID = 22
						and js.JobID in (select JobID from JobControl..JobSteps where StepTypeID = 1079)
				) x on x.StepID = s.StepID

     declare @ZipStepID int
     DECLARE CurZipSteps CURSOR FOR

		select js.JobID, js.StepID, js.StepOrder, zs.StepID
			from JobControl..JobSteps js
				join JobControl..JobSteps zs on zs.JobID = js.JobID and zs.StepTypeID = 1079 and zs.VFPIn = 1
			where js.StepTypeID = 22 and js.VFPIn = 1
			order by js.JobID, js.StepOrder

     OPEN CurZipSteps

     FETCH NEXT FROM CurZipSteps into @JobID, @StepID, @StepOrder, @ZipStepID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
		
			update JobControl..JobSteps 
				set DependsOnStepIDs = coalesce(DependsOnStepIDs,'') + case when coalesce(DependsOnStepIDs,'') > '' then ',' else '' end + trim(str(@StepID))
				where StepID = @ZipStepID

          FETCH NEXT FROM CurZipSteps into @JobID, @StepID, @StepOrder, @ZipStepID
     END
     CLOSE CurZipSteps
     DEALLOCATE CurZipSteps

-- Add Deliver Steps

	--delete JobControl..JobSteps where VFPIn = 1 and StepTypeID = 1091

	insert JobControl..JobSteps (JobID, StepName, StepTypeID, RunModeID, DeliveryTypeID, VFPIn, UpdatedStamp, CreatedStamp, SendDeliveryConfirmationEmail, StepOrder)
		select x.JobID, x.StepName, 1091, 3, x.DeliveryTypeID, 1, getdate(), getdate(), case when x.DeliveryTypeID = 2 then 1 else 0 end
				, MaxStep + ROW_NUMBER() OVER (PARTITION BY x.JobID ORDER BY x.DeliveryTypeID)
			from (
				select distinct j.JobID, 'Deliver File(s) by ' + dt.Description StepName, dt.ID DeliveryTypeID
					from JobControl..Jobs j
						join DataLoad..Jobs_delivery jd on jd.jobid = j.VFPJobID
						join JobControl..DeliveryTypes dt on dt.code = case when jd.delivtype = 'EXT' then 'FTP' else jd.delivtype end
					) x
				join (select max(StepOrder) MaxStep, JobID from JobControl..JobSteps Group By JobID) ms on ms.JobID = x.JobID 

     declare @DelivStepID int
     DECLARE curA CURSOR FOR

		select js.JobID, js.StepID, js.StepOrder, zs.StepID
			from JobControl..JobSteps js
				join JobControl..JobSteps zs on zs.JobID = js.JobID and zs.StepTypeID = 1091
			where js.StepTypeID = 22
				and js.JobID not in (select JobID from JobControl..JobSteps where StepTypeID = 1079)
		union select js.JobID, js.StepID, js.StepOrder, zs.StepID
			from JobControl..JobSteps js
				join JobControl..JobSteps zs on zs.JobID = js.JobID and zs.StepTypeID = 1091
			where js.StepTypeID = 1079
		order by js.JobID, js.StepOrder

     OPEN curA

     FETCH NEXT FROM curA into @JobID, @StepID, @StepOrder, @DelivStepID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
		
			update JobControl..JobSteps 
				set DependsOnStepIDs = coalesce(DependsOnStepIDs,'') + case when coalesce(DependsOnStepIDs,'') > '' then ',' else '' end + trim(str(@StepID))
				where StepID = @DelivStepID

          FETCH NEXT FROM curA into @JobID, @StepID, @StepOrder, @DelivStepID
     END
     CLOSE curA
     DEALLOCATE curA

	 -- Clean Up Duplicates in QueryEditor..QueryLocations 
		 Declare @RecsDel int = 99
		 while @RecsDel > 0
		 begin
			delete QL 
				from QueryEditor..QueryLocations QL
					join ( select QueryID, StateID, CountyID, Max(ID) MaxID
								from QueryEditor..QueryLocations
									where (StateID is not null or CountyID is not null) and VFPIn = 1
							group by QueryID, StateID, CountyID
							having count(*) > 1 ) x on x.MaxID = QL.ID

			set @RecsDel = @@ROWCOUNT
			print @RecsDel
		end	

   -- Fix Special Report Steps

	   update js set StepName = x.StepName
				, StepTypeID = x.StepTypeID
				, ReportListID = x.ReportListID
				, StepFileNameAlgorithm = x.StepFileNameAlgorithm
		from JobControl..JobSteps js
			join (
				select j.JobID, j.VFPJobID, js.StepID
		
						, 'Special Report ' + Replace(Replace(CALLPROC,'Do Special.app with "',''),'", oJC.OutTable','') StepName
						, 22 StepTypeID
						, 39 ReportListID
							, case when CALLPROC like '%GalleyRpt%' and OutTable like '%\BT\AllReg%' then 'R:\Wired3\ReportsOut\Products\BT\AllRegistries_<MMDDYYYY>.TXT'
									when CALLPROC like '%GalleyRpt%' and OutTable like '%\BT\%' then 'R:\Wired3\ReportsOut\Products\BT\<CN>_<MMDDYYYY>.TXT'
									when CALLPROC like '%GalleyRpt%' and OutTable not like '%\BT\%' then 'R:\Wired3\ReportsOut\Products\<ST>\<CN>_<MMDDYYYY>.TXT'
									when CALLPROC like '%GalleyCreditRpt%' then LEFT(JobControl.dbo.VFPImport_StepFileNameCleanUp(OutTable),LEN(JobControl.dbo.VFPImport_StepFileNameCleanUp(OutTable)) - 10) + '_<MMDDYYYY>.TXT'
									when CALLPROC like '%galleysalesnh%' then 'R:\Wired3\ReportsOut\Products\RR\RegistryReview_SalesRecs_<MMDDYYYY>.TXT'
								else '' end StepFileNameAlgorithm

					from JobControl..Jobs j
						join ( select distinct JobID from DataLoad..Jobs_jobsteps  
									where CALLPROC in ('Do Special.app with "GalleyCreditRpt", oJC.OutTable',
										'Do Special.app with "GalleyRpt", oJC.OutTable',
										'Do Special.app with "galleysalesnh", oJC.OutTable',
										'Do Special.app with "SunChronicle", oJC.OutTable',
										'Do special with ''lpsmtgstats'',oJC.outtable')
							) x on x.JOBID = j.VFPJobID 

						join JobControl..JobSteps js on js.JobID = j.JobID
						join JobControl..JobStepTypes jst on jst.StepTypeID = js.StepTypeID
						join DataLoad..Jobs_jobsteps vjs on vjs.JOBID = x.JOBID
							and jst.StepName =  vjs.STEPTYPE
							and js.StepOrder = vjs.STEPID
							and vjs.CALLPROC like '%oJC.outtable%'
				) x on x.StepID = js.STEPID

-- Manual fix of file names
	update js set StepFileNameAlgorithm = REPLACE(StepFileNameAlgorithm ,'<TBLN>',UseTbl)
		from JobControl..JobSteps js
			join JobControl..Jobs j on j.JobID = js.JobID
			join ( select 1559 VFPJobID,'BROC' UseTbl
					 union select 1561 VFPJobID,'BROC' UseTbl
					 union select 1567 VFPJobID,'WORC' UseTbl
					 union select 1572 VFPJobID,'HometownWeekly' UseTbl
					 union select 1573 VFPJobID,'BEAC' UseTbl
					 union select 1576 VFPJobID,'NBHE' UseTbl
					 union select 1580 VFPJobID,'CAPE' UseTbl
					 union select 1625 VFPJobID,'EagleTrib' UseTbl
					 union select 1645 VFPJobID,'STDT-Res' UseTbl
					 union select 1669 VFPJobID,'NEWH' UseTbl
					 union select 3121 VFPJobID,'GRML' UseTbl
					 union select 3462 VFPJobID,'HUPM' UseTbl
					 union select 3463 VFPJobID,'HUPR' UseTbl
					 union select 3464 VFPJobID,'INPG' UseTbl
					 union select 3555 VFPJobID,'PATS' UseTbl
					 union select 3657 VFPJobID,'GUARD' UseTbl
					 union select 5093 VFPJobID,'WSNC' UseTbl
					 union select 5094 VFPJobID,'WSNR' UseTbl
					 union select 8286 VFPJobID,'SHOR' UseTbl
					 union select 9425 VFPJobID,'CRNC' UseTbl
					 union select 21167 VFPJobID,'DUXB' UseTbl
					 union select 25762 VFPJobID,'NPDN' UseTbl
					 union select 35753 VFPJobID,'BEAH' UseTbl
					 union select 57682 VFPJobID,'ESBN' UseTbl
					 union select 59855 VFPJobID,'ESBM' UseTbl
					 union select 63332 VFPJobID,'wand' UseTbl
					 union select 64809 VFPJobID,'BEA3' UseTbl
					 union select 66646 VFPJobID,'theday' UseTbl
					 union select 66770 VFPJobID,'NPIN' UseTbl
					 union select 67244 VFPJobID,'stow2' UseTbl
					 union select 67610 VFPJobID,'WOBTIM' UseTbl
					 union select 69276 VFPJobID,'BOST2' UseTbl
					 union select 69405 VFPJobID,'FALMPUB' UseTbl
					 union select 74295 VFPJobID,'rarer' UseTbl
					 union select 85423 VFPJobID,'SalemNews' UseTbl
					 union select 87061 VFPJobID,'DNNewbypt' UseTbl
					 union select 88167 VFPJobID,'GloucesterDT' UseTbl
					 union select 110830 VFPJobID,'BerkEagle' UseTbl
					 union select 130475 VFPJobID,'AndoverTM' UseTbl
					 union select 130480 VFPJobID,'HaverhillG' UseTbl
					 union select 134063 VFPJobID,'HoldenLndMk' UseTbl
					 union select 135793 VFPJobID,'DerryNews' UseTbl
					 union select 135795 VFPJobID,'EagleTribNH' UseTbl
					 union select 141301 VFPJobID,'MilfCabPr' UseTbl
					 union select 138512 VFPJobID,'BerkshireEdge_CT' UseTbl
					 union select 138096 VFPJobID,'BerkshireEdge_MA_Wk' UseTbl
					 union select 141304 VFPJobID,'InterTwnRec' UseTbl
					 union select 141307 VFPJobID,'KeeneSentnl' UseTbl
					 union select 141310 VFPJobID,'SalmonPress' UseTbl
					 union select 141312 VFPJobID,'ConcordMon' UseTbl
					 union select 141323 VFPJobID,'UnionLeader' UseTbl
					 union select 141315 VFPJobID,'NashTelegra' UseTbl
					 union select 141317 VFPJobID,'ValleyNews' UseTbl
					 union select 143309 VFPJobID,'ReminderPub' UseTbl
					 union select 143308 VFPJobID,'ReminderPb' UseTbl
					 union select 143522 VFPJobID,'AdvocateNews' UseTbl
					 union select 147800 VFPJobID,'BerkshireEdge_COM_CT' UseTbl
					 union select 147802 VFPJobID,'BerkshireEdge_COM_MA' UseTbl
					 union select 148124 VFPJobID,'JacobsDavid' UseTbl
					 union select 159038 VFPJobID,'DolbeaGlenn' UseTbl
					 union select 169932 VFPJobID,'AndersDebor' UseTbl
				) x on x.VFPJobID = j.VFPJobID
		where StepFileNameAlgorithm like '%<TBLN>%'


-- Fix Jobs with Alt Layouts ---------------------------

	declare @Report_ID varchar(50)
	declare @VFP_LayoutID varchar(50)
	declare @TransformationID int
	declare @FileLayoutID int
	declare @XFormStepID int
	declare @QueryStepID int
	declare @FieldList varchar(max)
	declare @ForCond varchar(max)

	set @LastJobID = -1
	declare @LastFieldList varchar(max)  = 'ZZZZZZZZZZZZZZZZZZZZZZ'
	declare @JobStepCount int = 0
	declare @NewFieldList bit = 0
	set @NewLayoutID = 0
	declare @NewStepID int = 0
	         
	DECLARE curXFormLayout CURSOR FOR
		select Report_ID
				, js2.VFP_LayoutID
				, js2.TransformationID
				, js2.FileLayoutID
				, js.ReportListID
				, js.JobID
				, js.StepOrder
				, js.StepID
				, js2.StepID XFormStepID
				, js3.StepID QueryStepID
				, ltrim(substring(case when OUTPOPTEXP like '% for %' then Support.FuncLib.StringFromTo(OUTPOPTEXP,'fields',' for ',0)
						when OUTPOPTEXP like '% delimited %' then Support.FuncLib.StringFromTo(OUTPOPTEXP,'fields',' delimited ',0)
						when OUTPOPTEXP like '% with %' then Support.FuncLib.StringFromTo(OUTPOPTEXP,'fields',' with ',0)
						when OUTPOPTEXP like '% type %' then Support.FuncLib.StringFromTo(OUTPOPTEXP,'fields',' type ',0)
					else Support.FuncLib.StringFromTo(OUTPOPTEXP,'fields',null,0) end,7,2000)) FieldList
				, ltrim(substring(case when OUTPOPTEXP like '% for %' then Support.FuncLib.StringFromTo(OUTPOPTEXP,'for','type',1)
					else Support.FuncLib.StringFromTo(OUTPOPTEXP,'for',null,1) end,6,2000)) ForCond
			from DataLoad..Jobs_MF_reportdf rd
				join Jobcontrol..JobSteps js on js.VFP_ReportID = rd.REPORT_ID
				join Jobcontrol..JobSteps js2 on js2.JobID = js.jobID and JobControl.dbo.GetDependsJobStepID(js.StepID) = js2.StepID
				join Jobcontrol..JobSteps js3 on js3.JobID = js.jobID and JobControl.dbo.GetDependsJobStepID(js2.StepID) = js3.StepID
			where OUTPOPTEXP like '%fields%'
				and OUTPOPTEXP not like '% except %'
				--and Report_ID = 'XLHtCrWeb'
				--and js.JobID in (115,116,596,620)

		order by js2.TransformationID, js2.FileLayoutID, js.JobID, js.StepOrder

	OPEN curXFormLayout

	FETCH NEXT FROM curXFormLayout into @Report_ID, @VFP_LayoutID, @TransformationID, @FileLayoutID
									, @ReportListID, @JobID, @StepOrder, @StepID, @XFormStepID, @QueryStepID, @FieldList, @ForCond
	WHILE (@@FETCH_STATUS <> -1)
		BEGIN

--Print '##(a) ' + ltrim(str(@JobStepCount)) + '|' + case when @NewFieldList = 1 then '1' else '0' end
--Print '##(b) ' + ltrim(str(@LastJobID)) + '|' + ltrim(str(@JobID))

			if @LastJobID <> @JobID
				set @JobStepCount = 0

			if @LastFieldList <> @FieldList
				set @NewFieldList = 1

			if @NewFieldList = 1
			begin
				Print '------------------------------------------------------'
				Print 'JobID: ' + ltrim(str(@JobID))
				Print 'Create New Layout for XFrom: ' + ltrim(str(@TransformationID)) + ' with [' + @FieldList + ']'

				insert JobControl..FileLayouts (TransformationTemplateId, ShortFileLayoutName, Description, DefaultLayout, VFPIn)
					values (@TransformationID, 'Alt-' + @Report_ID, 'Alt-' + @Report_ID + ' Imported from VFP',0,1)

				select @NewLayoutID = max(ID) from JobControl..FileLayouts

				insert JobControl..FileLayoutFields (FileLayoutID, OutOrder, SortOrder, SortDir, OutType, OutWidth, SrcName, OutName
													, Disabled, CaseChange, DoNotTrim, Padding, PaddingLength, PaddingChar
													, VFPIn, DecimalPlaces)
				select @NewLayoutID, n.seq, case when n.seq = 1 then 1 else 0 end, 0, lf.OutType, OutWidth, SrcName, OutName
						, Disabled, CaseChange, DoNotTrim, Padding, PaddingLength, PaddingChar, VFPIn, DecimalPlaces
					from Support.FuncLib.SplitString(@FieldList,',') n
						left outer join JobControl..FileLayoutFields lf on lf.FileLayoutID = @FileLayoutID and n.Value = lf.OutName 

			end

			if @JobStepCount = 0
				begin
					Print 'Update StepID: ' + ltrim(str(@XFormStepID)) + ' seting FileLayoutID to new Layout ID' 
					update Jobcontrol..JobSteps set FileLayoutID = @NewLayoutID where StepID = @XFormStepID
				end
			else
				begin
					Print 'Add(a) XFrom Step with new Layout ID and XFrom: ' + ltrim(str(@TransformationID))
					Print '   before report step StepID: ' + ltrim(str(@StepID))
					print '   with Depends on Set to Query StepID: ' + ltrim(str(@QueryStepID))
					Print '   set report step StepID: ' + ltrim(str(@StepID)) + ' to Depends on New XForm Step ID'

					insert Jobcontrol..JobSteps (JobID, StepName, StepTypeID, RunModeID, TransformationID, FileLayoutID, VFPIn, DependsOnStepIDs)
						 values (@JobID, 'AltXForm-' + @Report_ID, 29, 1, @TransformationID, @NewLayoutID, 1, @QueryStepID)

					select @NewStepID = max(StepID) from Jobcontrol..JobSteps where JobID = @JobID

					update Jobcontrol..JobSteps set DependsOnStepIDs = @NewStepID
						where StepID = @StepID

					update js set StepOrder = x.NewSeq
						from Jobcontrol..JobSteps js
							join (select StepID
										, ROW_NUMBER() OVER (ORDER BY case when StepID = @NewStepID then 2 
																			when StepOrder < (select StepOrder from Jobcontrol..JobSteps where StepID = @StepID) then 1 
																			else 3 end, StepOrder) NewSeq
										, StepOrder
								from Jobcontrol..JobSteps
								where JobID = @JobID ) x on x.StepID = js.StepID										 

				end

			set @LastJobID = @JobID
			set @LastFieldList = @FieldList
			set @JobStepCount = @JobStepCount + 1
			set @NewFieldList = 0

			FETCH NEXT FROM curXFormLayout into @Report_ID, @VFP_LayoutID, @TransformationID, @FileLayoutID
											, @ReportListID, @JobID, @StepOrder, @StepID, @XFormStepID, @QueryStepID, @FieldList, @ForCond
		END
	CLOSE curXFormLayout
	DEALLOCATE curXFormLayout

-- End Fix Jobs with Alt Layouts ---------------------------


-- Fixes <TBLN> that is the customer issues
	update js set StepFileNameAlgorithm = replace(replace(js.StepFileNameAlgorithm,'<TBLN>',substring(replace(x.OUTTABLE,'\redp\output\Products\MTDE\',''), 1, len(replace(x.OUTTABLE,'\redp\output\Products\MTDE\','')) - 9)), '<IM2>','<TMY>')
		from JobControl..JobSteps js
			join JobControl..Jobs j on j.JobID = js.JobID
			join (select j.jobid, js.OUTTABLE
						from DataLoad..Jobs_jobsteps js
							join DataLoad..Jobs_jobs j on j.JOBID = js.JOBID
						where FILEALGORITHM like '%\MTDE\%' ) x on x.JOBID = j.VFPJobID
		where js.StepFileNameAlgorithm like '%\MTDE\%'
			and js.StepFileNameAlgorithm like '%<TBLN>%'

	update jsx set StepFileNameAlgorithm = y.newAlgo
		from JobControl..Jobsteps jsx
			join (
				select distinct z.VFPJOBID, z.JobID, z.StepID
						, case when StepFileNameAlgorithm like '%<IfProp|pr|tx>%' then Right(JobControl.dbo.VFPImport_TBLNCleanUp(z.core),4)
							else JobControl.dbo.VFPImport_TBLNCleanUp(z.core) end newcore
						, case when StepFileNameAlgorithm like '%<IfProp|pr|tx>%' then replace(StepFileNameAlgorithm,'a<TBLN>',Right(JobControl.dbo.VFPImport_TBLNCleanUp(z.core),4))
							else left(StepFileNameAlgorithm,len(StepFileNameAlgorithm) - charindex('\',REVERSE(StepFileNameAlgorithm)) + 1)
								+ JobControl.dbo.VFPImport_TBLNCleanUp(z.core)
								+ Right(StepFileNameAlgorithm,4)
							end newAlgo
						, StepFileNameAlgorithm
					from (
					select distinct x.JOBID VFPJOBID, j.JobID, js.StepID
							, x.OutTable
							, js.StepFileNameAlgorithm
							, case when charindex('.',x.OutTable) > 0 then
									substring(replace(x.OUTTABLE,left(x.OUTTABLE,len(x.OUTTABLE) - charindex('\',REVERSE(x.OUTTABLE)) + 1),''),1, len(rtrim(replace(x.OUTTABLE,left(x.OUTTABLE,len(x.OUTTABLE) - charindex('\',REVERSE(x.OUTTABLE)) + 1),''))) - 4)
								else
									replace(x.OUTTABLE,left(x.OUTTABLE,len(x.OUTTABLE) - charindex('\',REVERSE(x.OUTTABLE)) + 1),'')
								end core
						from JobControl..JobSteps js
							join JobControl..Jobs j on j.JobID = js.JobID
							join (select j.jobid, js.OUTTABLE
										from DataLoad..Jobs_jobsteps js
											join DataLoad..Jobs_jobs j on j.JOBID = js.JOBID
										where js.OUTTABLE > ''
											and js.OUTTABLE not like '%\query\%' and js.OUTTABLE not like '%\work\%'
										) x on x.JOBID = j.VFPJobID
						where js.StepFileNameAlgorithm like '%<TBLN>%'
					) z
				) y on jsx.StepID = y.StepID


		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','COCM') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 22137
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','MASH') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 26027
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','Dohen0Z5RFG_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 81177
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','RavagnNorm0_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 82892
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','DempseBob05_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 87317
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','Gilli0TQRCQ_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 94666
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','Zaja0S1PV6_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 94674
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','LyonsSean00_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 100300
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','Norto0XEASJS') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 109687
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','Norto0XM3UL_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 109688
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','Norto0XUAXV_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 109690
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','CoeyKurt012_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 126111
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','CoeyKurt013_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 126112
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','CoeyKurt014_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 126113
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','CoeyKurt015_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 126114
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','DerderJim02_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 134780
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','DerderJim03_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 134781
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','SchurGeoff2_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 137441
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','MonadnockLg') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 141321
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','VTValleyNews') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 144250
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','Magov0L50B1_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 144505
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','0L53T3_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 144506
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','AsseliAlexa_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 146246
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','TuftsRyan01_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 148079
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','Georg0OTBC8_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 150286
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','EllettGreg8_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 151286
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','EllettGreg9_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 151287
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','E_4Q90Q6UH6_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 151288
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','E_000000005_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 151289
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','Bourn0RLJFF_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 159731
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','Bourn0RO1M5_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 159732
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','BancroDave0_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 160476
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','BancroDave1_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 160484
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','GBetha00000_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 161936
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','GaryBetha00_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 162000
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','S_5460MGJ9M_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 165313
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','S_000005461_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 165314
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','RyanKathy13_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 168446
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','WaldfoKirk1_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 171850
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','W_5900JPN6E_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 171851
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','W_000005901_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 171852
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','W_5900JPZBE_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 171853
		update js set StepFileNameAlgorithm = replace(js.StepFileNameAlgorithm,'<TBLN12>','W_5900JZOA5_') from JobControl..JobSteps js join JobControl..Jobs j on j.JobID = js.JobID where js.StepTypeID = 22 and j.VFPJobID = 171854


-- Fix sort orders of Layouts that were not really used in VFP 
-- becuse reports are created in VFP with Special steps that run *.prg applications

	declare @SpecialProgName varchar(100)
	declare @SQLReportID int, @SQLFileLayoutID int
	declare @VFPProgFieldList varchar(max)
	
	DECLARE curProgRep CURSOR FOR
		select 'GalleyRep', 39, 'GalleySort, Registry, City, RecGrp, street, stnum, stnumext, unit'
		--union select 'GalleyCreditRpt', 0, ''

	OPEN curProgRep

	FETCH NEXT FROM curProgRep into @SpecialProgName, @SQLReportID, @VFPProgFieldList 
	WHILE (@@FETCH_STATUS <> -1)
		BEGIN

			DECLARE curProgRepB CURSOR FOR
				select distinct js.FileLayoutID
						from JobControl..JobSteps js
							join JobControl..JobSteps js2 on js2.ReportListID = @SQLReportID and js.JobID = js2.JobID
						where js.FileLayoutID > 0

			OPEN curProgRepB

			FETCH NEXT FROM curProgRepB into @SQLFileLayoutID
			WHILE (@@FETCH_STATUS <> -1)
				BEGIN

					update lf set SortOrder = coalesce(fn.Seq,0)
								, SortDir = case when fn.Seq > 0 then 'asc' else '0' end
						from FileLayoutFields lf
							left outer join Support.FuncLib.SplitString(@VFPProgFieldList,',') fn on fn.Value = lf.OutName
						where lf.FileLayoutID = @SQLFileLayoutID

					FETCH NEXT FROM curProgRepB into @SQLFileLayoutID
				END
			CLOSE curProgRepB
			DEALLOCATE curProgRepB

			FETCH NEXT FROM curProgRep into @SpecialProgName, @SQLReportID, @VFPProgFieldList 
		END
	CLOSE curProgRep
	DEALLOCATE curProgRep

-- End of Fix sort orders of Layouts that were not really used in VFP 

	declare @VFPJobID int

	DECLARE curJobFix CURSOR FOR
		select QueryTemplateID, VFPJobID, VFP_QueryID, VFP_BTCRITID 
			from VFPJobs_TemplateJobTemplateFixes

	OPEN curJobFix

	FETCH NEXT FROM curJobFix into @QueryTemplateID, @VFPJobID, @VFP_QueryID, @VFP_BTCRITID
	WHILE (@@FETCH_STATUS <> -1)
		BEGIN
			if @VFPJobID is null and @VFP_BTCRITID > ''
			begin
				update JobControl..JobSteps
					set QueryTemplateID = @QueryTemplateID
					where VFP_QueryID = @VFP_QueryID and VFP_BTCRITID = @VFP_BTCRITID

				update Q set TemplateID = @QueryTemplateID 
					from QueryEditor..Queries Q 
						join JobControl..JobSteps js on js.QueryCriteriaID = q.ID  
					where js.VFP_QueryID = @VFP_QueryID and js.VFP_BTCRITID = @VFP_BTCRITID 
			end
			if @VFP_BTCRITID = '' and @VFPJobID is not null
			begin

				update js set QueryTemplateID = @QueryTemplateID
					from JobControl..JobSteps js 
						join JobControl..Jobs j on j.JobID = js.JobID 
					where js.VFP_QueryID = @VFP_QueryID and j.VFPJobID = @VFPJobID
						
				update q set TemplateID = @QueryTemplateID 
					from QueryEditor..Queries q 
						join JobControl..JobSteps js on js.QueryCriteriaID = q.id 
						join JobControl..Jobs j on j.JobID = js.JobID
					where js.VFP_QueryID = @VFP_QueryID and j.VFPJobID = @VFPJobID

				update JobControl..TransformationTemplates
					set QueryTemplateID = @QueryTemplateID
					where ID in ( select distinct Xjs.TransformationID
									from JobControl..JobSteps js
										join JobControl..Jobs j on j.JobID = js.JobID
										join JobControl..JobSteps Xjs on ',' + Xjs.DependsOnStepIDs + ',' like '%,' + ltrim(str(js.StepID)) + ',%'
									where js.VFP_QueryID = @VFP_QueryID and j.VFPJobID = @VFPJobID )

			end

			FETCH NEXT FROM curJobFix into @QueryTemplateID, @VFPJobID, @VFP_QueryID, @VFP_BTCRITID 
		END
	CLOSE curJobFix
	DEALLOCATE curJobFix


		--update js set QueryTemplateID = 1057
		--	from JobControl..JobSteps js
		--		join JobControl..Jobs j on j.JobID = js.JobID		
		--		join ( select js.VFP_QueryID, j.VFPJobID 
		--				from JobControl..Jobs j
		--					join JobControl..JobSteps js on js.JobID = j.JobID
		--					join  ( select QueryID, count(*) QueryCnt
		--									from ( select distinct qm.QueryID, tt.Category 
		--												from QueryEditor..QueryMultIDs qm
		--													join Lookups..TransactionTypes tt on tt.Id = qm.ValueID
		--												where qm.ValueSource = 'TransTypeID'
		--										) x
		--								group by QueryID
		--								having count(*) > 1
		--							) z on z.QueryID = js.QueryCriteriaID
		--					join JobControl..CustomerInfo ci on ci.ID = j.CustID
		--			) x on js.VFP_QueryID = x.VFP_QueryID and x.VFPJobID = j.VFPJobID


		--update q set TemplateID = 1057
		--	from QueryEditor..Queries q
		--		join JobControl..JobSteps js on js.QueryCriteriaID = q.id
		--		join JobControl..Jobs j on j.JobID = js.JobID		
		--		join ( select js.VFP_QueryID, j.VFPJobID 
		--				from JobControl..Jobs j
		--					join JobControl..JobSteps js on js.JobID = j.JobID
		--					join  ( select QueryID, count(*) QueryCnt
		--									from ( select distinct qm.QueryID, tt.Category 
		--												from QueryEditor..QueryMultIDs qm
		--													join Lookups..TransactionTypes tt on tt.Id = qm.ValueID
		--												where qm.ValueSource = 'TransTypeID'
		--										) x
		--								group by QueryID
		--								having count(*) > 1
		--							) z on z.QueryID = js.QueryCriteriaID
		--					join JobControl..CustomerInfo ci on ci.ID = j.CustID
		--			) x on js.VFP_QueryID = x.VFP_QueryID and x.VFPJobID = j.VFPJobID

		--update JobControl..TransformationTemplates
		--	set QueryTemplateID = 1057
		--	where ID in (
		--				select distinct Xjs.TransformationID
		--						from JobControl..JobSteps js
		--							join JobControl..Jobs j on j.JobID = js.JobID		
		--							join ( select js.VFP_QueryID, j.VFPJobID 
		--									from JobControl..Jobs j
		--										join JobControl..JobSteps js on js.JobID = j.JobID
		--										join  ( select QueryID, count(*) QueryCnt
		--														from ( select distinct qm.QueryID, tt.Category 
		--																	from QueryEditor..QueryMultIDs qm
		--																		join Lookups..TransactionTypes tt on tt.Id = qm.ValueID
		--																	where qm.ValueSource = 'TransTypeID'
		--															) x
		--													group by QueryID
		--													having count(*) > 1
		--												) z on z.QueryID = js.QueryCriteriaID
		--										join JobControl..CustomerInfo ci on ci.ID = j.CustID
		--								) x on js.VFP_QueryID = x.VFP_QueryID and x.VFPJobID = j.VFPJobID
		--							join JobControl..JobSteps Xjs on ',' + Xjs.DependsOnStepIDs + ',' like '%,' + ltrim(str(js.StepID)) + ',%'
		--						)

	exec JobControl..VFPJobs_SetFileLayoutCorrections

	exec JobControl..VFPJobs_SyncQueryTemplateIDs null

	--Fixes for 36 Jobs without Depencey ofr Report to Transform for XPBTGALL (BTCRDS,BTRERS)
	update jsr set DependsOnStepIDs = jst2.StepID
	from JobControl..JobSteps jsr
		left outer join JobControl..JobSteps jst on jst.StepTypeID = 29 and jst.JobID = jsr.JobID and jsr.DependsOnStepIDs = ltrim(str(jst.StepID))
		left outer join JobControl..JobSteps jst2 on jst2.StepTypeID = 29 and jst2.JobID = jsr.JobID and jsr.StepOrder = (jst2.StepOrder + 1)
	where jsr.StepTypeID = 22
		and coalesce(jsr.DependsOnStepIDs,'-1') <> ltrim(str(jst2.StepID))

	--Jobs should not ask or use both 'CalPeriod','CalYear' and 'IssueWeek'
		update j set PromptCalPeriod = 0, PromptCalYear = 0 
			from JobControl..Jobs j
				join JobControl..JobParameters jpCal on j.JobID = jpCal.JobID
				join JobControl..JobParameters jpIW on jpCal.JobID = jpIW.JobID and jpIW.ParamName = 'IssueWeek'
			where jpCal.ParamName in ('CalPeriod','CalYear')

		delete jpCal
			from JobControl..JobParameters jpCal 
				join JobControl..JobParameters jpIW on jpCal.JobID = jpIW.JobID and jpIW.ParamName = 'IssueWeek'
			where jpCal.ParamName in ('CalPeriod','CalYear')

	-- Fix for alt reports
	update js set ReportListID = 186 
		from JobControl..JobSteps js
			join JobControl..Jobs j on j.JobID = js.JobID 
		 where (j.VFPJobID in (137781,137783,137785,137787,137789)
			or j.Type = 'WBAVLW')
			and js.VFP_ReportID = 'XLWebLd'

	update js set QueryTemplateID = 1057
		from JobControl..JobSteps js
		where js.VFP_QueryID = 'XLCUBEPfWk'

	update q set TemplateID = 1057
	from QueryEditor..Queries q
		where q.VFP_QueryID = 'XLCUBEPfWk'

	insert QueryEditor..QueryLocations (StateID, QueryID, VFPIn)
	select g.StateID, m.QueryCriteriaID, 1
		from (
			select j.jobID, ql.StateID
				from JobControl..JobSteps js
					join JobControl..Jobs j on j.JobID = js.jobID
					left outer join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID
				where j.VFPJobID in (145468, 145645, 145143, 146069, 146245, 171435, 170463)
					and StepTypeID = 21
					and VFP_QueryID in ('XLCMLSPrWk')
			) g
			join (
			select j.jobID, js.QueryCriteriaID
				from JobControl..JobSteps js
					join JobControl..Jobs j on j.JobID = js.jobID
					left outer join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID
				where j.VFPJobID in (145468, 145645, 145143, 146069, 146245, 171435, 170463)
					and StepTypeID = 21
					and VFP_QueryID in ('XLCUBEPfWk')
			) m on g.JobID = m.jobid

print ' MUST RUN!!! this to update Query SQLCmds'
print 'R:\Wired3\Devel\Runable\QueryEditorSQLUpdate\QueryEditorSQLUpdate.exe' 

end
