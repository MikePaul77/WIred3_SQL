/****** Object:  Procedure [dbo].[BuildFileNameOpts]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.BuildFileNameOpts @JobStartStamp varchar(50), @StartPath varchar(500), @StepID int, @FullRunOption varchar(50), @NormalRunOption varchar(50)
AS
BEGIN
	SET NOCOUNT ON;

		                    select distinct coalesce(case when coalesce(@StartPath,'') > '' then @StartPath else null end, js.StepFileNameAlgorithm) FullPath
				                    , fc.Code
				                    , case when fc.Code = '<YYYYMMDD>' then convert(varchar(50),convert(datetime,@JobStartStamp),112)
					                    when fc.Code = '<MMDDYYYY>' then replace(convert(varchar(10),convert(datetime,@JobStartStamp),101),'/','')
					                    when fc.Code = '<MMDDYYYY+1>' then replace(convert(varchar(10),dateadd(dd,1,convert(datetime,@JobStartStamp)),101),'/','')
					                    when fc.Code = '<MMDDYYYY+2>' then replace(convert(varchar(10),dateadd(dd,2,convert(datetime,@JobStartStamp)),101),'/','')
					                    when fc.Code = '<MMDDYYYY+3>' then replace(convert(varchar(10),dateadd(dd,3,convert(datetime,@JobStartStamp)),101),'/','')
					                    when fc.Code = '<MMDDYYYY+4>' then replace(convert(varchar(10),dateadd(dd,4,convert(datetime,@JobStartStamp)),101),'/','')
					                    when fc.Code = '<MM-DD-YYYY>' then replace(convert(varchar(10),convert(datetime,@JobStartStamp),101),'/','-')
					                    when fc.Code = '<RO>' then case when jp.ParamValue = 'FullLoad' then @FullRunOption else @NormalRunOption end
					                    when fc.Code = '<HH>' then left(convert(varchar(50),convert(datetime,@JobStartStamp),108),2)
					                    when fc.Code = '<MI>' then substring(convert(varchar(50),convert(datetime,@JobStartStamp),108),4,2)
					                    when fc.Code = '<YY>' then right(convert(varchar(50),year(convert(datetime,@JobStartStamp))),2)
					                    when fc.Code = '<YYYY>' then convert(varchar(50),year(convert(datetime,@JobStartStamp)))
					                    when fc.Code = '<TMY>' then case when jp.ParamName = 'IssueWeek' then left(datename(month,dateadd(wk,convert(int,left(jp.ParamValue,2)),'1/1/' + left(jp.ParamValue,4))),3) + left(jp.ParamValue,4)
                                                                            when jp.ParamName = 'IssueMonth' and left(jp.ParamValue,2) = '13' then 'YR' + right(jp.ParamValue,4)
													                        when jp.ParamName = 'IssueMonth' then left(datename(month,convert(datetime,left(jp.ParamValue,2)  + '/1/' +  right(jp.ParamValue,4))),3) + right(jp.ParamValue,4)
													                        --when jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod' then left(datename(month,convert(datetime,left(jp.ParamValue,2)  + '/1/' +  right(jp2.ParamValue,4))),3) + right(jp2.ParamValue,4)
													                        -- Replaced the line above with the line below.  Mark W.  2/21/2019
													                        when jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod' and jp.ParamValue between '01' and '12' then left(datename(month,convert(datetime,left(jp.ParamValue,2)  + '/1/' +  right(jp2.ParamValue,4))),3) + right(jp2.ParamValue,4)
													                        --Added the line below to accomodate Annual reports.  Mark W. 02/19/2020
 													                        when jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod' and jp.ParamValue='YR' then right(jp2.ParamValue,4)+'Annual'
													                    else left(datename(month,convert(datetime,@JobStartStamp)),3) + ltrim(str(year(convert(datetime,@JobStartStamp)))) end
					                    when fc.Code = '<JOBID>' then ltrim(str(j.JobID))
					                    when fc.Code = '<TBLN>' then coalesce(replace(c.FullName,' ',''),'XXXXXXXXXXXX')
					                    when fc.Code = '<TBLN12>' then coalesce(left(replace(c.FullName,' ',''),12),'XXXXXXXXXXXX')
					                    when fc.Code = '<PrcName>' then left(replace(NEWID(),'-',''),9)
					                    when fc.Code = '<CO>' then case when co.CompanyID > 0 then Support.FuncLib.CleanStringForFileName(ltrim(rtrim(co.CompanyName))) else '' end
					                    when fc.Code = '<TBD>' then left(replace(NEWID(),'-',''),9)

					                    when fc.Code = '<IDT>' then '--'
					                    when fc.Code = '<FY2>' then '--'

					                    when fc.Code = '<IfStCT||ST>' then case when S.Code = 'CT' then '' else S.Code end
					                    when fc.Code = '<IfStMA|BT|CR>' then case when S.Code = 'MA' then 'BT' else 'CR' end
					                    when fc.Code = '<IfStME|E|ST1>' then case when S.Code = 'ME' then 'E' else left(S.Code,1) end

					                    when fc.Code = '<BKTYP>' then 'TBD'

					                    when jp.ParamName = 'IssueWeek' and fc.Code = '<IW6>' then jp.ParamValue
								        when jp.ParamName = 'IssueWeek' and fc.Code = '<IW4>' then right(jp.ParamValue,4)
								        when jp.ParamName = 'IssueWeek' and fc.Code = '<IWY2>' then right(left(jp.ParamValue,4),2)
								        when jp.ParamName = 'IssueWeek' and fc.Code = '<IWY4>' then left(jp.ParamValue,4)
					                    when jp.ParamName = 'IssueMonth' and fc.Code = '<IM6>' then jp.ParamValue
								        when jp.ParamName = 'IssueMonth' and fc.Code = '<IM2>' then left(jp.ParamValue,2)
								        when jp.ParamName = 'IssueMonth' and fc.Code = '<IMY2>' then right(jp.ParamValue,2) -- Added 2/6/2019 - Mark W.
								        when jp.ParamName = 'IssueMonth' and fc.Code = '<IMY4>' then right(jp.ParamValue,4)
						                when jp.ParamName = 'CalYear' and fc.Code = '<CY>' then jp.ParamValue
							            when jp.ParamName = 'CalYear' and fc.Code = '<CY2>' then right(jp.ParamValue,2)
							            when jp.ParamName = 'CalYear' and fc.Code = '<IMY2>' then right(jp.ParamValue,2)
							            when jp.ParamName = 'CalYear' and fc.Code = '<IMY4>' then jp.ParamValue
						                when jp.ParamName = 'CalPeriod' and fc.Code = '<CP>' then jp.ParamValue
						                when jp.ParamName = 'CalPeriod' and fc.Code = '<CPM>' then case when isnumeric(jp.ParamValue) = 1 then datename(mm,convert(date,jp.ParamValue + '/1/2023'))
															                else jp.ParamValue end
						                when jp.ParamName = 'CalPeriod' and fc.Code = '<CPM3>' then case when isnumeric(jp.ParamValue) = 1 then left(datename(mm,convert(date,jp.ParamValue + '/1/2023')),3)
															                else jp.ParamValue end
							            when jp.ParamName = 'CalPeriod' and fc.Code = '<CP1>' then case when left(jp.ParamValue,1) = 'Q' then 'Q'
															                when jp.ParamValue = 'YR' then 'A'
															                else 'M' end
							            when jp.ParamName = 'CalPeriod' and fc.Code = '<IM2>' then left(jp.ParamValue,2)
					                    when jp.ParamName = 'StateID' and fc.Code = '<ST>' then S.Code
							            when jp.ParamName = 'StateID' and fc.Code = '<ST1>' then left(S.Code,1)
							            when jp.ParamName = 'StateID' and fc.Code = '<SFIP>' then S.StateFIPS
					                    when jp.ParamName = 'CountyID' and fc.Code = '<CC>' then C.Code
							            when jp.ParamName = 'CountyID' and fc.Code = '<CN>' then replace(c.FullName,' ','')
							            when jp.ParamName = 'CountyID' and fc.Code = '<CFIP>' then C.CountyFIPS
							            when jp.ParamName = 'RegistryID' and fc.Code = '<RN>' then replace(r.RegistryName,' ','')

					                    when qt.ID > 0 and fc.Code = '<TN>' then replace(qt.FullName,' ','')
										when qc.ID > 0 and fc.Code = '<CC>' then qc.Code
							            when qc.ID > 0 and fc.Code = '<CN>' then replace(qc.FullName,' ','')
							            when qc.ID > 0 and fc.Code = '<RN>' then replace(r.RegistryName,' ','')
							            when qc.ID > 0 and fc.Code = '<CFIP>' then qc.CountyFIPS
										when qs.Id > 0 and fc.Code = '<ST>' then case when qlsc.States > 1 then '' else qs.Code end
							            when qs.Id > 0 and fc.Code = '<ST1>' then case when qlsc.States > 1 then '' else left(qs.Code,1) end
							            when qs.Id > 0 and fc.Code = '<SFIP>' then case when qlsc.States > 1 then '' else qs.StateFIPS end

					                    when QueryRangeMinDate is not null and fc.Code = '<QRSY2>' then right(convert(varchar(50), Year(QueryRangeMinDate)),2)
							            when QueryRangeMinDate is not null and fc.Code = '<QRSY4>' then convert(varchar(50), Year(QueryRangeMinDate))
							            when QueryRangeMinDate is not null and fc.Code = '<QRSM2>' then Support.FuncLib.PadWithLeft(convert(varchar(50), month(QueryRangeMinDate)),2,'0')
							            when QueryRangeMinDate is not null and fc.Code = '<QRSM3>' then left(datename(month,QueryRangeMinDate),3)

						                when QueryRangeMaxDate is not null and fc.Code = '<QREY2>' then right(convert(varchar(50), Year(QueryRangeMaxDate)),2)
							            when QueryRangeMaxDate is not null and fc.Code = '<QREY4>' then convert(varchar(50), Year(QueryRangeMaxDate))
							            when QueryRangeMaxDate is not null and fc.Code = '<QREM2>' then Support.FuncLib.PadWithLeft(convert(varchar(50), month(QueryRangeMaxDate)),2,'0')
							            when QueryRangeMaxDate is not null and fc.Code = '<QREM3>' then left(datename(month,QueryRangeMaxDate),3)
					
					                    else null end ReplacementValue	

				                    , case when jp.ParamName = 'IssueWeek' then 10
						                    when jp.ParamName = 'IssueMonth' then 20
						                    when jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod' then 25
						                    when jp.ParamName = 'CalYear' then 30
						                    when jp.ParamName = 'CalPeriod' then 40
						                    when jp.ParamName = 'StateID' then 50
						                    when jp.ParamName = 'CountyID' then 60	else 99 end PriOrder	

                                    , case when fc.Code = '<BKTYP>' and tt.UsageGroupType = 1 then tt.QueryTemplateID else -1 end UsageQueryTemplateID

			                    from JobControl..JobSteps js
				                    join JobControl..Jobs j on j.JobID = js.JobID
				                    join JobControl..FileAlgorithmCodes fc on @StartPath like '%' + fc.code + '%'
									left outer join OrderControl..Customers cu on cu.CustID = j.CustID
									left outer join OrderControl..Companies co on co.CompanyID = cu.CompanyID
				                    left outer join JobControl..JobParameters jp on jp.JobID = j.JobID
				                    left outer join JobControl..JobParameters jp2 on jp2.JobID = j.JobID and jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod'
				                    left outer join Lookups..States s on ltrim(str(s.id)) = jp.ParamValue and jp.ParamName = 'StateID'
				                    left outer join Lookups..Registries r on ltrim(str(r.id)) = jp.ParamValue and jp.ParamName = 'RegistryID'
				                    left outer join Lookups..Counties c on ltrim(str(c.id)) = jp.ParamValue and jp.ParamName = 'CountyID'
				                    left outer join (select js.QueryCriteriaID, j.JobID, convert(date,MinValue) QueryRangeMinDate,convert(date, MaxValue) QueryRangeMaxDate
									                    , rowid = ROW_NUMBER() OVER (PARTITION BY j.JobID ORDER BY js.StepOrder, qr.ID)
								                    from JobCOntrol..JobSteps js
									                    join JobControl..Jobs j on js.JobID = j.JobID and coalesce(j.disabled,0) = 0
									                    join QueryEditor..QueryRanges qr on qr.QueryID = js.QueryCriteriaID and isdate(coalesce(MinValue,'1/1/1980')) = 1 
																								                        and isdate(coalesce(MaxValue,'1/1/1980')) = 1 
								                    where coalesce(js.Disabled,0) = 0
									                    and js.StepTypeID in (21,1124)
									                    and js.QueryCriteriaID > 0) qjs on qjs.JobID = j.JobID and qjs.rowid = 1

				                    left outer join (select js.QueryCriteriaID, j.JobID, ql.StateID, ql.CountyID, ql.TownID
															, rowid = ROW_NUMBER() OVER (PARTITION BY j.JobID ORDER BY js.StepOrder, ql.ID)
														from JobCOntrol..JobSteps js
															join JobControl..Jobs j on js.JobID = j.JobID and coalesce(j.disabled,0) = 0
															join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID 
														where coalesce(js.Disabled,0) = 0
															and js.StepTypeID in (21,1124)
															and js.QueryCriteriaID > 0) qls on qls.JobID = j.JobID 
				                    left outer join (select j.JobID, count(distinct ql.StateID) states
														from JobCOntrol..JobSteps js
															join JobControl..Jobs j on js.JobID = j.JobID and coalesce(j.disabled,0) = 0
															join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID 
														where coalesce(js.Disabled,0) = 0
															and js.StepTypeID in (21,1124)
															and js.QueryCriteriaID > 0
														group by j.JobID) qlsc on qlsc.JobID = j.JobID 
				                    left outer join Lookups..States qs on qs.id = qls.StateID
				                    left outer join Lookups..Counties qc on qc.id = qls.CountyID
				                    left outer join Lookups..Towns qt on qt.id = qls.TownID

									left outer join JobControl..JobSteps tjs on tjs.StepTypeID in (29,1) and tjs.JobID = j.JobID and js.DependsOnStepIDs like tjs.StepID
									left outer join JobControl..JobSteps tjs2 on tjs.StepTypeID = 1 and tjs2.StepTypeID in (29) and tjs.JobID = j.JobID and ' ,' + tjs.DependsOnStepIDs + ', ' like '%,' + ltrim(str(tjs2.StepID)) + ',%'
									left outer join JobControl..TransformationTemplates tt on tt.ID = coalesce(tjs.TransformationID, tjs2.TransformationID)

			                    where js.StepID = @StepID
END
