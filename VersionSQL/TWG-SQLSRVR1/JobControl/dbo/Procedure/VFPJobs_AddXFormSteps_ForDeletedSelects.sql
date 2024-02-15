/****** Object:  Procedure [dbo].[VFPJobs_AddXFormSteps_ForDeletedSelects]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobs_AddXFormSteps_ForDeletedSelects @TemplateID int, @JobID int
AS
BEGIN
	SET NOCOUNT ON;

		declare @LastTansformStepID int = 0
		declare @NewTransformStepID int = 0
		declare @LastJobStepID int = 0
		declare @NewJobStepID int = 0
		declare @LastLayoutID int = 0
		declare @NewLayoutID int = 0
		declare @DelSelectStepID int = 0

		declare @JobTemplateID int, @TemplateStepID int, @StepName varchar(500), @StepOrder int, @StepTypeID int, @DependsOnStepIDs varchar(2000), @TransformationID int , @FileLayoutID int, @QueryCriteriaID int, @QueryTemplateID int, @DelQuery int, @SelQuery int, @DelIDRep int
		declare @JobStepID int

		--if @TemplateID is not null
		--begin

		--	DECLARE curB CURSOR FOR
		--		select jts.TemplateID, jts.ID, StepName, StepOrder, StepTypeID, DependsOnStepIDs, TransformationID, FileLayoutID
		--				, jts.QueryCriteriaID, q.TemplateID 
		--				, case when ValueID = 3 then 1 else 0 end DelQuery
		--			from JobControl..JobTemplateSteps jts
						
		--				left outer join QueryEditor.. Queries q on q.ID = jts.QueryCriteriaID 
		--				left outer join QueryEditor..QueryMultIDs qm on qm.queryId = q.ID and qm.valueSource = 'ModificationType'
		--			where jts.VFPIn = 1
		--				and jts.TemplateID = @TemplateID
		--			order by jts.TemplateID, StepOrder


		--	 OPEN curB

		--	 FETCH NEXT FROM curB into @JobTemplateID, @TemplateStepID, @StepName, @StepOrder, @StepTypeID, @DependsOnStepIDs, @TransformationID, @FileLayoutID, @QueryCriteriaID, @QueryTemplateID, @DelQuery
		--	 WHILE (@@FETCH_STATUS <> -1)
		--	 BEGIN

		--		if @StepTypeID = 29
		--		Begin
		--			set @LastTansformStepID = @TemplateStepID
		--			set @LastLayoutID = @FileLayoutID
		--		end

		--		if @DelQuery = 1
		--		begin

		--			set @DelSelectStepID = @TemplateStepID

		--			update JobControl..JobTemplateSteps set StepOrder = StepOrder + 1
		--				where TemplateID = @JobTemplateID
		--					and StepOrder > @StepOrder
				

		--			insert JobControl..FileLayouts (TransformationTemplateId, ShortFileLayoutName, Description, DefaultLayout, VFPIn)
		--			select fl.TransformationTemplateId, 'AutoDel-' + fl.ShortFileLayoutName, 'AutoDel-' + fl.Description, 0, 1 
		--				from JobControl..FileLayouts fl
		--			where fl.Id = @LastLayoutID

		--			set @NewLayoutID = SCOPE_IDENTITY()

		--			insert JobControl..FileLayoutFields (FileLayoutID, OutOrder, SortOrder, SortDir, OutType, OutWidth, SrcName, OutName, Disabled, CaseChange, DoNotTrim, Padding, PaddingLength, PaddingChar, VFPIn)
		--			select @NewLayoutID, OutOrder, SortOrder, SortDir, OutType, OutWidth, SrcName, OutName, Disabled, CaseChange, DoNotTrim, Padding, PaddingLength, PaddingChar, VFPIn
		--				from JobControl..FileLayoutFields
		--				where FileLayoutID = @LastLayoutID

		--			update JobControl..FileLayoutFields
		--				set SrcName = ''
		--				where FileLayoutID = @NewLayoutID
		--					and OutOrder > 1

		--			insert JobControl..JobTemplateSteps (TemplateID, StepName, StepOrder, StepTypeID, RunModeID, TransformationId, FileLayoutId, VFPIn, DependsOnStepIDs)
		--			select TemplateID, 'AutoXForm-' + StepName, @StepOrder + 1, StepTypeID, RunModeID, TransformationId, @NewLayoutID, VFPIn, ltrim(str(@DelSelectStepID))
		--				from JobControl..JobTemplateSteps where ID = @LastTansformStepID
			
		--			set @NewTransformStepID = SCOPE_IDENTITY()
		--		end

		--		if @StepTypeID = 1
		--		begin

		--			update JobControl..JobTemplateSteps 
		--					set DependsOnStepIDs = ltrim(str(@LastTansformStepID)) + ',' + ltrim(str(@NewTransformStepID))
		--				where ID = @TemplateStepID

		--			set @LastTansformStepID = 0
		--			set @NewTransformStepID = 0
		--			set @LastLayoutID = 0
		--			set @NewLayoutID = 0
		--			set @DelSelectStepID = 0
		--		end


		--		FETCH NEXT FROM curB into @JobTemplateID, @TemplateStepID, @StepName, @StepOrder, @StepTypeID, @DependsOnStepIDs, @TransformationID, @FileLayoutID, @QueryCriteriaID, @QueryTemplateID, @DelQuery
		--	 END
		--	 CLOSE curB
		--	 DEALLOCATE curB

		-- end

		if @JobID is not null
		begin

			DECLARE curB CURSOR FOR
				select js.JobID, js.StepID, js.StepName, js.StepOrder, js.StepTypeID, js.DependsOnStepIDs, js.TransformationID, js.FileLayoutID
						, js.QueryCriteriaID, q.TemplateID 
						, case when ValueID = 3 then 1 else 0 end DelQuery
						, case when js.StepTypeID = 21 and js2.StepTypeID = 1 then 1 else 0 end SelQuery
						, case when js3.StepID > 0 then 1 else 0 end DelIDRep
					from JobControl..JobSteps js
						left outer join QueryEditor.. Queries q on q.ID = js.QueryCriteriaID 
						left outer join QueryEditor..QueryMultIDs qm on qm.queryId = q.ID and qm.valueSource = 'ModificationType'
						left outer join JobControl..JobSteps js2 on js2.jobid = js.JobID and (js2.StepOrder - 1) = js.StepOrder
						left outer join JobControl..JobSteps js3 on js3.jobid = js.JobID and (js3.StepOrder - 1) = js.StepOrder and js3.VFP_ReportID in ('XLWebDT','XLWebDP','XLWebDC','XLWebDA','XLWebDD') 
					where js.VFPIn = 1
						and js.JobID = @JobID
					order by js.JobID, StepOrder


			 OPEN curB

			 FETCH NEXT FROM curB into @JobID, @JobStepID, @StepName, @StepOrder, @StepTypeID, @DependsOnStepIDs, @TransformationID, @FileLayoutID, @QueryCriteriaID, @QueryTemplateID, @DelQuery, @SelQuery, @DelIDRep
			 WHILE (@@FETCH_STATUS <> -1)
			 BEGIN

				if @StepTypeID = 29
				Begin
					set @LastJobStepID = @JobStepID
					set @LastLayoutID = @FileLayoutID
				end

				if @DelQuery = 1
				begin

					set @DelSelectStepID = @JobStepID

					update JobControl..JobSteps set StepOrder = StepOrder + 1
						where JobID = @JobID
							and StepOrder > @StepOrder

					insert JobControl..FileLayouts (TransformationTemplateId, ShortFileLayoutName, Description, DefaultLayout, VFPIn)
					select fl.TransformationTemplateId, 'AutoDel-' + fl.ShortFileLayoutName, 'AutoDel-' + fl.Description, 0, 1 
						from JobControl..FileLayouts fl
					where fl.Id = @LastLayoutID

					set @NewLayoutID = SCOPE_IDENTITY()

					insert JobControl..FileLayoutFields (FileLayoutID, OutOrder, SortOrder, SortDir, OutType, OutWidth, SrcName, OutName, Disabled, CaseChange, DoNotTrim, Padding, PaddingLength, PaddingChar, VFPIn)
					select @NewLayoutID, OutOrder, SortOrder, SortDir, OutType, OutWidth, SrcName, OutName, Disabled, CaseChange, DoNotTrim, Padding, PaddingLength, PaddingChar, VFPIn
						from JobControl..FileLayoutFields
						where FileLayoutID = @LastLayoutID

					update JobControl..FileLayoutFields
						set SrcName = ''
						where FileLayoutID = @NewLayoutID
							and OutOrder > 1

					insert JobControl..JobSteps (JobID, StepName, StepOrder, StepTypeID, RunModeID, TransformationId, FileLayoutId, VFPIn, DependsOnStepIDs)
					select distinct JobID, 'AutoXForm-DQ-' + StepName, @StepOrder + 1, StepTypeID, RunModeID, TransformationId, @NewLayoutID, VFPIn, ltrim(str(@DelSelectStepID))
						from JobControl..JobSteps where StepID = @LastJobStepID
			
					set @NewJobStepID = SCOPE_IDENTITY()
				end

				if @DelIDRep = 1
				begin

					set @DelSelectStepID = @JobStepID

					update JobControl..JobSteps set StepOrder = StepOrder + 1
						where JobID = @JobID
							and StepOrder > @StepOrder

					insert JobControl..FileLayouts (TransformationTemplateId, ShortFileLayoutName, Description, DefaultLayout, VFPIn)
					select fl.TransformationTemplateId, 'AutoDel-' + fl.ShortFileLayoutName, 'AutoDel-' + fl.Description, 0, 1 
						from JobControl..FileLayouts fl
					where fl.Id = @LastLayoutID

					set @NewLayoutID = SCOPE_IDENTITY()

					insert JobControl..FileLayoutFields (FileLayoutID, OutOrder, SortOrder, SortDir, OutType, OutWidth, SrcName, OutName, Disabled, CaseChange, DoNotTrim, Padding, PaddingLength, PaddingChar, VFPIn)
					select @NewLayoutID, OutOrder, SortOrder, SortDir, OutType, OutWidth, SrcName, OutName, Disabled, CaseChange, DoNotTrim, Padding, PaddingLength, PaddingChar, VFPIn
						from JobControl..FileLayoutFields
						where FileLayoutID = @LastLayoutID
							and OutOrder = 1

					insert JobControl..JobSteps (JobID, StepName, StepOrder, StepTypeID, RunModeID, TransformationId, FileLayoutId, VFPIn, DependsOnStepIDs)
					select JobID, 'AutoXForm-DI-' + StepName, @StepOrder + 1, StepTypeID, RunModeID, TransformationId, @NewLayoutID, VFPIn, ltrim(str(@DelSelectStepID))
						from JobControl..JobSteps where StepID = @LastJobStepID
			
					set @NewJobStepID = SCOPE_IDENTITY()

					update jsx set DependsOnStepIDs = js.StepID
						from JobControl..JobSteps jsx
							join JobControl..JobSteps js on jsx.DependsOnStepIDs = js.DependsOnStepIDs and jsx.StepID <> js.StepID
						where js.StepID = @NewJobStepID

				end

				if @SelQuery = 1 and @DelQuery = 0
				begin

					set @DelSelectStepID = @JobStepID

					update JobControl..JobSteps set StepOrder = StepOrder + 1
						where JobID = @JobID
							and StepOrder > @StepOrder

					insert JobControl..JobSteps (JobID, StepName, StepOrder, StepTypeID, RunModeID, TransformationId, FileLayoutId, VFPIn, DependsOnStepIDs)
					select JobID, 'AutoXForm-SQ-' + StepName, @StepOrder + 1, StepTypeID, RunModeID, TransformationId, FileLayoutId, VFPIn, ltrim(str(@DelSelectStepID))
						from JobControl..JobSteps where StepID = @LastJobStepID
			
					set @NewJobStepID = SCOPE_IDENTITY()
				end

				if @StepTypeID  = 1
				begin

					update JobControl..JobSteps 
							set DependsOnStepIDs = ltrim(str(@LastJobStepID)) + ',' + ltrim(str(@NewJobStepID))
						where StepID = @JobStepID

					set @LastJobStepID = 0
					set @NewJobStepID = 0
					set @LastLayoutID = 0
					set @NewLayoutID = 0
					set @DelSelectStepID = 0
				end


				FETCH NEXT FROM curB into @JobID, @JobStepID, @StepName, @StepOrder, @StepTypeID, @DependsOnStepIDs, @TransformationID, @FileLayoutID, @QueryCriteriaID, @QueryTemplateID, @DelQuery, @SelQuery, @DelIDRep
			 END
			 CLOSE curB
			 DEALLOCATE curB

		 end
END
