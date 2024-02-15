/****** Object:  Procedure [dbo].[VFPJobs_SyncQueryTemplateIDs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobs_SyncQueryTemplateIDs @JobID int
AS
BEGIN
	SET NOCOUNT ON;

	 declare @StepID int, @QueryID int, @XFormID int, @FixQueryTemplateID int, @OrigQTemplateID int
     DECLARE curA CURSOR FOR
          select js.StepID, js.QueryCriteriaID, tt.ID
			--, coalesce(tt.QueryTemplateID,q.TemplateID,js.QueryTemplateID, x.ForceTemplateID)
			, coalesce(x.ForceTemplateID, x2.ForceTemplateID, tt.QueryTemplateID,q.TemplateID,js.QueryTemplateID)
			, q.TemplateID 
		from JobControl..JobSteps js
			join JobControl..Jobs j on j.JobID = js.JobID and coalesce(j.IsTemplate,0) = 0
			join JobControl..JobSteps tjs on tjs.StepTypeID = 29 and js.JobID = tjs.JobID and js.StepID = tjs.DependsOnStepIDs
			left outer join JobControl..TransformationTemplates tt on tt.Id = tjs.TransformationID
			left outer join QueryEditor..Queries q on q.Id = js.QueryCriteriaID
			--left outer join JobControl..VFPJobs_FinalForceQueryTemplateID x on x.VFP_BTCRITID = js.VFP_QueryID and x.VFPJobID = j.VFPJobID
			left outer join JobControl..VFPJobs_FinalForceQueryTemplateID x on x.VFP_BTCRITID = js.VFP_BTCRITID and x.VFPJobID = j.VFPJobID
			left outer join JobControl..VFPJobs_FinalForceQueryTemplateID x2 on x2.VFP_QueryID = js.VFP_QueryID and x2.VFPJobID = j.VFPJobID
		where js.StepTypeID = 21
			and case when @JobID is null
						and (coalesce(js.QueryTemplateID,-1) <> coalesce(tt.QueryTemplateID,-1)
							or coalesce(tt.QueryTemplateID,-1) <> coalesce(q.TemplateID,-1)
							or coalesce(q.TemplateID,-1) <> coalesce(js.QueryTemplateID,-1)
							or js.QueryTemplateID is null or tt.QueryTemplateID is null or q.TemplateID is null) then 1 
					when @JobID is not null and js.jobID = @JobID then 1
					else 0 end = 1

     OPEN curA

     FETCH NEXT FROM curA into @StepID, @QueryID, @XFormID, @FixQueryTemplateID, @OrigQTemplateID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
			if @FixQueryTemplateID <> coalesce(@OrigQTemplateID, -1)
				print 'R:\Wired3\Devel\Runable\QueryEditorSQLUpdate\QueryEditorSQLUpdate.exe ' + ltrim(str(@QueryID))

			update QueryEditor..Queries set TemplateID = @FixQueryTemplateID where ID = @QueryID
			update JobControl..JobSteps set QueryTemplateID = @FixQueryTemplateID where StepID = @StepID

          FETCH NEXT FROM curA into @StepID, @QueryID, @XFormID, @FixQueryTemplateID, @OrigQTemplateID
     END
     CLOSE curA
     DEALLOCATE curA

	 insert VFPJobs_FinalForceQueryTemplateID (JobID, js_QueryTemplateID, Q_TemplateID, XF_QueryTemplateID, VFPJobID, VFP_BTCRITID, ForceTemplateID, JobName, StepName)
	 select js.JobID, js.QueryTemplateID, q.TemplateID, tt.QueryTemplateID, j.VFPJobID, js.VFP_BTCRITID, null, j.JobName, js.StepName
		from JobControl..JobSteps js
			join JobControl..Jobs j on j.JobID = js.JobID and coalesce(j.IsTemplate,0) = 0
			join JobControl..JobSteps tjs on tjs.StepTypeID = 29 and js.JobID = tjs.JobID and js.StepID = tjs.DependsOnStepIDs
			left outer join JobControl..TransformationTemplates tt on tt.Id = tjs.TransformationID
			left outer join QueryEditor..Queries q on q.Id = js.QueryCriteriaID
			left outer join JobControl..VFPJobs_FinalForceQueryTemplateID x on x.VFP_BTCRITID = js.VFP_BTCRITID and x.VFPJobID = j.VFPJobID
		where js.StepTypeID = 21
			and (coalesce(js.QueryTemplateID,-1) <> coalesce(tt.QueryTemplateID,-1)
				or coalesce(tt.QueryTemplateID,-1) <> coalesce(q.TemplateID,-1)
				or coalesce(q.TemplateID,-1) <> coalesce(js.QueryTemplateID,-1)
				or js.QueryTemplateID is null or tt.QueryTemplateID is null or q.TemplateID is null)
			and coalesce(tt.QueryTemplateID,q.TemplateID,js.QueryTemplateID, x.ForceTemplateID) is null

	 --insert JobControl..VFPJobs_QueryToQueryTemplateForce (VFP_QueryID)
		--select distinct js.VFP_QueryID
		--	from JobControl..JobSteps js
		--		join JobControl..Jobs j on j.JobID = js.JobID and coalesce(j.IsTemplate,0) = 0
		--		join JobControl..JobSteps tjs on tjs.StepTypeID = 29 and js.JobID = tjs.JobID and js.StepID = tjs.DependsOnStepIDs
		--		left outer join JobControl..TransformationTemplates tt on tt.Id = tjs.TransformationID 
		--		left outer join QueryEditor..Queries q on q.Id = js.QueryCriteriaID
		--		left outer join JobControl..VFPJobs_FinalForceQueryTemplateID x on x.VFP_BTCRITID = js.VFP_BTCRITID and x.VFPJobID = j.VFPJobID
		--		left outer join JobControl..VFPJobs_QueryToQueryTemplateForce f on f.VFP_QueryID = js.VFP_QueryID
		--	where js.StepTypeID = 21
		--		and (coalesce(js.QueryTemplateID,-1) <> coalesce(tt.QueryTemplateID,-1)
		--			or coalesce(tt.QueryTemplateID,-1) <> coalesce(q.TemplateID,-1)
		--			or coalesce(q.TemplateID,-1) <> coalesce(js.QueryTemplateID,-1)
		--			or js.QueryTemplateID is null or tt.QueryTemplateID is null or q.TemplateID is null)
		--	and tt.QueryTemplateID is null and tt.VFPIn = 1
		--	and f.VFP_QueryID is null

END
