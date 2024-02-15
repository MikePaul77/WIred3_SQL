/****** Object:  Procedure [dbo].[NewsPaperReprintJobs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE NewsPaperReprintJobs
AS
BEGIN
	SET NOCOUNT ON;

	select count(distinct j.jobID) Jobs
			, tt.Id, tt.ShortTransformationName
			, fl.Id, fl.ShortFileLayoutName
			, r.Id, r.Description
		from JobControl..Jobs j
			join JobControl..JobSteps jst on jst.JobID = j.jobID and jst.StepTypeID = 29 and coalesce(jst.disabled,0) = 0
			join JobControl..JobSteps jsr on jsr.JobID = j.jobID and jsr.StepTypeID = 22 and coalesce(jsr.disabled,0) = 0
			join JobControl..TransformationTemplates tt on tt.id = jst.TransformationID
			join JobControl..FileLayouts fl on fl.id = jst.FileLayoutID
			join JobControl..Reports r on r.id = jsr.ReportListID
		where j.InProduction = 1 
			and coalesce(j.disabled,0) = 0
			and j.CategoryID in (12,13)
	group by  tt.Id, tt.ShortTransformationName
			, fl.Id, fl.ShortFileLayoutName
			, r.Id, r.Description
	order by 1 desc,  tt.ShortTransformationName
			, fl.ShortFileLayoutName
			, r.Description



END
