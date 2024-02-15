/****** Object:  View [dbo].[VFPJobs_ImportedReportStatus]    Committed by VersionSQL https://www.versionsql.com ******/

Create VIEW dbo.VFPJobs_ImportedReportStatus
AS

	select j.JobID, j.VFPJobID, jc.Description JobCat, jc.Code CatCode
			, qjs.StepOrder QueryStep
			--, q.TemplateID Query_TemplateID, qqt.FromPart Query_FromPart
			, tjs.StepOrder XFormStep
			, tt.Description XFormName, tt.QueryTemplateID XFrom_TemplateID, tqt.FromPart XFrom_FromPart
			, rjs.StepOrder ReportStep
			, rjs.ReportListID ReportID, r.Description ReportDesc
			, case when tjs.TransformationID is null then 'No XForm Specified'
					when rjs.ReportListID is null then 'No Report Specified'
					when r.Description is null then 'Report Not Defined'
				else '' end JobStatus 
		from JobControl..Jobs j
			join JobControl..JobCategories jc on jc.ID = j.CategoryID
			join JobControl..JobSteps qjs on qjs.JobID = j.JobID and qjs.StepTypeID = 21
			left outer join QueryEditor..Queries q on q.Id = qjs.QueryCriteriaID
			left outer join JobControl..JobSteps tjs on tjs.JobID = j.JobID and tjs.StepTypeID = 29 and tjs.DependsOnStepIDs like qjs.StepID 
			left outer join JobControl..TransformationTemplates tt on tt.Id = tjs.TransformationID
			left outer join JobControl..JobSteps ajs on ajs.JobID = j.JobID and ajs.StepTypeID = 1 and ajs.DependsOnStepIDs like '%' + ltrim(str(tjs.StepID)) + '%'
			left outer join JobControl..JobSteps rjs on rjs.JobID = j.JobID and rjs.StepTypeID = 22 and rjs.DependsOnStepIDs like coalesce(ajs.StepID,tjs.StepID) 
			left outer join JobControl..Reports r on r.Id = rjs.ReportListID
			left outer join JobControl..QueryTemplates qqt on qqt.ID = q.TemplateID
			left outer join JobControl..QueryTemplates tqt on tqt.ID = tt.QueryTemplateID
		where coalesce(j.IsTemplate,0) = 0
