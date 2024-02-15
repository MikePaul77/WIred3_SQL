/****** Object:  Procedure [dbo].[JobQTSyncCheck]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE JobQTSyncCheck @JobStepID int, @InproductionOnly bit
AS
BEGIN
	SET NOCOUNT ON;



	select j.JobID, j.JobName, J.InProduction
		, qjs.QueryTemplateID JobTemplateID, jqt.TemplateName JobTemplateName, jqt.FromPart JobFrom
		, q.TemplateID QueryTemplateID, qqt.TemplateName QueryTemplateName, qqt.FromPart QueryFrom
		, tt.QueryTemplateID XformTemplateID, tqt.TemplateName XFormTemplateName, tqt.FromPart XFormFrom
		, qjs.StepID QueryStepID 
		, QJS.QueryCriteriaID
		, tjs.StepID XFormStepID
		, tt.ID XFromID
		, XFJs.Jobs XFromInJobs

		, 'update JobControl..TransformationTemplates set QueryTemplateID = ? where ID in (' + ltrim(str(tt.ID)) + ')' XFormCMD
		, 'update JobControl..JobSteps set QueryTemplateID = ? where stepID IN (' + ltrim(str(qjs.StepID)) + ')' JobStepCMD 
		, 'update QueryEditor..Queries set TemplateID = ? where id IN (' + ltrim(str(QJS.QueryCriteriaID)) + ')' QueryCMD 


		from JobControl..JobSteps qjs
			join JobControl..Jobs j on j.JobID = qjs.JobID and coalesce(j.disabled,0) = 0 and coalesce(j.Deleted,0) = 0
			left outer join QueryEditor..Queries q on q.ID = qjs.QueryCriteriaID
			left outer join JobControl..JobSteps tjs on j.JobID = tjs.jobid and tjs.StepTypeID = 29 
														and ',' + tjs.DependsOnStepIDs + ',' like '%,' + ltrim(str(qjs.StepID)) + ',%'
			left outer join JobControl..TransformationTemplates tt on tt.id = tjs.TransformationID
			left outer join (select js.TransformationID, count(distinct j.JobID) Jobs 
								from JobControl..JobSteps js
									join JobControl..Jobs J on j.jobID = js.JobID and coalesce(j.disabled,0) = 0 and coalesce(j.Deleted,0) = 0
								where coalesce(js.disabled,0) = 0
									and case when J.InProduction = 1 and @InproductionOnly = 1 then 1
											when coalesce(@InproductionOnly,0) = 0 then 1 else 0
											end = 1
								group by js.TransformationID ) XFJs on XFJs.TransformationID = tt.id
			left outer join QueryTemplates jqt on jqt.Id = qjs.QueryTemplateID
			left outer join QueryTemplates qqt on qqt.Id = q.TemplateID
			left outer join QueryTemplates tqt on tqt.Id = tt.QueryTemplateID
		where qjs.StepTypeID in (21,1124)
			and coalesce(qjs.disabled,0) = 0
			and case when coalesce(@JobStepID,0) > 0 then 1
					when J.InProduction = 1 and @InproductionOnly = 1 then 1
					when coalesce(@InproductionOnly,0) = 0 then 1 
					else 0 end = 1
			and case when coalesce(@JobStepID,0) > 0 and (@JobStepID = qjs.StepID or @JobStepID = tjs.StepID) then 1
					when coalesce(@JobStepID,0) = 0 then 1 
					else 0 end = 1
		
			and (qjs.QueryTemplateID <> q.TemplateID
					or qjs.QueryTemplateID <> tt.QueryTemplateID
					or q.TemplateID <> tt.QueryTemplateID
			)
		order by j.JobID


END
