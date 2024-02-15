/****** Object:  Procedure [dbo].[MTDTrendLineAddFresh]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE MTDTrendLineAddFresh @JobID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @Towns int = 0
	declare @Counties int = 0
	declare @States int = 0

	--Get potential State and County from Trendline Jobs
	drop table if exists #AddableFiles

	select rjs.StepID FromStepID 
				, ql.StateID
				, c.ID CountyID
				, rjs.JobID
				, 'TrendLine' FileType
	into #AddableFiles
		from JobControl..JobSteps rjs
			join JobControl..JobSteps qjs on qjs.jobID = rjs.JobID and qjs.QueryCriteriaID > 0 
			join QueryEditor..QueryLocations ql on ql.QueryID = qjs.QueryCriteriaID and qjs.QueryTemplateID = 1060
			join Lookups..Counties c on c.stateID = ql.stateID
		where rjs.JobID in (2808,2807,2806,2792) AND rjs.StepTypeID = 22 and rjs.SharableReport = 1
	union
	select rjs.StepID FromStepID 
				, ql.StateID
				, c.ID CountyID
				, rjs.JobID
				, 'Summary' FileType
		from JobControl..JobSteps rjs
			join JobControl..JobSteps qjs on qjs.jobID = rjs.JobID and qjs.QueryCriteriaID > 0 
			join QueryEditor..QueryLocations ql on ql.QueryID = qjs.QueryCriteriaID and qjs.QueryTemplateID = 1060
			join Lookups..Counties c on c.stateID = ql.stateID
		where rjs.JobID in (6587,6583,6604,6605,6606,6607,6608,6609) AND rjs.StepTypeID = 22 and rjs.SharableReport = 1

	--Check query for Towns counties and states, only county or states get trendlines
	select @Towns = count(distinct ql.townID)
		, @Counties = count(distinct ql.CountyID)
		, @States = count(distinct ql.StateID)
	from JobControl..Jobs j
			join JobControl..JobSteps js on js.jobID = j.JobID and js.QueryCriteriaID > 0 and js.QueryTemplateID = 1075
			left outer join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID
	where j.CategoryID = 46
		and j.JobID = @JobID

	--Get Step ID's
	declare @ToStepID int = 0
	declare @DelivStepID int = 0
	declare @ReportStepID int = 0

	select @ReportStepID = rjs.StepID
			, @DelivStepID = djs.StepID
			, @ToStepID = coalesce(ajs.StepID,0)
		from JobControl..JobSteps rjs
			left outer join JobControl..JobSteps djs on djs.JobID = rjs.JobID and djs.steptypeID = 1125
			left outer join JobControl..JobSteps ajs on ajs.JobID = rjs.JobID and ajs.steptypeID = 1103
		where rjs.JobID = @JobID and rjs.stepTypeid = 22

print '@Towns: ' + ltrim(str(@Towns))
print '@Counties: ' + ltrim(str(@Counties))
print '@States: ' + ltrim(str(@States))

	if @Towns = 0 
	begin

		Print 'In Towns = 0'

		 
		if coalesce(@ToStepID,0) = 0 and @DelivStepID > 0 and @ReportStepID > 0
		begin

			-- add missing AddFile Step
			insert JobControl..JobSteps (JobID, StepName, StepOrder, StepTypeID, SQLJobStepID, RunModeID, Disabled, UpdatedStamp)
				select JobID, '', StepOrder + 1, 1103, SQLJobStepID, RunModeID, Disabled, getdate()
					from JobControl..JobSteps 
					where JobID = @JobID and StepID = @ReportStepID

			-- Get New AddFile Step ID
			select @ToStepID = coalesce(ajs.StepID,0)
				from JobControl..JobSteps ajs 
				where ajs.JobID = @JobID and ajs.steptypeID = 1103

			-- Update stepOrder of Delivery and Validataion step
			update JobControl..JobSteps 
				set stepOrder = StepOrder + 1
				where JobID = @JobID and steptypeID in (1125,1121)

			-- Update Report Depends on ato add Add File ID
			update JobControl..JobSteps 
				set DependsOnStepIDs = DependsOnStepIDs + ',' + ltrim(str(@ToStepID))
				where JobID = @JobID and StepID = @DelivStepID
		

		end


		if @Counties > 0
		begin

			Print 'In Counties'

				--insert any missing counties that should go
				insert JobControl..JobAddedFiles (ToJobStepID, FromJobStepID, Iteration_CountyID, Iteration_TownID, Iteration_StateID)
				select x.ToStepID, x.FromStepID, x.CountyID, 0, 0
					from (
						select @ToStepID ToStepID, tl.FromStepID, tl.CountyID
						from JobControl..Jobs j
								join JobControl..JobSteps js on js.jobID = j.JobID and js.QueryCriteriaID > 0 and js.QueryTemplateID = 1075
								join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID
								join #AddableFiles tl on tl.StateID = ql.StateID and tl.CountyID = ql.CountyID
						where j.CategoryID = 46
							and j.JobID = @JobID
						) x
						left outer join JobControl..JobAddedFiles jaf on jaf.ToJobStepID = x.ToStepID
																		and jaf.FromJobStepID = x.FromStepID
																		and jaf.Iteration_CountyID = x.CountyID
					where jaf.recID is null


				--Remove any extra counties the should no longer go
				delete jaf
					from JobControl..JobAddedFiles jaf
						left outer join (
							select @ToStepID ToStepID, tl.FromStepID, tl.CountyID
							from JobControl..Jobs j
									join JobControl..JobSteps js on js.jobID = j.JobID and js.QueryCriteriaID > 0 and js.QueryTemplateID = 1075
									join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID
									join #AddableFiles tl on tl.StateID = ql.StateID and tl.CountyID = ql.CountyID
							where j.CategoryID = 46
								and j.JobID = @JobID
						) x on jaf.ToJobStepID = x.ToStepID
									and jaf.FromJobStepID = x.FromStepID
									and jaf.Iteration_CountyID = x.CountyID
					where jaf.ToJobStepID = @ToStepID
						and x.CountyID is null

																
		end

		if @Counties = 0 and @States > 0  -- Add or remove All counties in state
		begin

			Print 'In States'

			-- Summaries

				--insert any missing counties that should go
				insert JobControl..JobAddedFiles (ToJobStepID, FromJobStepID, Iteration_CountyID, Iteration_TownID, Iteration_StateID)
				select x.ToStepID, x.FromStepID, 0, 0, StateID
					from (
						select distinct @ToStepID ToStepID, tl.FromStepID, tl.StateID
						from JobControl..Jobs j
								join JobControl..JobSteps js on js.jobID = j.JobID and js.QueryCriteriaID > 0 and js.QueryTemplateID = 1075
								join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID and ql.StateID > 0
								join #AddableFiles tl on tl.StateID = ql.StateID and tl.FileType = 'Summary'
						where j.CategoryID = 46
							and j.JobID = @JobID
						) x
						left outer join JobControl..JobAddedFiles jaf on jaf.ToJobStepID = x.ToStepID
																		and jaf.FromJobStepID = x.FromStepID
																		and jaf.Iteration_StateID = x.StateID
					where jaf.recID is null


				--Remove any extra counties the should no longer go
				delete jaf
					from JobControl..JobAddedFiles jaf
						left outer join (
							select distinct @ToStepID ToStepID, tl.FromStepID, tl.StateID
							from JobControl..Jobs j
									join JobControl..JobSteps js on js.jobID = j.JobID and js.QueryCriteriaID > 0 and js.QueryTemplateID = 1075
									join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID and ql.StateID > 0
									join #AddableFiles tl on tl.StateID = ql.StateID and tl.FileType = 'Summary'
							where j.CategoryID = 46
								and j.JobID = @JobID
						) x on jaf.ToJobStepID = x.ToStepID
									and jaf.FromJobStepID = x.FromStepID
									and jaf.Iteration_StateID = x.StateID
					where jaf.ToJobStepID = @ToStepID
						and jaf.Iteration_StateID > 0
						and x.StateID is null

			-- TrendLines

				--insert any missing counties that should go
				insert JobControl..JobAddedFiles (ToJobStepID, FromJobStepID, Iteration_CountyID, Iteration_TownID, Iteration_StateID)
				select x.ToStepID, x.FromStepID, x.CountyID, 0, 0
					from (
						select distinct @ToStepID ToStepID, tl.FromStepID, tl.CountyID
						from JobControl..Jobs j
								join JobControl..JobSteps js on js.jobID = j.JobID and js.QueryCriteriaID > 0 and js.QueryTemplateID = 1075
								join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID and ql.StateID > 0
								join Lookups..Counties c on c.StateID = ql.StateID
								join #AddableFiles tl on tl.CountyID = c.Id and tl.FileType = 'TrendLine'
						where j.CategoryID = 46
							and j.JobID = @JobID
						) x
						left outer join JobControl..JobAddedFiles jaf on jaf.ToJobStepID = x.ToStepID
																		and jaf.FromJobStepID = x.FromStepID
																		and jaf.Iteration_CountyID = x.CountyID
					where jaf.recID is null


			--	Remove any extra counties the should no longer go
	
				delete jaf
					from JobControl..JobAddedFiles jaf
						left outer join (
							select distinct @ToStepID ToStepID, tl.FromStepID, tl.CountyID
							from JobControl..Jobs j
									join JobControl..JobSteps js on js.jobID = j.JobID and js.QueryCriteriaID > 0 and js.QueryTemplateID = 1075
									join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID and ql.StateID > 0
									join Lookups..Counties c on c.StateID = ql.StateID
									join #AddableFiles tl on tl.CountyID = c.Id and tl.FileType = 'TrendLine'
							where j.CategoryID = 46
								and j.JobID = @JobID
						) x on jaf.ToJobStepID = x.ToStepID
									and jaf.FromJobStepID = x.FromStepID
									and jaf.Iteration_CountyID = x.CountyID
					where jaf.ToJobStepID = @ToStepID
						and jaf.Iteration_CountyID > 0
						and x.CountyID is null



		end


	end
	else  -- Towns selected
	begin

		print 'Clean All, Towns > 0'

			delete jaf
				from JobControl..JobAddedFiles jaf
				where jaf.ToJobStepID = @ToStepID
	end


	-- Clear and set Job depends on 

	delete JobControl..JobDepends where JobID = @JobID

	insert JobControl..JobDepends (JobID, DependsOnJobID)
	select distinct tjs.JObID, fjs.JobID 
		from JobControl..JobAddedFiles jaf
			join JobControl..JobSteps tjs on tjs.StepID = jaf.ToJobStepID
			join JobControl..JobSteps fjs on fjs.StepID = jaf.FromJobStepID
		where tjs.JobID = @JobID


END
