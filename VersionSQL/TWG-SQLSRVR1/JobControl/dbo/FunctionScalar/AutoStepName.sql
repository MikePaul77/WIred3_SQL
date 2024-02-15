/****** Object:  ScalarFunction [dbo].[AutoStepName]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.AutoStepName
(
	@StepID int
)
RETURNS varchar(500)
AS
BEGIN
	DECLARE @Result varchar(500)

	select @Result = case when js.StepTypeID in (21,1124) 
												then case when (qA.ID > 0 or qC.ID > 0 or qD.ID > 0) and qt.ID not in (1060) then
														'['
														+ substring(case when qA.ID > 0 and coalesce(qA.Exclude,0) = 0 then ',Adds' else '' end
																	+ case when qC.ID > 0 and coalesce(qC.Exclude,0) = 0  then ',Changes' else '' end
																	+ case when qD.ID > 0 and coalesce(qD.Exclude,0) = 0  then ',Deletes' else '' end
																	+ case when qA.ID > 0 and coalesce(qA.Exclude,0) = 1 then ',Not Adds' else '' end
																	+ case when qC.ID > 0 and coalesce(qC.Exclude,0) = 1  then ',Not Changes' else '' end
																	+ case when qD.ID > 0 and coalesce(qD.Exclude,0) = 1  then ',Not Deletes' else '' end
																,2,100)
														+ ']'
													else '' end + ' '  + JobControl.dbo.JobStepRunStates(js.StepID)

							else '' end
	from JobControl..JobSteps js
		--left outer join JobControl..JobStepTypes jst on jst.StepTypeID = js.StepTypeID
		left outer join JobControl..QueryTemplates qt on qt.Id = js.QueryTemplateID
		--left outer join JobControl..Reports r on r.Id = js.ReportListID
		--left outer join JobControl..TransformationTemplates tt on tt.Id = js.TransformationID
		--left outer join JobControl..FileLayouts fl on fl.Id = js.FileLayoutID
		--left outer join JobControl..Reports cr on cr.Id = js.ReportListID
		left outer join QueryEditor..QueryMultIDs qA on qA.QueryID = js.QueryCriteriaID and qA.ValueSource = 'ModificationType' and qA.ValueID = 1
		left outer join QueryEditor..QueryMultIDs qC on qC.QueryID = js.QueryCriteriaID and qC.ValueSource = 'ModificationType' and qC.ValueID = 2
		left outer join QueryEditor..QueryMultIDs qD on qD.QueryID = js.QueryCriteriaID and qD.ValueSource = 'ModificationType' and qD.ValueID = 3
		--left outer join JobControl..JobSteps ajs on ajs.StepID = js.QuerySourceStepID
	where js.StepID = @StepID

	--select @Result = coalesce(case when js.StepTypeID = 21 
	--											then qt.TemplateName 
	--											-- + case when js.QueryTemplateID = 1060 then ' ' + JobControl.dbo.JobStepRunStates(js.StepID) else '' end 
	--											+ case when (qA.ID > 0 or qC.ID > 0 or qD.ID > 0) and qt.ID not in (1060) then
	--													' ['
	--													+ substring(case when qA.ID > 0 and coalesce(qA.Exclude,0) = 0 then ',Adds' else '' end
	--																+ case when qC.ID > 0 and coalesce(qC.Exclude,0) = 0  then ',Changes' else '' end
	--																+ case when qD.ID > 0 and coalesce(qD.Exclude,0) = 0  then ',Deletes' else '' end
	--																+ case when qA.ID > 0 and coalesce(qA.Exclude,0) = 1 then ',Not Adds' else '' end
	--																+ case when qC.ID > 0 and coalesce(qC.Exclude,0) = 1  then ',Not Changes' else '' end
	--																+ case when qD.ID > 0 and coalesce(qD.Exclude,0) = 1  then ',Not Deletes' else '' end
	--															,2,100)
	--													+ ']'
	--												else '' end + case when coalesce(js.QuerySourceStepID,0) > 0 
	--																then ' AltSourceStep: ' + ltrim(str(ajs.StepOrder)) 
	--																else ' '  + JobControl.dbo.JobStepRunStates(js.StepID) end

	--										when js.StepTypeID = 1107 then 'Loop through ' + CASE WHEN js.BeginLoopType = 1 THEN 'States'
	--																						WHEN js.BeginLoopType = 2 THEN 'Counties'
	--																						ELSE 'Towns' end
	--										when js.StepTypeID = 22 then r.ReportName + ' / ' + js.StepFileNameAlgorithm 
	--										when js.StepTypeID = 1101 then r.ReportName + ' / ' + js.StepFileNameAlgorithm 
	--										when js.StepTypeID = 29 then tt.ShortTransformationName + '/' + fl.ShortFileLayoutName
	--										else null end
	--									, jst.StepDescription, '')
	--from JobControl..JobSteps js
	--	left outer join JobControl..JobStepTypes jst on jst.StepTypeID = js.StepTypeID
	--	left outer join JobControl..QueryTemplates qt on qt.Id = js.QueryTemplateID
	--	left outer join JobControl..Reports r on r.Id = js.ReportListID
	--	left outer join JobControl..TransformationTemplates tt on tt.Id = js.TransformationID
	--	left outer join JobControl..FileLayouts fl on fl.Id = js.FileLayoutID
	--	left outer join JobControl..Reports cr on cr.Id = js.ReportListID
	--	left outer join QueryEditor..QueryMultIDs qA on qA.QueryID = js.QueryCriteriaID and qA.ValueSource = 'ModificationType' and qA.ValueID = 1
	--	left outer join QueryEditor..QueryMultIDs qC on qC.QueryID = js.QueryCriteriaID and qC.ValueSource = 'ModificationType' and qC.ValueID = 2
	--	left outer join QueryEditor..QueryMultIDs qD on qD.QueryID = js.QueryCriteriaID and qD.ValueSource = 'ModificationType' and qD.ValueID = 3
	--	left outer join JobControl..JobSteps ajs on ajs.StepID = js.QuerySourceStepID
	--where js.StepID = @StepID


	RETURN @Result

END
