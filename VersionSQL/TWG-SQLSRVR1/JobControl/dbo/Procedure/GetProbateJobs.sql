/****** Object:  Procedure [dbo].[GetProbateJobs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetProbateJobs
AS
BEGIN
	SET NOCOUNT ON;

	select j.JobName, j.JobID, coalesce(j.disabled,0) disabled, coalesce(j.JobNameAddition,'') JobNameAddition
		, coalesce(qsp.updatedStamp, qspp.updatedStamp, qsd.updatedStamp, '') updatestamp
		, coalesce(substring((select ', ' + x.code 
				from (select distinct s.code 
					from QueryEditor..QueryLocations ql
						join Lookups..States s on s.Id = ql.StateID
					where ql.QueryID = coalesce(qsp.QueryCriteriaID,qspp.QueryCriteriaID,qsd.QueryCriteriaID) and ql.stateID > 0
					)x 
				order by x.code
				for XML path('') 
			),2,2000), '-NONE-') States
		, coalesce(substring((select ', ' + c.FullName +',' +s.code + ' ('+s.StateFIPS + c.CountyFIPS + ')'
				from QueryEditor..QueryLocations ql
					join Lookups..Counties c on c.id = ql.CountyID 
					join Lookups..States s on s.Id = c.StateID
				where ql.QueryID = coalesce(qsp.QueryCriteriaID,qspp.QueryCriteriaID,qsd.QueryCriteriaID) and ql.CountyID > 0
				order by c.FullName
				for XML path('') 
			),2,4000), '-NONE-') Counties
			,coalesce(substring((select ', ' + s.StateFIPS + c.CountyFIPS 
				from QueryEditor..QueryLocations ql
					join Lookups..Counties c on c.id = ql.CountyID 
					join Lookups..States s on s.Id = c.StateID
				where ql.QueryID = coalesce(qsp.QueryCriteriaID,qspp.QueryCriteriaID,qsd.QueryCriteriaID) and ql.CountyID > 0
				order by c.FullName
				for XML path('') 
			),2,4000), '-NONE-') CountyFIPS
		, substring((select '; ' + dd.DestAddress
				from JobControl..DeliveryJobSteps djs
					join JobControl..DeliveryDests dd on dd.id = djs.DeliveryDestID --and dd.DisabledStamp is null
				where djs.JobStepID = coalesce(dsp.StepID,dspp.StepID,dsd.StepID) and djs.DisabledStamp is null
				order by dd.DestAddress
				for XML path('') 
			),2,2000) emails		
			,j.FinalParamTarget
			,case when qspp.Disabled = 1 or xspp.Disabled = 1 or rspp.Disabled = 1 then 0 else 1 end PPEnabled
			,case when qsp.Disabled = 1 or xsp.Disabled = 1 or rsp.Disabled = 1 then 0 else 1 end PEnabled
			,case when qsd.Disabled = 1 or xsd.Disabled = 1 or rsd.Disabled = 1 then 0 else 1 end DEnabled
			, j.CustID

			, qsp.stepID, qspp.stepID, qsd.stepID
			, xsp.stepID, xspp.stepID, xsd.stepID
			, rsp.stepID, rspp.stepID, rsd.stepID
			, dsp.stepID, dspp.stepID, dsd.stepID

			, case when nd.JobID is not null then 1 else 0 end NeedsData

		from JobControl..Jobs j 
			left outer join JobControl..JobSteps qsp on qsp.QueryTemplateID in (1133) and qsp.JobID = j.JobID and qsp.StepTypeID = 1124 
			left outer join JobControl..JobSteps qspp on qspp.QueryTemplateID in (1132) and qspp.JobID = j.JobID and qspp.StepTypeID = 1124 
			left outer join JobControl..JobSteps qsd on qsd.QueryTemplateID in (1134) and qsd.JobID = j.JobID and qsd.StepTypeID = 1124 

			left outer join jobcontrol..jobsteps xsp on ','+xsp.DependsOnStepIDs+',' like '%,'+ltrim(str(qsp.StepID))+',%' and xsp.JobID = j.JobID and xsp.StepTypeID = 29 
			left outer join jobcontrol..jobsteps xspp on ','+xspp.DependsOnStepIDs+',' like '%,'+ltrim(str(qspp.StepID))+',%' and xspp.JobID = j.JobID and xspp.StepTypeID = 29 
			left outer join jobcontrol..jobsteps xsd on ','+xsd.DependsOnStepIDs+',' like '%,'+ltrim(str(qsd.StepID))+',%' and xsd.JobID = j.JobID and xsd.StepTypeID = 29 

			left outer join jobcontrol..jobsteps rsp on ','+rsp.DependsOnStepIDs+',' like '%,'+ltrim(str(xsp.StepID))+',%' and rsp.JobID = j.JobID and rsp.StepTypeID = 22 
															and rsp.StepFileNameAlgorithm like '<MMDDYYYY>_<IW6>_<ST>_%.xlsx'
			left outer join jobcontrol..jobsteps rspp on ','+rspp.DependsOnStepIDs+',' like '%,'+ltrim(str(xspp.StepID))+',%' and rspp.JobID = j.JobID and rspp.StepTypeID = 22 
															and rspp.StepFileNameAlgorithm like '<MMDDYYYY>_<IW6>_<ST>_%.xlsx'
			left outer join jobcontrol..jobsteps rsd on ','+rsd.DependsOnStepIDs+',' like '%,'+ltrim(str(xsd.StepID))+',%' and rsd.JobID = j.JobID and rsd.StepTypeID = 22 
															and rsd.StepFileNameAlgorithm like '<MMDDYYYY>_<IW6>_<ST>_%.xlsx'

			left outer join jobcontrol..jobsteps dsp on ','+dsp.DependsOnStepIDs+',' like '%,'+ltrim(str(rsp.StepID))+',%' and dsp.JobID = j.JobID and dsp.StepTypeID = 1125 and coalesce(dsp.Disabled,0) = 0
			left outer join jobcontrol..jobsteps dspp on ','+dspp.DependsOnStepIDs+',' like '%,'+ltrim(str(rspp.StepID))+',%' and dspp.JobID = j.JobID and dspp.StepTypeID = 1125 and coalesce(dspp.Disabled,0) = 0
			left outer join jobcontrol..jobsteps dsd on ','+dsd.DependsOnStepIDs+',' like '%,'+ltrim(str(rsd.StepID))+',%' and dsd.JobID = j.JobID and dsd.StepTypeID = 1125 and coalesce(dsd.Disabled,0) = 0
			left outer join (select distinct j.JobID
								from JobControl..Jobs j 
									left outer join JobControl..JobSteps qsp on qsp.QueryTemplateID in (1133) and qsp.JobID = j.JobID and qsp.StepTypeID = 1124 
									left outer join JobControl..JobSteps qspp on qspp.QueryTemplateID in (1132) and qspp.JobID = j.JobID and qspp.StepTypeID = 1124 
									left outer join JobControl..JobSteps qsd on qsd.QueryTemplateID in (1134) and qsd.JobID = j.JobID and qsd.StepTypeID = 1124 
									join QueryEditor..QueryLocations ql on ql.QueryID = coalesce(qsp.QueryCriteriaID,qspp.QueryCriteriaID,qsd.QueryCriteriaID) and ql.CountyID > 0
									join Lookups..Counties c on c.id = ql.CountyID 
									join Lookups..States s on s.Id = c.StateID
									left outer join Lookups..CountryExceptions ceP on cep.Countyid = C.id AND cep.DataType = 'Probate'
									left outer join Lookups..CountryExceptions cePP on cePP.Countyid = C.id AND cepp.DataType = 'PreProbate'
									left outer join Lookups..CountryExceptions ced on ceD.Countyid = C.id AND ced.DataType = 'Divorce'
								where j.CategoryID = 47 and j.IsTemplate = 0 and j.jobid != 6669 
									and coalesce(j.deleted,0) = 0
									and j.InProduction = 1
									and (( coalesce(c.InProbate,0) = 0 and coalesce(qsp.Disabled,0) = 0 and cep.countyID is null)
											or ( coalesce(c.InPreProbate,0) = 0 and coalesce(qspp.Disabled,0) = 0 and cepp.countyID is null )
											or ( coalesce(c.InDivorce,0) = 0 and coalesce(qsd.Disabled,0) = 0 and ced.countyID is null))
							) nd on nd.JobID = j.JobID


		where j.CategoryID = 47 and j.IsTemplate = 0 and j.jobid != 6669 
			and coalesce(j.deleted,0) = 0 
			and j.InProduction = 1
			order by j.jobid





-- before 	 ----------------------------------------------
--select distinct j.JobName, j.JobID, coalesce(j.disabled,0) disabled
--		--, coalesce(s.Code,'') state
--				, coalesce(substring((select ', ' + x.code 
--				from (select distinct s.code 
--					from QueryEditor..QueryLocations ql
--						join Lookups..States s on s.Id = ql.StateID
--					where ql.QueryID = js.QueryCriteriaID and ql.stateID > 0
--					)x 
--				order by x.code
--				for XML path('') 
--			),2,2000), '-NONE-') States
--		, coalesce(substring((select ', ' + c.FullName +',' +s.code + ' ('+s.StateFIPS + c.CountyFIPS + ')'
--				from QueryEditor..QueryLocations ql
--					join Lookups..Counties c on c.id = ql.CountyID 
--					join Lookups..States s on s.Id = c.StateID
--				where ql.QueryID = js.QueryCriteriaID and ql.CountyID > 0
--				order by c.FullName
--				for XML path('') 
--			),2,4000), '-NONE-') Counties
--			,coalesce(substring((select ', ' + s.StateFIPS + c.CountyFIPS 
--				from QueryEditor..QueryLocations ql
--					join Lookups..Counties c on c.id = ql.CountyID 
--					join Lookups..States s on s.Id = c.StateID
--				where ql.QueryID = js.QueryCriteriaID and ql.CountyID > 0
--				order by c.FullName
--				for XML path('') 
--			),2,4000), '-NONE-') CountyFIPS
--		, substring((select '; ' + dd.DestAddress
--				from JobControl..DeliveryJobSteps djs
--					join JobControl..DeliveryDests dd on dd.id = djs.DeliveryDestID and dd.DisabledStamp is null
--				where djs.JobStepID = js2.StepID and djs.DisabledStamp is null
--				order by dd.DestAddress
--				for XML path('') 
--			),2,2000) emails		
--			,j.FinalParamTarget
--			,case when (pp.QueryStepDisabled = 1 or pp.XformStepDisabled = 1 or  pp.ReportStepDisabled = 1) then 0 else 1 end PPEnabled
--			,case when (p.QueryStepDisabled = 1 or p.XformStepDisabled = 1 or  p.ReportStepDisabled = 1) then 0 else 1 end PEnabled
--			,case when (d.QueryStepDisabled = 1 or d.XformStepDisabled = 1 or  d.ReportStepDisabled = 1) then 0 else 1 end DEnabled
--			, j.CustID
--		from JobControl..Jobs j 
--			join JobControl..JobSteps js on js.jobID = j.JobID and js.QueryCriteriaID > 0 and coalesce(js.disabled, 0) = 0
--			join JobControl..JobSteps js2 on js2.jobID = j.JobID and js2.StepTypeID in (1091,1125)
--			--left outer join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID and ql.CountyID is not null
--			--left outer join Lookups..Counties c on c.Id = ql.CountyID
--			--left outer join Lookups..States s on s.Id = c.StateID 
--			left outer join (select js.JobID, js.StepID QuerystepID, xs.StepID xformStepID, rs.StepID reporststepid  
--								, coalesce(js.Disabled,0) QueryStepDisabled,coalesce(xs.Disabled, 0) XformStepDisabled, coalesce(rs.Disabled, 0) ReportStepDisabled
--								from JobControl..JobSteps js
--								join jobcontrol..jobsteps xs on ','+xs.DependsOnStepIDs+',' like ','+ltrim(str(js.StepID))+',' and xs.JobID = js.JobID and xs.StepTypeID = 29
--								join jobcontrol..jobsteps rs on ','+rs.DependsOnStepIDs+',' like ','+ltrim(str(xs.StepID))+',' and rs.JobID = js.JobID and rs.StepTypeID = 22 
--								left outer join JobControl..Jobs j on j.JobID = js.JobID 
--								where js.QueryTemplateID in (1132) and rs.StepTypeID = 22  and j.CategoryID = 47 and j.IsTemplate = 0 ) pp on pp.JobID = j.JobID
--			left outer join (select js.JobID, js.StepID QuerystepID, xs.StepID xformStepID, rs.StepID reporststepid  
--								, coalesce(js.Disabled,0) QueryStepDisabled,coalesce(xs.Disabled, 0) XformStepDisabled, coalesce(rs.Disabled, 0) ReportStepDisabled
--								from JobControl..JobSteps js
--								join jobcontrol..jobsteps xs on ','+xs.DependsOnStepIDs+',' like ','+ltrim(str(js.StepID))+',' and xs.JobID = js.JobID and xs.StepTypeID = 29
--								join jobcontrol..jobsteps rs on ','+rs.DependsOnStepIDs+',' like ','+ltrim(str(xs.StepID))+',' and rs.JobID = js.JobID and rs.StepTypeID = 22 
--								left outer join JobControl..Jobs j on j.JobID = js.JobID 
--								where js.QueryTemplateID in (1133) and rs.StepTypeID = 22  and j.CategoryID = 47 and j.IsTemplate = 0 ) p on p.JobID = j.JobID
--			left outer join (select js.JobID, js.StepID QuerystepID, xs.StepID xformStepID, rs.StepID reporststepid  
--								, coalesce(js.Disabled,0) QueryStepDisabled,coalesce(xs.Disabled, 0) XformStepDisabled, coalesce(rs.Disabled, 0) ReportStepDisabled
--								from JobControl..JobSteps js
--								join jobcontrol..jobsteps xs on ','+xs.DependsOnStepIDs+',' like ','+ltrim(str(js.StepID))+',' and xs.JobID = js.JobID and xs.StepTypeID = 29
--								join jobcontrol..jobsteps rs on ','+rs.DependsOnStepIDs+',' like ','+ltrim(str(xs.StepID))+',' and rs.JobID = js.JobID and rs.StepTypeID = 22 
--								left outer join JobControl..Jobs j on j.JobID = js.JobID  
--								where js.QueryTemplateID in (1134) and js.StepTypeID = 1124
--								and j.CategoryID = 47 and j.IsTemplate = 0 ) d on d.JobID = j.JobID
--		where j.CategoryID = 47 and j.IsTemplate = 0
--			and coalesce(j.deleted,0) = 0 
--		order by JobID
--		, states
--		, 5








END
