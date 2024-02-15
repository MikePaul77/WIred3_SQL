/****** Object:  ScalarFunction [dbo].[GenAutoJobName]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.GenAutoJobName 
(
	@JobID int
)
RETURNS varchar(500)
AS
BEGIN
	DECLARE @Result varchar(500)

	--select j.JobID
		
	--	, j.custID
	--	--, coalesce(co.CompanyName,c.groupname, ltrim(c.firstname + ' ' + c.LastName), 'New Job') + ' '
	--	--			+ coalesce(j.JobNameAddition + ' ','')
	--	--			+ case when j.CategoryID = 47 then 'Probate: ' else '' end + coalesce(DataTypesList,'') + ' '
	--	--			+ case when TownsCount > 4 then ltrim(str(TownsCount)) +  ' Towns over ' + case when StatesCount > 3 then  ltrim(str(StatesCount)) + ' States' else coalesce(StatesList,'') end
	--	--					when TownsCount > 0 then 'Towns: ' + coalesce(TownsList,'')
	--	--					when CountiesCount > 4 then ltrim(str(CountiesCount)) +  ' Counties over ' + case when StatesCount > 3 then  ltrim(str(StatesCount)) + ' States' else coalesce(StatesList,'') end
	--	--					when CountiesCount > 0 then 'Counties: ' + coalesce(CountiesList,'')
	--	--					when StatesCount > 6 then ltrim(str(StatesCount)) +  ' States' 
	--	--					else coalesce(StatesList,'') + ' ' end
	--	, case when co.CompanyName > '' then co.CompanyName
	--			when c.groupname > '' then c.groupname
	--			when ltrim(c.firstname + ' ' + c.LastName) > '' then ltrim(c.firstname + ' ' + c.LastName)
	--			else 'Unspecified' end + ' | '
	--				+ ltrim(coalesce(j.JobNameAddition,'') + ' ')
	--				+ case when j.CategoryID = 47 then 'Probate: ' else '' end + coalesce(DataTypesList,'') + ' | '
	--				+ case when StatesCount > 6 then ltrim(str(StatesCount)) +  ' States' 
	--						else coalesce(StatesList,'') + ' ' end

	--	, j.JobName

	--	---, case when CategoryID = 47 then 

	--	--, coalesce(substring((select ', ' + x.code 
	--	--	from (select distinct s.code 
	--	--		from JobControl..JobSteps js
	--	--			join QueryEditor..QueryLocations ql on ql.queryID = js.QueryCriteriaID and ql.stateID > 0
	--	--			join Lookups..States s on s.Id = ql.StateID
	--	--		where js.jobID = j.JobID and js.StepTypeID = 1124
	--	--		)x 
	--	--	order by x.code
	--	--	for XML path('') 
	--	--),2,2000), '-NONE-') States
	--	, dt2.DataTypesCount, dt2.DataTypesList
	--	, s3.StatesCount, s3.StatesList
	--	, c3.CountiesCount, c3.CountiesList
	--	, t3.TownsCount, t3.TownsList

	--	, j.JobNameAddition

select @Result = case when j.ProductDefault = 1 then 
						case when j.CategoryID = 47 then 'Probate' 
							else case when dtd.ShortName = 'FA' then 'National' else dtd.ShortName end + ' | ' + dtd.ReqDataType + ' | ' + coalesce(dfl.CommonName,'') end
                    else
                        case when co.CompanyName > '' then co.CompanyName
                        when c.groupname > '' then c.groupname
                        when ltrim(c.firstname + ' ' + c.LastName) > '' then ltrim(c.firstname + ' ' + c.LastName)
                        when ltrim(c.EMail) > '' then ltrim(c.email)
                        else 'Unspecified' end + ' | '
                            + case when j.CategoryID = 47 then 'Probate: ' + coalesce(DataTypesList,'')
                                    when j.CategoryID = 24 then 'NP Galley: ' + coalesce(DataTypesList,'')
                                    when j.CategoryID in (45,46) then 'MTD'
                                else coalesce(DataTypesList,'Other') end 
                            + case when j.JobNameAddition > '' then ' | ' + j.JobNameAddition else '' end
                            + ' | ' + case when StatesCount > 6 then ltrim(str(StatesCount)) +  ' States' 
                                    else coalesce(StatesList,'') + ' ' end
                    end
	from JobControl..Jobs j
		left outer join OrderControl..Customers c on c.CustID = j.CustID
		left outer join OrderControl..Companies co on co.CompanyID = c.CompanyID
		left outer join (select distinct js.JobID, qs.*, qty.ReqDataType
									from JobControl..JobSteps js
										join JobControl..Jobs j on j.JobID = js.JobID and j.CategoryID <> 47
										join JobControl..QueryTemplates qt on qt.Id = js.QueryTemplateID and js.QueryTemplateID not in (1108,1060)
										left outer join JobControl..QueryTypes qty on qty.QueryTypeID = qt.QueryTypeID
										left outer join JobControl..QuerySources qs on qs.ID = qty.QuerySourceID
									where js.StepTypeID = 1124 and coalesce(js.disabled,0) = 0
						) dtd on dtd.JobID = j.jobID
		left outer join (select distinct js.JobID, js.FileLayoutID, coalesce(fl.CommonName,'Standard') CommonName
									from JobControl..JobSteps js
										left outer join JobControl..FileLayouts fl on fl.Id = js.FileLayoutID
									where js.StepTypeID = 29 and coalesce(js.disabled,0) = 0 
						) dfl on dfl.JobID = dtd.jobID
		left outer join (select distinct JobID, STRING_AGG(dt.DataType,' / ') DataTypesList, count(*) DataTypesCount
							from (select distinct js.JobID, case when j.CategoryID = 47 then qty.ShortDataType
																	else ltrim(coalesce(qs.publicshortname,qs.ShortName) + ' ' + qty.ReqDataType) end DataType
									from JobControl..JobSteps js
										join JobControl..Jobs j on j.JobID = js.JobID
										join JobControl..QueryTemplates qt on qt.Id = js.QueryTemplateID and js.QueryTemplateID not in (1108,1060)
										left outer join JobControl..QueryTypes qty on qty.QueryTypeID = qt.QueryTypeID
										left outer join JobControl..QuerySources qs on qs.ID = qty.QuerySourceID
									where js.StepTypeID = 1124 and coalesce(js.disabled,0) = 0
								) dt
							group by JobID ) dt2 on dt2.JobID = j.jobID
		left outer join (select distinct JobID, STRING_AGG(s2.code,', ') StatesList, count(*) StatesCount
							from (select distinct JobID, s.code
									from JobControl..JobSteps js
										join QueryEditor..QueryLocations ql on ql.queryID = js.QueryCriteriaID and ql.stateID > 0
										join Lookups..States s on s.Id = ql.StateID
									where js.StepTypeID = 1124 and coalesce(js.disabled,0) = 0
								) s2
							group by JobID ) s3 on s3.JobID = j.jobID
		left outer join (select distinct JobID, STRING_AGG(c2.CountyText,', ') CountiesList, count(*) CountiesCount
							from (select distinct JobID, c.FullName + ' ' + s.code + ' ' + s.StateFIPS + c.CountyFIPS CountyText
									from JobControl..JobSteps js
										join QueryEditor..QueryLocations ql on ql.queryID = js.QueryCriteriaID and ql.CountyID > 0
										join Lookups..Counties c on c.id = ql.CountyID 
										join Lookups..States s on s.Id = c.StateID
									where js.StepTypeID = 1124 and coalesce(js.disabled,0) = 0
								) c2
							group by JobID ) c3 on c3.JobID = j.jobID
		left outer join (select distinct JobID, STRING_AGG(t2.TownText,', ') TownsList, count(*) TownsCount
							from (select distinct JobID, t.FullName + ' ' + s.code TownText
									from JobControl..JobSteps js
										join QueryEditor..QueryLocations ql on ql.queryID = js.QueryCriteriaID and ql.TownID > 0
										join Lookups..Towns t on t.id = ql.TownID
										join Lookups..States s on s.Id = t.StateID
									where js.StepTypeID = 1124 and coalesce(js.disabled,0) = 0
										and js.jobID not in (6574) -- To Many
								) t2
							group by JobID ) t3 on t3.JobID = j.jobID



	where j.JobID = @JobID


	RETURN @Result

END
