/****** Object:  Procedure [dbo].[GetLayoutSpecDetails]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetLayoutSpecDetails @JobID int 
	
AS
BEGIN

	--jobs with just report and xform
	select ds.StepID DelivStep
		,RS.StepID ReportStepID, RS.DependsOnStepIDs
		, replace(rs.StepFileNameAlgorithm,'<RO>',RS.NormalRunOption) FileName
		, replace(rs.StepFileNameAlgorithm,'<RO>',RS.FullRunOption) AltFileName
		, rs.ZipFileDirectly
		, coalesce(Ts.FileLayoutID, -1) LayoutID
		, Coalesce(coalesce(q.QueryText, q.SQLCMD), 'None') QueryText

		, case when LS.BeginLoopType = 1 then 'State'
				when LS.BeginLoopType = 1 then 'County'
				when LS.BeginLoopType = 1 then 'Town' else '' end LoopType

		, Coalesce(coalesce(lq.QueryText, lq.SQLCMD), '') LoopQueryText
		, coalesce(R.FixedWidth,0) FixedWidthRep
		, coalesce(qt.SourceCompany,'') DataSource
		, coalesce(DS.Disabled, 0 ) Disabled
		, coalesce(ds.FTPCreateSubDir,'') FTPCreateSubDir
	from JobControl..JobSteps DS 
		join JobControl..JobSteps RS on RS.JobID = DS.JobID 
												and ','+DS.DependsOnStepIDs+',' like '%,'+convert(varchar, RS.StepID)+',%' 
												and coalesce(RS.Disabled, 0 ) = 0 and rs.StepTypeID = 22
		join JobControl..Reports r on r.ID = RS.ReportListID
		left outer join JobControl..JobSteps TS on TS.JobID = RS.JobID 
												and ','+RS.DependsOnStepIDs+',' like '%,'+convert(varchar, TS.StepID)+',%' 
												and coalesce(TS.Disabled, 0 ) = 0 and ts.StepTypeID in (29,1101, 1116, 1117, 1125)
		left outer join JobControl..JobSteps QS on QS.JobID = RS.JobID 
												and ','+TS.DependsOnStepIDs+',' like '%,'+convert(varchar, QS.StepID)+',%' 
												and coalesce(QS.Disabled, 0 ) = 0 and qs.StepTypeID in (21,1124)
		left outer join QueryEditor..Queries q on q.ID = qs.QueryCriteriaID
		left outer join JobControl..QueryTemplates qt on qt.ID = q.TemplateID
		left outer join JobControl..JobSteps LS on LS.JobID = QS.JobID 
												and ',' + QS.DependsOnStepIDs + ',' like '%,'+convert(varchar, LS.StepID)+',%' 
												and coalesce(LS.Disabled, 0 ) = 0 and LS.StepTypeID in (1107)
		left outer join JobControl..JobSteps LQS on LQS.JobID = RS.JobID 
												and ','+LS.DependsOnStepIDs+',' like '%,'+convert(varchar, LQS.StepID)+',%' 
												and coalesce(LQS.Disabled, 0 ) = 0 and Lqs.StepTypeID in (21,1124)
		left outer join QueryEditor..Queries lq on lq.ID = lqs.QueryCriteriaID

	where ds.StepTypeID in (1091,1125) and DS.JobID in (@JobID) 
		and coalesce(Ts.FileLayoutID, -1) > 0
		--and coalesce(DS.Disabled, 0 ) = 0

	--jobs with zip steps

	union
	select ds.StepID DeliveryStepID
		, RS.StepID ReportStepID, RS.DependsOnStepIDs
		, replace(rs.StepFileNameAlgorithm,'<RO>',RS.NormalRunOption) FileName
		, replace(rs.StepFileNameAlgorithm,'<RO>',RS.FullRunOption) AltFileName
		, rs.ZipFileDirectly
		, coalesce(Ts.FileLayoutID, -1) LayoutID
		, Coalesce(coalesce(q.QueryText, q.SQLCMD), 'None') QueryText
		, '' LoopType
		, '' LoopQueryText
		, coalesce(R.FixedWidth,0) FixedWidthRep
		, coalesce(qt.SourceCompany,'') DataSource
		, coalesce(DS.Disabled, 0 ) Disabled
		, coalesce(ds.FTPCreateSubDir,'') FTPCreateSubDir

	from JobControl..JobSteps DS 
		join JobControl..JobSteps ZS on ZS.JobID = DS.JobID 
												and ','+DS.DependsOnStepIDs+',' like '%,'+convert(varchar, ZS.StepID)+',%' 
												and coalesce(ZS.Disabled, 0 ) = 0 and zs.StepTypeID in (1112,1079)
		left outer join JobControl..JobSteps RS on RS.JobID = zS.JobID 
												and ','+ZS.DependsOnStepIDs+',' like '%,'+convert(varchar, RS.StepID)+',%' 
												and coalesce(RS.Disabled, 0 ) = 0 and rs.StepTypeID = 22
		left outer join JobControl..Reports r on r.ID = RS.ReportListID
		left outer join JobControl..JobSteps TS on TS.JobID = RS.JobID 
												and ','+RS.DependsOnStepIDs+',' like '%,'+convert(varchar, TS.StepID)+',%' 
												and coalesce(TS.Disabled, 0 ) = 0 and ts.StepTypeID in (29,1101, 1116, 1117, 1125)
		left outer join JobControl..JobSteps QS on QS.JobID = RS.JobID 
												and ','+TS.DependsOnStepIDs+',' like '%,'+convert(varchar, QS.StepID)+',%' 
												and coalesce(QS.Disabled, 0 ) = 0 and qs.StepTypeID in (21,1124)
		left outer join QueryEditor..Queries q on q.ID = qs.QueryCriteriaID
		left outer join JobControl..QueryTemplates qt on qt.ID = q.TemplateID

	where ds.StepTypeID in (1091,1125) and DS.JobID in (@JobID) 
		and coalesce(Ts.FileLayoutID, -1) > 0
		--and coalesce(DS.Disabled, 0 ) = 0

	--jobs with append steps

	union
	select ds.StepID DeliveryStepID
		, RS.StepID ReportStepID, RS.DependsOnStepIDs
		, replace(rs.StepFileNameAlgorithm,'<RO>',RS.NormalRunOption) FileName
		, replace(rs.StepFileNameAlgorithm,'<RO>',RS.FullRunOption) AltFileName
		, rs.ZipFileDirectly
		, coalesce(Ts.FileLayoutID, -1) LayoutID
		, Coalesce(coalesce(q.QueryText, q.SQLCMD), 'None') QueryText
		, '' LoopType
		, '' LoopQueryText
		, coalesce(R.FixedWidth,0) FixedWidthRep
		, coalesce(qt.SourceCompany,'') DataSource
		, coalesce(DS.Disabled, 0 ) Disabled
		, coalesce(ds.FTPCreateSubDir,'') FTPCreateSubDir

	from JobControl..JobSteps DS 
		left outer join JobControl..JobSteps RS on RS.JobID = DS.JobID 
												and ','+DS.DependsOnStepIDs+',' like '%,'+convert(varchar, RS.StepID)+',%' 
												and coalesce(RS.Disabled, 0 ) = 0 and rs.StepTypeID = 22
		left outer join JobControl..Reports r on r.ID = RS.ReportListID
		left outer join JobControl..JobSteps ApS on ApS.JobID = RS.JobID 
												and ','+RS.DependsOnStepIDs+',' like '%,'+convert(varchar, ApS.StepID)+',%' 
												and coalesce(ApS.Disabled, 0 ) = 0 and ApS.StepTypeID = 1
		left outer join JobControl..JobSteps TS on TS.JobID = ApS.JobID 
												and ','+ApS.DependsOnStepIDs+',' like '%,'+convert(varchar, TS.StepID)+',%' 
												and coalesce(TS.Disabled, 0 ) = 0 and ts.StepTypeID in (29,1101, 1116, 1117, 1125)
		left outer join JobControl..JobSteps QS on QS.JobID = RS.JobID 
												and ','+TS.DependsOnStepIDs+',' like '%,'+convert(varchar, QS.StepID)+',%' 
												and coalesce(QS.Disabled, 0 ) = 0 and qs.StepTypeID in (21,1124)
		left outer join QueryEditor..Queries q on q.ID = qs.QueryCriteriaID
		left outer join JobControl..QueryTemplates qt on qt.ID = q.TemplateID

	where ds.StepTypeID in (1091,1125) and DS.JobID in (@JobID) 
		and coalesce(Ts.FileLayoutID, -1) > 0
END
