/****** Object:  Procedure [dbo].[CheckProbateSync]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE CheckProbateSync
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	select x.*
	, case when x.CountiesP = x.CountiesPP and x.CountiesP = x.CountiesD then 1 else 0 END InSync
		from 
			(select j.JobName, j.JobID, coalesce(j.disabled,0) disabled
					, coalesce(substring((select ', ' + c.FullName +',' +s.code + ' ('+s.StateFIPS + c.CountyFIPS + ')'
							from QueryEditor..QueryLocations ql
								join Lookups..Counties c on c.id = ql.CountyID 
								join Lookups..States s on s.Id = c.StateID
							where ql.QueryID in (qsp.QueryCriteriaID) and ql.CountyID > 0
							order by c.FullName
							for XML path('') 
						),2,4000), '-NONE-') CountiesP
						, coalesce(substring((select ', ' + c.FullName +',' +s.code + ' ('+s.StateFIPS + c.CountyFIPS + ')'
							from QueryEditor..QueryLocations ql
								join Lookups..Counties c on c.id = ql.CountyID 
								join Lookups..States s on s.Id = c.StateID
							where ql.QueryID in (qspp.QueryCriteriaID) and ql.CountyID > 0
							order by c.FullName
							for XML path('') 
						),2,4000), '-NONE-') CountiesPP
					, coalesce(substring((select ', ' + c.FullName +',' +s.code + ' ('+s.StateFIPS + c.CountyFIPS + ')'
							from QueryEditor..QueryLocations ql
								join Lookups..Counties c on c.id = ql.CountyID 
								join Lookups..States s on s.Id = c.StateID
							where ql.QueryID in (qsd.QueryCriteriaID) and ql.CountyID > 0
							order by c.FullName
							for XML path('') 
						),2,4000), '-NONE-') CountiesD

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


					where j.CategoryID = 47 and j.IsTemplate = 0 and j.jobid != 6669 
					and coalesce(j.deleted,0) = 0 ) x
END
