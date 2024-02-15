/****** Object:  View [dbo].[EditXForms]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE VIEW dbo.EditXForms
AS

select j.JobID, js.StepID, js.StepOrder
	, tt.ShortTransformationName
	, qt.FromPart
	, fl.ShortFileLayoutName
	, js2.StepFileNameAlgorithm
	, flf.OutOrder, flf.OutName, tc.SourceCode, tc.VFPSourceCode, tc.VFPIn_Status, flf.RecID
	from JobControl..Jobs j
		join JobControl..JobSteps js on j.JobID = js.JobID
		join JobControl..TransformationTemplates tt on tt.Id = js.TransformationID
		join JobControl..QueryTemplates qt on qt.Id = tt.QueryTemplateID
		join JobControl..TransformationTemplateColumns tc on tc.TransformTemplateID = tt.Id
		join JobControl..FileLayouts fl on fl.id = js.FileLayoutID
		join JobControl..FileLayoutFields flf on flf.FileLayoutID = fl.ID and flf.SrcName = 'XF_' + tc.OutName
		left outer join JobControl..JobSteps js2 on j.JobID = js.JobID and ',' + js2.DependsOnStepIDs +',' like '%,' + ltrim(str(js.stepID)) + ',%' and js2.StepTypeID = 22 
