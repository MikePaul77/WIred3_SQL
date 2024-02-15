/****** Object:  Procedure [dbo].[VFPJobs_Get_ViewTemplateMapRecID]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE VFPJobs_Get_ViewTemplateMapRecID @XFormName varchar(100)
AS
BEGIN
	SET NOCOUNT ON;

		select distinct m.FromClause [VFPJobs_QueryFromClause.FromClause]
				--, m.VFPFuncFromClause [VFPJobs_QueryFromClause.VFPFuncFromClause]
				--, m.OrigVFPSelect [VFPJobs_QueryFromClause.OrigVFPSelect]
				, m.RecID [VFPJobs_QueryFromClause.RecID]
				, m.QueryTemplateID [VFPJobs_QueryFromClause.QueryTemplateID] 
				, qt.TemplateName [QueryTemplates.TemplateName]
				, qt.FromPart [QueryTemplates.FromPart (View)]
			from JobControl..JobSteps jsQ
				join JobControl..JobSteps jsX on jsX.StepTypeID = 29 and (jsQ.StepOrder + 1) = jsX.StepOrder and jsQ.JobID = jsX.JobID
				join QueryEditor..Queries Q on Q.ID = jsQ.QueryCriteriaID
				join (
							select Support.FuncLib.StringFromTo(SELECTEXP1,'from','where',1) FromClause
								, case when Support.FuncLib.StringFromTo(SELECTEXP1,'from','where',1) = '' then SELECTEXP1 else '' end OrigVFPSelect
								, js.QUERYID
							from Dataload..Jobs_MF_query jsq
								join Dataload..Jobs_jobsteps js on js.QUERYID = jsq.QUERY_ID and js.STEPTYPE = 'QUERY'
					) x on x.QUERYID = jsQ.VFP_QueryID
				join JobControl..VFPJobs_QueryFromClause m on m.FromClause = x.FromClause and m.OrigVFPSelect = x.OrigVFPSelect
				join JobControl..TransformationTemplates xf on xf.ShortTransformationName = jsX.VFP_LayoutID
				join JobControl..QueryTemplates qt on qt.Id = xf.QueryTemplateID
			where jsQ.VFPIn = 1
				and jsQ.StepTypeID = 21
				and jsX.VFP_LayoutID = 	@XFormName

END
