/****** Object:  Procedure [dbo].[VFPJobs_BuildProcess]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobs_BuildProcess
AS
BEGIN
	SET NOCOUNT ON;

	--truncate table JobControl..VFPJobs_QueryFromClause

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

	end

-- Clear previous VFP Loeaded attempts
	declare @Tbl varchar(100), @IdentCol varchar(50)
	declare @cmd varchar(max)

	DECLARE curA CURSOR FOR
		      select 'JobControl..Jobs' Tbl, 'JobID' IdentCol
		union select 'JobControl..JobSteps', 'StepID'
		union select 'JobControl..JobTemplates', 'TemplateID'
		union select 'JobControl..JobTemplateSteps', 'ID'
		union select 'QueryEditor..Queries', 'ID'
		union select 'QueryEditor..QueryLocations', 'ID'
		union select 'QueryEditor..QueryMultIDs', 'ID'
		union select 'QueryEditor..QueryRanges', 'ID'
		union select 'JobControl..JobParameters', 'ParmRecID'
		union select 'JobControl..TransformationTemplates', 'ID'
		union select 'JobControl..TransformationTemplateColumns','RecID'
		union select 'JobControl..FileLayouts', 'Id'
		union select 'JobControl..FileLayoutFields','RecID'

     OPEN curA

     FETCH NEXT FROM curA into @Tbl, @IdentCol
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
		
		set @cmd = 'delete ' + @Tbl + ' where VFPIn = 1'
		exec(@cmd)

		set @cmd = 'declare @MaxID int; select @MaxID = max(' + @IdentCol + ') from ' + @Tbl + '; DBCC CHECKIDENT (''' + @Tbl + ''', RESEED, @MaxID);'
		exec(@cmd)

          FETCH NEXT FROM curA into @Tbl, @IdentCol
     END
     CLOSE curA
     DEALLOCATE curA

	select j.JobID into #JobsToDo
		from DataLoad..Jobs_Jobs j
			--join (	select j.JOBID, j.JOBTYPE, j.CATEGORY, j.STATUS, j.DTCOMPLETE
			--			, jc.Code, jc.Description
			--		from DataLoad..Jobs_Jobs j
			--			join JobControl..JobCategories jc on jc.Code = j.CATEGORY
			--			join (
			--					select q.JOBID
			--						from (select distinct JOBID from DataLoad..Jobs_jobsteps where steptype = 'Query') q
			--						 join (select distinct JOBID from DataLoad..Jobs_jobsteps where steptype = 'xform') x on q.JOBID = x.JOBID
			--						 join (select distinct JOBID from DataLoad..Jobs_jobsteps where steptype = 'REPORTER') r on r.JOBID = q.JOBID
			--				) QXR on QXR.JOBID = j.JOBID
			--		where j.STATUS <> 'S'
			--			and j.DTCOMPLETE >= '1/1/2018'
			--	) bj on bj.jobID = j.JobID
		where j.JobID in (145645,141451, 28835)

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

			declare @TemplateExists bit

			select @TemplateExists = case when count(*) > 0 then 1 else 0 end
				from DataLoad..Jobs_JOBSTEMPL jt 
						join JobControl..JobTemplates wjt on wjt.Description = jt.jobdescrip and wjt.VFPIn = 1
					where jt.jobType = @JobType
			
			if @TemplateExists = 0
				begin

	 				insert JobControl..JobTemplates (VFPIn, Type, Description, CategoryID, RunModeID, RecurringTypeID, ProcessTypeID)
						select 1, jt.jobtype, jt.jobdescrip, jc.ID, jm.ID, jrt.ID, 0
							from DataLoad..Jobs_JOBSTEMPL jt 
								left outer join JobControl..JobCategories jc on jc.Code = jt.category
								left outer join JobControl..JobModes jm on jm.Code = jt.jobrunmode
								left outer join JobControl..JobRecurringTypes jrt on jrt.Code = jt.recurring
							where jt.jobType = @JobType
		
					select @NewJobTempID = max(TemplateID) from JobControl..JobTemplates where VFPIn = 1


					--TBD?  RequiresSetup, ReportListId, FileLayoutId, SpecialId
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

					update jsX set DependsOnStepID = jsPr.ID
								,DependsOnStepIDs = jsPr.ID
							from JobControl..JobTemplateSteps jsX 
								join JobControl..JobTemplateSteps jsPr on jsPr.StepOrder = (jsX.StepOrder - 1) and jsPr.TemplateID = jsX.TemplateID
							where jsX.VFPIn = 1
								and jsX.StepTypeID in (29,22,1)	-- 29 Xfrom, 22 Report, 1 Append
								and jsx.TemplateID = @NewJobTempID

					declare @LastTemplateID int = 0
					declare @NewFilePat varchar(2000)
					declare @TemplateID int, @StepID int, @StepTypeID int, @StepFileNameAlgorithm varchar(2000), @OutPath varchar(2000), @OutFileName varchar(2000), @ReportListID int, @Extension varchar(10)

					DECLARE curB CURSOR FOR
 						select x.ID, x.TemplateID, x.StepTypeID, x.StepFileNameAlgorithm
								, replace(x.OutPath,'\redp\output\','R:\Wired3\ReportsOut\') OutPath
								, replace(replace(replace(replace(replace(replace(x.OutFileName,'right(oJC.issweek,4)','!IW4!'),'oJC.issweek','!IW6!'),'oJC.curstate','!ST!'),'''',''),'+',''),' ','') OutFileName
								, ReportListID
								, Extension
						from (
							select js.ID, js.TemplateID, js.StepOrder, js.StepTypeID
								, js.StepFileNameAlgorithm
								, substring(ltrim(rtrim(js.StepFileNameAlgorithm)),1,len(ltrim(rtrim(js.StepFileNameAlgorithm))) - charindex('\',reverse(ltrim(rtrim(js.StepFileNameAlgorithm)))) + 1) OutPath
								, substring(ltrim(rtrim(js.StepFileNameAlgorithm)),len(ltrim(rtrim(js.StepFileNameAlgorithm))) - charindex('\',reverse(ltrim(rtrim(js.StepFileNameAlgorithm)))) + 2,2000) OutFileName
								, js.ReportListID
								, r.Extension
							from JobControl..JobTemplateSteps js
								left outer join JobControl..Reports r on r.Id = js.ReportListId
							where js.VFPIn = 1
							) x
						order by x.TemplateID, x.StepOrder

					 OPEN curB

					 FETCH NEXT FROM curB into @StepID, @TemplateID, @StepTypeID, @StepFileNameAlgorithm, @OutPath, @OutFileName, @ReportListID, @Extension
					 WHILE (@@FETCH_STATUS <> -1)
					 BEGIN

							if ltrim(rtrim(@StepFileNameAlgorithm)) > ''
								begin
									set @NewFilePat = @OutPath + @OutFileName
									update JobControl..JobTemplateSteps set StepFileNameAlgorithm = '' where ID = @StepID
								end
							else
								begin
									if @LastTemplateID = @TemplateID and @ReportListID is not null
										update JobControl..JobTemplateSteps set StepFileNameAlgorithm = @NewFilePat + '.' + @Extension where ID = @StepID
								end

							set @LastTemplateID = @TemplateID
						  FETCH NEXT FROM curB into @StepID, @TemplateID, @StepTypeID, @StepFileNameAlgorithm, @OutPath, @OutFileName, @ReportListID, @Extension
					 END
					 CLOSE curB
					 DEALLOCATE curB
				end
			else
				begin
						select @NewJobTempID = wjt.TemplateID
						from DataLoad..Jobs_JOBS j 
								join DataLoad..Jobs_JOBSTEMPL jt on jt.jobtype = j.JOBTYPE
								join DataLoad..Jobs_stepstempl jts on jts.JOBTEMPLID = jt.jobtemplid
								left outer join JobControl..JobTemplates wjt on wjt.Description = jt.jobdescrip and wjt.VFPIn = 1
							where jt.jobType = @JobType
				end

			insert JobControl..Jobs (VFPIn, JobName, JobTemplateID, CategoryID, ModeID, RecurringTypeID, ProcessTypeID
										, VFPState, VFPCCode, VFPJobID)
				select 1, j.JOBDESCRIP, @NewJobTempID, wjt.CategoryID, jm.ID, jrt.ID, 0
										, j.CurState, j.CCode, @JobID
					from DataLoad..Jobs_JOBS j 
						join DataLoad..Jobs_JOBSTEMPL jt on jt.jobtype = j.JOBTYPE
						join JobControl..JobTemplates wjt on wjt.TemplateID = @NewJobTempID
						left outer join JobControl..JobModes jm on jm.Code = j.JOBRUNMODE
						left outer join JobControl..JobRecurringTypes jrt on jrt.Code = j.recurring					 
					where j.JobID = @JobID

			select @NewJobID = max(JobID) from JobControl..Jobs where VFPIn = 1

			insert JobControl..JobSteps (VFPIn, JobID, StepName, StepOrder, StepTypeID, RunModeID
										,VFP_QueryID, VFP_BTCRITID, VFP_LayoutID, VFP_ReportID)
				select 1, @NewJobID, js.STEPDESC, ROW_NUMBER() OVER(ORDER BY js.STEPID), coalesce(jst.StepTypeID,0), jm.ID
						, QueryID, BTCRITID, LayoutID, ReportID
				from DataLoad..Jobs_JOBs j
						join DataLoad..Jobs_jobsteps js on js.JOBID = j.JOBID
						left outer join VFPJobs_Map_StepTypes mst on mst.VFPStepType = js.STEPTYPE
						left outer join JobControl..JobStepTypes jst on jst.Code = mst.Code
						left outer join JobControl..JobModes jm on jm.Code = js.STEPRUNMODE
					where j.JobID = @JobID
				order by js.STEPID

			insert JobControl..JobParameters (VFPIn, JobID, ParamName, ParamValue)
				select 1, @NewJobID, 'IssueWeek', ISSWEEK from DataLoad..Jobs_JOBs where JobID = @JobID and ISSWEEK > ''
			insert JobControl..JobParameters (VFPIn, JobID, ParamName, ParamValue)
				select 1, @NewJobID, 'StateID', s.Id
					from DataLoad..Jobs_JOBs j
						join Lookups..States s on j.CURSTATE = s.Code
					where j.JobID = @JobID and j.curstate > ''
			insert JobControl..JobParameters (VFPIn, JobID, ParamName, ParamValue)
				select 1, @NewJobID, 'CountyID', c.Id
					from DataLoad..Jobs_JOBs j
						join Lookups..States s on j.CURSTATE = s.Code
						join Lookups..Counties c on c.State = s.Code and c.Code = j.CCODE
					where j.JobID = @JobID and j.CCODE > ''

			--update jsX set DependsOnStepID = jsPr.StepID
			--				,DependsOnStepIDs = jsPr.StepID
			--			from JobControl..JobSteps jsX 
			--				join JobControl..JobSteps jsPr on jsPr.StepOrder = (jsX.StepOrder - 1) and jsPr.JobID = jsX.JobID
			--			where jsX.VFPIn = 1
			--				and jsX.StepTypeID in (29,22,1)	-- 29 Xfrom, 22 Report, 1 Append
			--				and jsx.JobID = @JobID

			exec SetDependsOnStepIDs @NewJobID

          FETCH NEXT FROM curA into @JobID, @JobType
     END
     CLOSE curA
     DEALLOCATE curA

		update js set StepFileNameAlgorithm = jts.StepFileNameAlgorithm
				from JobControl..JobSteps js
					join JobControl..Jobs j on j.JobID = js.JobID
					join JobControl..JobTemplateSteps jts on jts.TemplateID = j.JobTemplateID and js.StepOrder = jts.StepOrder
				where js.VFPIn = 1
					and ltrim(rtrim(jts.StepFileNameAlgorithm)) > ''

	--	Create Queries from Jobs and JobTemplates

	-- Build the "And" Conditions

	truncate table JobControl..VFPJobs_Query_Conds 

	declare @NewQueryID int
	declare @WhereClause varchar(max)
	declare @VFP_QueryID varchar(100), @QueryTemplateID int

	DECLARE curB CURSOR FOR
		
		select q.VFP_QueryID, max(coalesce(qtf.QueryTemplateID,fc.QueryTemplateID))
			from (
					select VFP_QueryID from JobControl..JobSteps where VFPIn = 1 and VFP_QueryID > ''
					union select VFP_QueryID from JobControl..JobTemplateSteps where VFPIn = 1 and VFP_QueryID > ''
					) q
				join Dataload..Jobs_MF_query vq on vq.QUERY_ID = q.VFP_QueryID
				left outer join JobControl..VFPJobs_QueryToQueryTemplateForce qtf on qtf.VFP_QueryID = q.VFP_QueryID
				left outer join JobControl..VFPJobs_QueryFromClause fc on fc.FromClause = Support.FuncLib.StringFromTo(vq.SELECTEXP1,'from','where',1)
																			or fc.OrigVFPSelect = vq.SELECTEXP1
			group by q.VFP_QueryID


     OPEN curB

     FETCH NEXT FROM curB into @VFP_QueryID, @QueryTemplateID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

			insert QueryEditor..Queries (VFPIn, VFP_QueryID, TemplateID)
				values (1, @VFP_QueryID, @QueryTemplateID)
			
			select @WhereClause = Support.FuncLib.StringFromTo(Support.FuncLib.CleanVFPInfo(SELECTEXP1,'QuerySelect'),'Where','',1) + Support.FuncLib.StringFromTo(Support.FuncLib.CleanVFPInfo(SELECTEXP2,'QuerySelect'),'Where','',1)
				from DataLoad..Jobs_MF_query 
					where QUERY_ID = @VFP_QueryID		

			insert JobControl..VFPJobs_Query_Conds ( QUERY_ID, Cond)
				select @VFP_QueryID, case when ltrim(x.value) like 'where %' then substring(ltrim(x.value), 7,1000) else ltrim(x.value) end
					from Support.FuncLib.SplitString(@WhereClause,'and') x

          FETCH NEXT FROM curB into @VFP_QueryID, @QueryTemplateID
     END
     CLOSE curB
     DEALLOCATE curB

		update jts set QueryCriteriaID = q.ID
					, QueryTemplateID = q.TemplateID
			from JobControl..JobTemplateSteps jts
				join QueryEditor..Queries q on q.VFP_QueryID = jts.VFP_QueryID

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
					from Support.FuncLib.SplitString(@Cond,'or') x
						left outer join JobControl..VFPJobs_Map_TemplatesToConds xc on xc.cond = x.value and xc.OrRecID = @RecID and xc.TemplateID = @TemplateID
					where xc.recId is null


          FETCH NEXT FROM curB into @RecID, @TemplateID, @Cond
     END
     CLOSE curB
     DEALLOCATE curB

	 -- TBD Build Template Queries turning Conds into Wired3 conds using
		declare @NewCondPlace varchar(50), @NewCondType varchar(50), @NewCondField varchar(50)
				, @NewCondNot bit, @NewCondSymbol varchar(100), @NewCondValue varchar(100), @OrRecID int, @OrigCond Varchar(max)

		DECLARE curB CURSOR FOR
		
		select TemplateID, NewCondPlace, NewCondType, NewCondField, NewCondNot, NewCondSymbol, NewCondValue, OrRecID, Cond
			from JobControl..VFPJobs_Map_TemplatesToConds
			where coalesce(ignore,0) = 0
			ORDER BY TemplateID, COALESCE (OrRecID, RecId), RecId

		 OPEN curB

		 FETCH NEXT FROM curB into @TemplateID, @NewCondPlace, @NewCondType, @NewCondField, @NewCondNot, @NewCondSymbol, @NewCondValue, @OrRecID, @OrigCond
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				-- TBD JobParam		Skipped becuse these will be added after the cloned queries
				-- TBD Join			Noe yet
				if @NewCondPlace = 'Query'
				begin
					-- TBD Range
					if @NewCondType = 'MultiVal'
						begin
							insert QueryEditor.. QueryMultIDs (VFPIn, QueryID, ValueSource, ValueID, Exclude)
							select 1, q.ID, @NewCondField, x.Value, coalesce(@NewCondNot,0)
								from QueryEditor..Queries q
									join JobControl..QueryTemplates qt on qt.Id = q.TemplateID
									join JobControl..VFPJobs_Query_Conds c on c.QUERY_ID = q.VFP_QueryID and c.Cond = @OrigCond
									join Support.FuncLib.SplitString(@NewCondValue,',') x on 1=1
									left outer join QueryEditor.. QueryMultIDs m on m.VFPIn = 1 and m.QueryID = q.ID 
																					and m.ValueSource = @NewCondField
																					and m.ValueID = x.Value
																					and m.Exclude = coalesce(@NewCondNot,0)
								where TemplateID = @TemplateID and q.VFPIn = 1
									and m.ID is null
						end
					if @NewCondType = 'Field'
						begin
							set @cmd = 'update QueryEditor..Queries set ' + @NewCondField + ' = ' + @NewCondValue + ' where TemplateID = ' + ltrim(str(@TemplateID)) + ' and VFPIn = 1'
							exec(@cmd)
						end
				end
			  FETCH NEXT FROM curB into @TemplateID, @NewCondPlace, @NewCondType, @NewCondField, @NewCondNot, @NewCondSymbol, @NewCondValue, @OrRecID, @OrigCond
		 END
		 CLOSE curB
		 DEALLOCATE curB

	------------------------------------------------------------------------------------------------

	 -- For every job Clone Query of JobTemplate into new query in Job
	 -- Add Job State Location to Query (JobParam)
	 -- Add Job County Location to Query (JobParam)
	 -- Add Issueweek to Query (JobParam)

		declare @QueryCriteriaId int, @QueryTypeID int

		DECLARE curB CURSOR FOR
		
		select jts.QueryCriteriaId, js.JobID, js.StepID, qt.QueryTypeID
			from JobControl..Jobs j
				join JobControl..JobTemplates jt on jt.TemplateID = j.JobTemplateID
				join JobControl..JobTemplateSteps jts on jts.TemplateID = jt.TemplateID
				join JobControl..JobSteps js on js.JobID = j.JobID and js.StepOrder = jts.StepOrder
				join QueryEditor..Queries q on q.ID = jts.QueryCriteriaId
				join JobControl..QueryTemplates qt on qt.Id = q.TemplateID
			where jts.QueryCriteriaId is not null
				and j.VFPIn = 1

		 OPEN curB

		 FETCH NEXT FROM curB into @QueryCriteriaId, @JobID, @StepID, @QueryTypeID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				exec @NewQueryID = QueryEditor..CloneQuery @QueryCriteriaId

				update JobControl..JobSteps set QueryCriteriaID = @NewQueryID where StepID = @StepID

				update QueryEditor..Queries set VFPIn = 1 where ID = @NewQueryID
				update QueryEditor..QueryLocations set VFPIn = 1 where QueryID = @NewQueryID
				update QueryEditor..QueryMultIDs set VFPIn = 1 where QueryID = @NewQueryID
				update QueryEditor..QueryRanges set VFPIn = 1 where QueryID = @NewQueryID

				insert QueryEditor..QueryLocations (QueryID, StateID, CountyID, VFPIn)
				select @NewQueryID
						, case when ParamName = 'StateID' then ParamValue else null end
						, case when ParamName = 'CountyID' then ParamValue else null end
						, 1
					from JobControl..JobParameters
					where JobID = @JobID and VFPIn = 1 and ParamName in ('StateID','CountyID')

				insert QueryEditor..QueryRanges (QueryID, RangeSource, MinValue, MaxValue, VFPIn)
				select @NewQueryID
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
						, ParamValue, ParamValue, 1 
					from JobControl..JobParameters
					where JobID = @JobID and VFPIn = 1 and ParamName in ('IssueWeek')

			  FETCH NEXT FROM curB into @QueryCriteriaId, @JobID, @StepID, @QueryTypeID
		 END
		 CLOSE curB
		 DEALLOCATE curB


	 -- TBD Merge multiple appended county steps into 1 job step
	 -- TBD Merge multiple appended state Jobs into 1 job
	 -- TBD Deal with Customer ID (Maybe not here but need to be addressed)

	 -- TBD For each Template build all the Xfroms from Xform Steps
	 -- TBD For each Template build all the Layouts from Xform Steps
	 -- TBD For each Template build all the Reports from Report Steps

	 declare @NewXFromID int, @NewLayoutID int, @VFPXFormShell varchar(100)
	 declare @VFPLayoutID varchar(50)

		DECLARE curB CURSOR FOR
		
		select distinct jsX.VFP_LayoutID, Q.TemplateID
			from JobControl..JobSteps jsQ
				join JobControl..JobSteps jsX on jsX.StepTypeID = 29 and (jsQ.StepOrder + 1) = jsX.StepOrder and jsQ.JobID = jsX.JobID
				join QueryEditor..Queries Q on Q.ID = jsQ.QueryCriteriaID
			where jsQ.VFPIn = 1
				and jsQ.StepTypeID = 21	

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
				insert JobControl..VFPJObs_Map_XForm_VFPCode (VFPLayoutID, VFPSourceCode, SQLCode)
					select distinct @VFPLayoutID, ttc.VFPSourceCode, null
						from JobControl..TransformationTemplateColumns ttc
							left outer join JobControl..VFPJObs_Map_XForm_VFPCode pc on pc.VFPSourceCode = ttc.VFPSourceCode
--																						and pc.TransformTemplateID = ttc.TransformTemplateID
						where ttc.VFPIn = 1
							and pc.RecID is null

				update u set SQLCode = k.SQLCode
					from JobControl..VFPJObs_Map_XForm_VFPCode u
						join JobControl..VFPJObs_Map_XForm_VFPCode k on k.VFPSourceCode = u.VFPSourceCode and coalesce(k.confirmed,0) = 1 and k.SQLCode is not null
					where u.SQLCode is null

				update u set SQLCode = k.SQLCode
					from JobControl..VFPJObs_Map_XForm_VFPCode u
						join JobControl..VFPJObs_Map_XForm_VFPCode k on k.VFPSourceCode = u.VFPSourceCode and coalesce(k.confirmed,0) = 0 and k.SQLCode is not null
					where u.SQLCode is null

				update u set SQLCode = case when VFPSourceCode like '''%''' then VFPSourceCode
									when VFPSourceCode like '"%"' then replace(VFPSourceCode,'"','''')
									else null end
				from JobControl..VFPJObs_Map_XForm_VFPCode u
					where SQLCode is null

				
				--Update SourceCode from Map Table based on TemplateID
				update ttc set SourceCode = SQLCode
					from JobControl..TransformationTemplateColumns ttc
						join JobControl..VFPJObs_Map_XForm_VFPCode pc on pc.VFPSourceCode = ttc.VFPSourceCode
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

				set @NewLayoutID = SCOPE_IDENTITY()

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

		 -- Update Transform Steps of Jobs with Correct new TransformID and LayoutID

			update jts set jts.TransformationId = tt.id, jts.FileLayoutId = fl.ID
				from JobControl..JobTemplateSteps jts
					join JobControl..TransformationTemplates tt on tt.VFPin = 1 and tt.ShortTransformationName = jts.VFP_LayoutID
					join JobControl..FileLayouts fl on tt.ID = fl.TransformationTemplateId 
					where jts.StepTypeID = 29 and jts.VFPin = 1

			update js set js.TransformationId = tt.id, js.FileLayoutId = fl.ID
				from JobControl..JobSteps js
					join JobControl..TransformationTemplates tt on tt.VFPin = 1 and tt.ShortTransformationName = js.VFP_LayoutID
					join JobControl..FileLayouts fl on tt.ID = fl.TransformationTemplateId 
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

		drop table #JobsToDo


-- Show Completed Work

	--select 'JobControl..Jobs', * from JobControl..Jobs where VFPIn = 1
	--select 'JobControl..JobSteps', * from JobControl..JobSteps where VFPIn = 1
	--select 'JobControl..JobTemplates', * from JobControl..JobTemplates where VFPIn = 1
	--select 'JobControl..JobTemplateSteps', * from JobControl..JobTemplateSteps where VFPIn = 1
	--select 'QueryEditor..Queries', * from QueryEditor..Queries where VFPIn = 1
	--select 'JobControl..VFPJobs_Query_Conds', * from JobControl..VFPJobs_Query_Conds

-- Errors/ Issues

	--select count(*) Issues, 'JobControl..JobTemplateSteps with an Unknown JobStepType' from JobControl..JobTemplateSteps where StepTypeID = 0 and VFPIn = 1
	--select count(*) Issues, 'QueryEditor..Queries with an Unknown TemplateID' from QueryEditor..Queries where TemplateID is null and VFPIn = 1
	--select count(*) Issues, 'Query JobControl..JobSteps w/o QueryID' from JobControl..JobSteps where QueryCriteriaID is null and StepTypeID = 21 and VFPIn = 1
	--select count(*) Issues, 'Query JobControl..JobTemplateSteps w/o QueryID' from JobControl..JobTemplateSteps where QueryCriteriaID is null and StepTypeID = 21 and VFPIn = 1

-- Error Details
	
	-- Details top help with  QueryEditor..Queries with an Unknown TemplateID
			--select js.JobID, q.ID QueryID, js.VFP_QueryID, js.StepID, js.StepName, qtf.QueryTemplateID ForcedQueryTemplateID, fc.* 
			--	from QueryEditor..Queries q
			--		join JobControl..JobSteps js on js.QueryCriteriaID = q.ID
			--		join Dataload..Jobs_MF_query vq on vq.QUERY_ID = q.VFP_QueryID
			--		left outer join JobControl..VFPJobs_QueryToQueryTemplateForce qtf on qtf.VFP_QueryID = js.VFP_QueryID
			--		left outer join JobControl..VFPJobs_QueryFromClause fc on (fc.FromClause = Support.FuncLib.StringFromTo(vq.SELECTEXP1,'from','where') and fc.FromClause <> '')
			--																	or fc.OrigVFPSelect = vq.SELECTEXP1
			--select * from QueryTemplates
	
--	-- Details for help with Conds																		
--	select case when coalesce(Ignore,0) = 0 and (ltrim(coalesce(NewCondType,'')) = '' or ltrim(coalesce(NewCondField,'')) = '' or ltrim(coalesce(NewCondPlace,'')) = '') then 'Yes' else '' end NeedsAttention
--			, x.*, qt.FromPart, qt.TemplateName
----			, q.VFP_QueryID
--			--, Support.FuncLib.StringFromTo(SELECTEXP1,'From','where',1)
--			, COALESCE (OrRecID, RecId) OrderBy
--		from JobControl..VFPJobs_Map_TemplatesToConds x
--			join JobControl..QueryTemplates qt on qt.Id = x.TemplateID
----			join QueryEditor..Queries q on q.TemplateID = x.TemplateID
----			join DataLoad..Jobs_MF_query vq on vq.QUERY_ID = q.VFP_QueryID
--		ORDER BY TemplateID, COALESCE (OrRecID, RecId), RecId
