/****** Object:  Procedure [dbo].[PopulateJobStepFileName_05-15-2019]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[PopulateJobStepFileName] @FullPath varchar(2000), @JobStepID int 
AS
BEGIN
	SET NOCOUNT ON;

	declare @ResultPath varchar(2000)

	declare @FileName varchar(2000), @code varchar(50), @RepVal varchar(100) 

	DECLARE curFileName CURSOR FOR

select fullPath, code, ReplacementValue
	from (
	select fullPath, code, ReplacementValue
		, PrioritySeq = ROW_NUMBER() OVER (PARTITION BY code ORDER BY PriOrder)
		 from (
		select coalesce(case when coalesce(@FullPath,'') > '' then @FullPath else null end, js.StepFileNameAlgorithm) FullPath
				, fc.Code
				, case when fc.Code = '<YYYYMMDD>' then convert(varchar(50),getdate(),112)
					when fc.Code = '<MMDDYYYY>' then replace(convert(varchar(10),getdate(),101),'/','')
					when fc.Code = '<HH>' then left(convert(varchar(50),getdate(),108),2)
					when fc.Code = '<MI>' then substring(convert(varchar(50),getdate(),108),4,2)
					when fc.Code = '<TMY>' then case when jp.ParamName = 'IssueWeek' then left(datename(month,dateadd(wk,convert(int,left(jp.ParamValue,2)),'1/1/' + left(jp.ParamValue,4))),3) + left(jp.ParamValue,4)
													 when jp.ParamName = 'IssueMonth' then left(datename(month,convert(datetime,left(jp.ParamValue,2)  + '/1/' +  right(jp.ParamValue,4))),3) + right(jp.ParamValue,4)
													 --when jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod' then left(datename(month,convert(datetime,left(jp.ParamValue,2)  + '/1/' +  right(jp2.ParamValue,4))),3) + right(jp2.ParamValue,4)
													 -- Replaced the line above with the line below.  Mark W.  2/21/2019
													 when jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod' and jp.ParamValue between '01' and '12' then left(datename(month,convert(datetime,left(jp.ParamValue,2)  + '/1/' +  right(jp2.ParamValue,4))),3) + right(jp2.ParamValue,4)
													else left(datename(month,getdate()),3) + ltrim(str(year(getdate()))) end
					when fc.Code = '<JOBID>' then ltrim(str(j.JobID))
					when fc.Code = '<TBLN>' then coalesce(replace(c.FullName,' ',''),'XXXXXXXXXXXX')
					when fc.Code = '<TBLN12>' then coalesce(left(replace(c.FullName,' ',''),12),'XXXXXXXXXXXX')
					when fc.Code = '<PrcName>' then left(replace(NEWID(),'-',''),9)
					when fc.Code = '<TBD>' then left(replace(NEWID(),'-',''),9)

					when fc.Code = '<IDT>' then '--'
					when fc.Code = '<FY2>' then '--'

					when fc.Code = '<IfStCT||ST>' then case when S.Code = 'CT' then '' else S.Code end
					when fc.Code = '<IfStMA|BT|CR>' then case when S.Code = 'MA' then 'BT' else 'CR' end
					when fc.Code = '<IfStME|E|ST1>' then case when S.Code = 'ME' then 'E' else left(S.Code,1) end

					when jp.ParamName = 'IssueWeek' then
						case when fc.Code = '<IW6>' then jp.ParamValue
								when fc.Code = '<IW4>' then right(jp.ParamValue,4)
						else null end
					when jp.ParamName = 'IssueMonth' then
						case when fc.Code = '<IM6>' then jp.ParamValue
								when fc.Code = '<IM2>' then left(jp.ParamValue,2)
								when fc.Code = '<IMY2>' then right(jp.ParamValue,2) -- Added 2/6/2019 - Mark W.
						else null end
					when jp.ParamName = 'CalYear' then
						case when fc.Code = '<CY>' then jp.ParamValue
								when fc.Code = '<CY2>' then right(jp.ParamValue,2)
						else null end
					when jp.ParamName = 'CalPeriod' then
						case when fc.Code = '<CP>' then jp.ParamValue
						else null end
					when jp.ParamName = 'StateID' then
						case when fc.Code = '<ST>' then S.Code
							when fc.Code = '<ST1>' then left(S.Code,1)
							when fc.Code = '<SFIP>' then S.StateFIPS
						else null end
					when jp.ParamName = 'CountyID' then
						case when fc.Code = '<CC>' then C.Code
							when fc.Code = '<CN>' then replace(c.FullName,' ','')
							when fc.Code = '<CFIP>' then C.CountyFIPS
						else null end
					
					else null end ReplacementValue	

				, case when jp.ParamName = 'IssueWeek' then 10
						when jp.ParamName = 'IssueMonth' then 20
						when jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod' then 25
						when jp.ParamName = 'CalYear' then 30
						when jp.ParamName = 'CalPeriod' then 40
						when jp.ParamName = 'StateID' then 50
						when jp.ParamName = 'CountyID' then 60	else 99 end PriOrder	

			from JobControl..JobSteps js
				join JobControl..Jobs j on j.JobID = js.JobID
				join JobControl..FileAlgorithmCodes fc on js.StepFileNameAlgorithm like '%' + fc.code + '%'
				left outer join JobControl..JobParameters jp on jp.JobID = j.JobID
				left outer join JobControl..JobParameters jp2 on jp2.JobID = j.JobID and jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod'
				left outer join Lookups..States s on ltrim(str(s.id)) = jp.ParamValue and jp.ParamName = 'StateID'
				left outer join Lookups..Counties c on ltrim(str(c.id)) = jp.ParamValue and jp.ParamName = 'CountyID'
			where js.StepID = @JobStepID
		) x
		where ReplacementValue is not null
	) y
	where PrioritySeq = 1

	OPEN curFileName

	FETCH NEXT FROM curFileName into @FileName, @code , @RepVal
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN

	if @ResultPath is null
		set @ResultPath = @FileName

		set @ResultPath = replace(@ResultPath, @code , @RepVal)

		FETCH NEXT FROM curFileName into @FileName, @code , @RepVal
	END
	CLOSE curFileName
	DEALLOCATE curFileName


     DECLARE curFileName CURSOR FOR

		select distinct fullPath, code, ReplacementValue from (
			select coalesce(@ResultPath, js.StepFileNameAlgorithm) FullPath
					, fc.Code
					, case when fc.Code = '<TN>' and ql.TownID is not null then replace(t.FullName,' ','_')  -- Modified 2/27/19 to replace blank spaces with underscores.  Mark W.
							when fc.Code = '<RN>' and ql.TownID is not null then replace(t.Registry,' ','')
							when fc.Code = '<TC>' and ql.TownID is not null then t.Code
							when fc.Code = '<ST>' and ql.StateID is not null then S.Code
							when fc.Code = '<ST1>' and ql.StateID is not null then left(S.Code,1)
							when fc.Code = '<SFIP>' and ql.StateID is not null then S.StateFIPS
							when fc.Code = '<CC>' and ql.CountyID is not null then C.Code
							when fc.Code = '<CFIP>' and ql.CountyID is not null then C.CountyFIPS
							when fc.Code = '<CN>' and ql.CountyID is not null then replace(c.FullName,' ','')
							when fc.Code = '<IfProp|pr|tx>' then case when DQ.TemplateID = 4 then 'pr' else 'tx' end

						else null end ReplacementValue
							
				from JobControl..JobSteps js
					join JobControl..Jobs j on j.JobID = js.JobID
					join JobControl..FileAlgorithmCodes fc on js.StepFileNameAlgorithm like '%' + fc.code + '%'
					left outer join JobControl..JobSteps DQjs on DQjs.StepID = dbo.GetDependsQueryJobStepID(js.StepID)
					left outer join QueryEditor..Queries DQ on DQ.ID = DQjs.QueryCriteriaID
					left outer join QueryEditor..QueryLocations ql on ql.QueryID = DQjs.QueryCriteriaID
					left outer join Lookups..towns t on ltrim(str(t.id)) = ql.TownID
					left outer join Lookups..States s on ltrim(str(s.id)) = ql.StateID
					left outer join Lookups..Counties c on ltrim(str(c.id)) = ql.CountyID
				where js.StepID = @JobStepID
			) x
			where ReplacementValue is not null

     OPEN curFileName

     FETCH NEXT FROM curFileName into @FileName, @code , @RepVal
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
		if @ResultPath is null
			set @ResultPath = @FileName

			set @ResultPath = replace(@ResultPath, @code , @RepVal)
          FETCH NEXT FROM curFileName into @FileName, @code , @RepVal
     END
     CLOSE curFileName
     DEALLOCATE curFileName

	Select coalesce(@ResultPath, @FullPath) ResultPath
END
