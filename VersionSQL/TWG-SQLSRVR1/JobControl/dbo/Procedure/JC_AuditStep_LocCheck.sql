/****** Object:  Procedure [dbo].[JC_AuditStep_LocCheck]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_AuditStep_LocCheck
	@JobStepID int, @GroupRecID int
AS
BEGIN

	SET NOCOUNT ON;

	declare @DepOnQueryID int
	declare @XFormTableA varchar(200)
	declare @FailLevel int
	declare @WarnLevel int
	declare @BeginLoopType int
	declare @LocationQueryCriteriaID int
	declare @AllLocationsTotal bit

	drop table if exists #LocCheck

	create table #LocCheck (TestMess varchar(1000), TestResult int)

	declare @XFormLayoutID int
	declare @XFormStepID int
	declare @QuerySource varchar(10)

	Select @XFormLayoutID = js.FileLayoutID
			, @XFormStepID = js.StepID
		from JobControl..JobSteps js
			join JobControl..JobStepTypes st on js.StepTypeID = st.StepTypeID
		where js.StepID = @JobStepID


			select @FailLevel = FailLevel
				, @WarnLevel = WarnLevel
				, @XFormTableA = XFormTableA 
				, @DepOnQueryID = QueryCriteriaID
				, @BeginLoopType = BeginLoopType
				, @LocationQueryCriteriaID = LocationQueryCriteriaID
				, @AllLocationsTotal = AllLocationsTotal
				, @QuerySource = qt.SourceCompany
			from (
				select js.JobID, js.StepID
						, 'JobControlWork..' + jst.StepName + 'StepResultsA_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))  XFormTableA
						, qjs.QueryCriteriaID
						, qjs.QueryTemplateID
						, null BeginLoopType
						, null LocationQueryCriteriaID
						, 'Query-Append-XForm' JobFlowType
						, coalesce(xv.LocationFailRecs,-1) FailLevel
						, coalesce(xv.LocationWarnRecs,-1) WarnLevel
						, coalesce(xv.AllLocationsTotal,0) AllLocationsTotal
					from JobControl..JobSteps js 
						join JobControl..JobSteps ajs on js.JobID = ajs.jobid and ajs.StepTypeID = 1 
																	and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(ajs.StepID)) + ',%'
						join JobControl..JobSteps qjs on js.JobID = qjs.jobid and qjs.StepTypeID in (21,1124)
																	and ',' + ajs.DependsOnStepIDs + ',' like '%,' + ltrim(str(qjs.StepID)) + ',%'
						join JobControl..JobStepTypes jst on jst.StepTypeID = js.StepTypeID
						join JobControl..XFormOtherValidataions xv on xv.LayoutID = js.FileLayoutID and coalesce(xv.disabled,0) = 0
					where js.StepTypeID = 29
						and qjs.QueryCriteriaID > 0
						and js.StepID = @JobStepID

				union
					select js.JobID, js.StepID
						, 'JobControlWork..' + jst.StepName + 'StepResultsA_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID)) XFormTableA
						, qjs.QueryCriteriaID
						, qjs.QueryTemplateID
						, null BeginLoopType
						, null LocationQueryCriteriaID
						, 'Query-XForm' JobFlowType
						, coalesce(xv.LocationFailRecs,-1) FailLevel
						, coalesce(xv.LocationWarnRecs,-1) WarnLevel
						, coalesce(xv.AllLocationsTotal,0) AllLocationsTotal
					from JobControl..JobSteps js 
						join JobControl..JobSteps qjs on js.JobID = qjs.jobid and qjs.StepTypeID in (21,1124) 
																	and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(qjs.StepID)) + ',%'
						join JobControl..JobStepTypes jst on jst.StepTypeID = js.StepTypeID
						join JobControl..XFormOtherValidataions xv on xv.LayoutID = js.FileLayoutID and coalesce(xv.disabled,0) = 0
					where js.StepTypeID = 29
						and qjs.QueryCriteriaID > 0
						and js.StepID = @JobStepID
				union
					select js.JobID, js.StepID
						, 'JobControlWork..' + jst.StepName + 'StepResultsA_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID)) XFormTableA
						, qjs.QueryCriteriaID
						, qjs.QueryTemplateID
						, ljs.BeginLoopType
						, l2js.QueryCriteriaID LocationQueryCriteriaID
						, 'Query-XForm InLoop' JobFlowType
						, coalesce(xv.LocationFailRecs,-1) FailLevel
						, coalesce(xv.LocationWarnRecs,-1) WarnLevel
						, coalesce(xv.AllLocationsTotal,0) AllLocationsTotal
					from JobControl..JobSteps js 
						join JobControl..JobSteps qjs on js.JobID = qjs.jobid and qjs.StepTypeID in (21,1124)  
																	and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(qjs.StepID)) + ',%'
						join JobControl..JobSteps ljs on js.JobID = ljs.jobid and ljs.StepTypeID in (1107)  
																	and ',' + qjs.DependsOnStepIDs + ',' like '%,' + ltrim(str(ljs.StepID)) + ',%'
						join JobControl..JobSteps l2js on js.JobID = l2js.jobid and l2js.StepTypeID in (21,1124)  
																	and ',' + ljs.DependsOnStepIDs + ',' like '%,' + ltrim(str(l2js.StepID)) + ',%'
						join JobControl..JobStepTypes jst on jst.StepTypeID = js.StepTypeID
						join JobControl..XFormOtherValidataions xv on xv.LayoutID = js.FileLayoutID and coalesce(xv.disabled,0) = 0
					where js.StepTypeID = 29
						and qjs.QueryCriteriaID > 0
						and js.StepID = @JobStepID
				) x
				left outer join JobControl..QueryTemplates qt on qt.Id = x.QueryTemplateID

			if @FailLevel >= 0
			Begin
				Print @XFormTableA
		
				declare @cmd varchar(4000)

				if @QuerySource = 'FA'
				begin
						if @AllLocationsTotal = 1
							begin
								set @cmd = ' select '' All Locations Total '' + ltrim(str(coalesce(z.recs,0))) + '' records''
															+ case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then '' Fail on: ' + ltrim(str(@FailLevel)) + ' or less''
																	when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then '' Warn on: ' + ltrim(str(@WarnLevel)) + ' or less'' else '''' end TestMess
													, case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then 3 when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then 2 else 1 end TestLevel
											from (select count(*) recs 
													from ' + @XFormTableA + ' ) z  '

								print @cmd
								insert #LocCheck execute(@cmd)

							end
						else
							begin

								set @cmd = ' select s.Code + '' Zip: '' + ql.ZipCode + '' has '' + ltrim(str(coalesce(z.recs,0))) + '' records''
															+ case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then '' Fail on: ' + ltrim(str(@FailLevel)) + ' or less''
																	when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then '' Warn on: ' + ltrim(str(@WarnLevel)) + ' or less'' else '''' end TestMess
													, case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then 3 when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then 2 else 1 end TestLevel
											from QueryEditor..QueryLocations ql
												join Lookups..States s on s.ID = ql.StateID 
												left outer Join (select state, ZipCode, count(*) recs 
																	from ' + @XFormTableA + '
																	group by state, ZipCode ) z on z.state = s.code and z.ZipCode = ql.ZipCode
											where QueryID = ' + ltrim(str(@DepOnQueryID)) + '
												and coalesce(ql.exclude,0) = 0
												and ql.ZipCode > '''' 
											order by s.Code, ql.ZipCode '

								print @cmd
								insert #LocCheck execute(@cmd)

								set @cmd = ' select ''County: '' + c.FullName + '' '' + s.stateFIPS + c.CountyFIPS + '' '' + s.Code + '' has '' + ltrim(str(coalesce(z.recs,0))) + '' records''
															+ case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then '' Fail on: ' + ltrim(str(@FailLevel)) + ' or less''
																	when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then '' Warn on: ' + ltrim(str(@WarnLevel)) + ' or less'' else '''' end TestMess
													, case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then 3 when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then 2 else 1 end TestLevel
											from QueryEditor..QueryLocations ql
												join Lookups..States s on s.Id = ql.StateID
												join Lookups..Counties c on c.Id = ql.CountyID
												left outer Join (select CountyFIPS, count(*) recs 
																	from ' + @XFormTableA + '
																	group by CountyFIPS) z on z.CountyFIPS = s.stateFIPS + c.CountyFIPS
											where QueryID = ' + ltrim(str(@DepOnQueryID)) + '
												and coalesce(ql.exclude,0) = 0
												and s.stateFIPS + c.CountyFIPS > ''''
											order by s.Code, c.FullName '

								print @cmd
								insert #LocCheck execute(@cmd)

								set @cmd = ' select ''State: '' + s.Code + '' has '' + ltrim(str(coalesce(z.recs,0))) + '' records''
															+ case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then '' Fail on: ' + ltrim(str(@FailLevel)) + ' or less''
																	when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then '' Warn on: ' + ltrim(str(@WarnLevel)) + ' or less'' else '''' end TestMess
													, case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then 3 when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then 2 else 1 end TestLevel
											from QueryEditor..QueryLocations ql
												join Lookups..States s on s.Id = ql.StateID
												left outer Join (select State, count(*) recs 
																	from ' + @XFormTableA + '
																	group by State) z on z.State = s.Code
												join ( select ql.StateID, count(ZipCode) Zips, count(TownID) Towns, count(CountyID) Counties
															from QueryEditor..QueryLocations ql
															where QueryID = ' + ltrim(str(@DepOnQueryID)) + '
															Group by ql.StateID
													) ls on ls.StateID = ql.StateID and ls.Zips = 0 and ls.Counties = 0 and ls.Towns = 0
											where QueryID = ' + ltrim(str(@DepOnQueryID)) + '
												and coalesce(ql.exclude,0) = 0
												and s.Code > ''''
											order by s.Code '

								print @cmd
								insert #LocCheck execute(@cmd)
							end					
				end
				else
					begin
						if @AllLocationsTotal = 1
							begin
								set @cmd = ' select '' All Locations Total '' + ltrim(str(coalesce(z.recs,0))) + '' records''
															+ case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then '' Fail on: ' + ltrim(str(@FailLevel)) + ' or less''
																	when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then '' Warn on: ' + ltrim(str(@WarnLevel)) + ' or less'' else '''' end TestMess
													, case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then 3 when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then 2 else 1 end TestLevel
											from (select count(*) recs 
													from ' + @XFormTableA + ' ) z  '

								print @cmd
								insert #LocCheck execute(@cmd)

							end
						else
							begin

								set @cmd = ' select s.Code + '' Zip: '' + ql.ZipCode + '' has '' + ltrim(str(coalesce(z.recs,0))) + '' records''
															+ case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then '' Fail on: ' + ltrim(str(@FailLevel)) + ' or less''
																	when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then '' Warn on: ' + ltrim(str(@WarnLevel)) + ' or less'' else '''' end TestMess
													, case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then 3 when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then 2 else 1 end TestLevel
											from QueryEditor..QueryLocations ql
												left outer Join (select stateID, Zip, count(*) recs 
																	from ' + @XFormTableA + '
																	group by stateID, Zip ) z on z.stateID = ql.StateID and z.Zip = ql.ZipCode
												join Lookups..States s on s.Id = ql.StateID
											where QueryID = ' + ltrim(str(@DepOnQueryID)) + '
												and coalesce(ql.exclude,0) = 0
												and ql.ZipCode > '''' 
											order by s.Code, ql.ZipCode '

								print @cmd
								insert #LocCheck execute(@cmd)

								set @cmd = ' select ''Town: '' + t.FullName + '' has '' + ltrim(str(coalesce(z.recs,0))) + '' records''
															+ case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then '' Fail on: ' + ltrim(str(@FailLevel)) + ' or less''
																	when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then '' Warn on: ' + ltrim(str(@WarnLevel)) + ' or less'' else '''' end TestMess
													, case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then 3 when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then 2 else 1 end TestLevel
											from QueryEditor..QueryLocations ql
												left outer Join (select TownID, count(*) recs 
																	from ' + @XFormTableA + '
																	group by TownID) z on z.TownID = ql.TownID
												join Lookups..States s on s.Id = ql.StateID
												join Lookups..Towns t on t.Id = ql.TownID
											where QueryID = ' + ltrim(str(@DepOnQueryID)) + '
												and coalesce(ql.exclude,0) = 0
												and ql.TownID is not null
											order by s.Code, t.FullName '

								print @cmd
								insert #LocCheck execute(@cmd)

								set @cmd = ' select ''County: '' + c.FullName + '' '' + s.Code + '' has '' + ltrim(str(coalesce(z.recs,0))) + '' records''
															+ case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then '' Fail on: ' + ltrim(str(@FailLevel)) + ' or less''
																	when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then '' Warn on: ' + ltrim(str(@WarnLevel)) + ' or less'' else '''' end TestMess
													, case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then 3 when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then 2 else 1 end TestLevel
											from QueryEditor..QueryLocations ql
												left outer Join (select CountyID, count(*) recs 
																	from ' + @XFormTableA + '
																	group by CountyID) z on z.CountyID = ql.CountyID
												join Lookups..States s on s.Id = ql.StateID
												join Lookups..Counties c on c.Id = ql.CountyID
											where QueryID = ' + ltrim(str(@DepOnQueryID)) + '
												and coalesce(ql.exclude,0) = 0
												and ql.CountyID is not null
											order by s.Code, c.FullName '

								print @cmd
								insert #LocCheck execute(@cmd)

								set @cmd = ' select ''State: '' + s.Code + '' has '' + ltrim(str(coalesce(z.recs,0))) + '' records''
															+ case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then '' Fail on: ' + ltrim(str(@FailLevel)) + ' or less''
																	when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then '' Warn on: ' + ltrim(str(@WarnLevel)) + ' or less'' else '''' end TestMess
													, case when coalesce(z.recs,0) <= ' + ltrim(str(@FailLevel)) + ' then 3 when coalesce(z.recs,0) <= ' + ltrim(str(@WarnLevel)) + ' then 2 else 1 end TestLevel
											from QueryEditor..QueryLocations ql
												left outer Join (select StateID, count(*) recs 
																	from ' + @XFormTableA + '
																	group by StateID) z on z.StateID = ql.StateID
												join Lookups..States s on s.Id = ql.StateID
												join ( select ql.StateID, count(ZipCode) Zips, count(TownID) Towns, count(CountyID) Counties
															from QueryEditor..QueryLocations ql
															where QueryID = ' + ltrim(str(@DepOnQueryID)) + '
															Group by ql.StateID
													) ls on ls.StateID = ql.StateID and ls.Zips = 0 and ls.Counties = 0 and ls.Towns = 0
											where QueryID = ' + ltrim(str(@DepOnQueryID)) + '
												and coalesce(ql.exclude,0) = 0
												and ql.StateID is not null
											order by s.Code '

								print @cmd
								insert #LocCheck execute(@cmd)
							end
						end

			end

	if @GroupRecID = 0

		select case when TestResult = 3 then 0 else 1 end ResultPass
				, TestResult ResultLevel
				, TestMess Results
				, 'LocCheck' ValType
			from #LocCheck
	else
		insert JobControl..ValsOtherCount (GroupRecID, ValPass, ValLevel, ValResult, ValType)
		select @GroupRecID
				, case when TestResult = 3 then 0 else 1 end ResultPass
				, TestResult ResultLevel
				, TestMess Results
				, 'LocCheck' ValType
			from #LocCheck

END
