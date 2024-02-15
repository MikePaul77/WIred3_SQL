/****** Object:  Procedure [dbo].[PopulateJobStepFileName]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.PopulateJobStepFileName @FullPath varchar(2000), @JobStepID int 
AS
BEGIN
	SET NOCOUNT ON;

	declare @ResultPath varchar(2000)

	declare @FileName varchar(2000), @code varchar(50), @RepVal varchar(100) 

	declare @JobStartStamp datetime

	select @JobStartStamp = coalesce(max(jl.StartTime), getdate())
	from JobControl..JobLog jl
		join JobControl..JobSteps js on js.JobID = jl.JobID
	where js.StepID = @JobStepID

	--if CHARINDEX('<ST>', @FullPath)>0
	--	if 1=dbo.InLoop(@JobStepID)
	--		Begin
	--			-- This JobStepID is within a loop.  Get the state value from the BeginLoopStepResults table
	--			Declare @BeginStepID int, @CurJobID int, @CurStepOrder int, @dSQL nvarchar(1000), @CurState varchar(2);
	--			Select @CurJobID=JobID, @CurStepOrder=StepOrder from JobControl..JobSteps where StepID=@JobStepID;
	--			Select Top 1 @BeginStepID=StepID 
	--				from JobControl..JobSteps 
	--				where JobID=@CurJobID 
	--					and StepTypeID=1107
	--					and StepOrder<@CurStepOrder
	--				Order by StepOrder desc;
	--			set @dSQL= 'Select @CurState=s.code from JobControlWork..BeginLoopStepResults_J' + 
	--				convert(varchar, @CurJobID) + '_S' + convert(varchar, @BeginStepID) + ' b ' + 
	--				'join Lookups..States s on b.StateID=s.ID where b.ProcessFlag=1'
	--			exec sp_executesql @dSQL, N' @CurState varchar(2) Output', @CurState output;
	--			if isnull(@CurState,'')<>'' set @FullPath=replace(@FullPath,'<ST>',@CurState)
	--		End
	if 1=dbo.InLoop(@JobStepID) and @FullPath<>''
		Begin
			-- This JobStepID is within a loop.  Determine if this is a state or county loop.  
			Declare @BeginStepID int, @CurJobID int, @CurStepOrder int, @dSQL nvarchar(1000), @CurState varchar(2),
				@LoopTableName varchar(max);
		
			-- Get the current JobID and StepOrder
			Select @CurJobID=JobID, @CurStepOrder=StepOrder from JobControl..JobSteps where StepID=@JobStepID;

			-- Get the StepID of the Begin Loop
			Select Top 1 @BeginStepID=StepID 
				from JobControl..JobSteps 
				where JobID=@CurJobID 
					and StepTypeID=1107
					and StepOrder<@CurStepOrder
				Order by StepOrder desc;
			set @LoopTableName='JobControlWork..BeginLoopStepResults_J' + convert(varchar, @CurJobID) + '_S' + convert(varchar, @BeginStepID);
			IF OBJECT_ID(@LoopTableName, 'U') IS NOT NULL  -- Skip the rest of this code if the BeginLoop table doesn't exist
			Begin
				Declare @CountyName varchar(50), @CFIPS varchar(10), @CurCountyID int,
					@CurStateID int, @StateName varchar(50), @SFIPS varchar(10), @StateCode varchar(2)
					, @TownName varchar(50), @TownCode varchar(10), @CurTownID int

				-- Determine if the loop type is County or State
				if COL_LENGTH(@LoopTableName, 'TownID') is not null
					Begin
						-- Get the CountyCode
						set @dSQL= 'Select @CurTownID=TownID from ' + @LoopTableName + ' where ProcessFlag=1'
						exec sp_executesql @dSQL, N' @CurTownID int Output', @CurTownID output;
						Select @TownName=t.FullName, @CurStateID=t.StateID, @TownCode=t.Code, 
								@StateName=s.FullName, @SFIPS=s.StateFIPS, @StateCode=s.Code 
							from Lookups..Towns t
								Join Lookups..States s on s.id=t.StateID
							where t.ID=@CurTownID;
						if isnull(@TownCode,'')<>'' set @FullPath=replace(@FullPath,'<TC>',@TownCode)
						if isnull(@TownName,'')<>'' set @FullPath=replace(@FullPath,'<TN>',replace(@TownName,' ',''))
					End
				else if COL_LENGTH(@LoopTableName, 'CountyID') is not null
					Begin
						-- Get the CountyCode
						set @dSQL= 'Select @CurCountyID=CountyID from ' + @LoopTableName + ' where ProcessFlag=1'
						exec sp_executesql @dSQL, N' @CurCountyID int Output', @CurCountyID output;
						Select @CountyName=c.FullName, @CurStateID=c.StateID, @CFIPS=c.CountyFIPS, 
								@StateName=s.FullName, @SFIPS=s.StateFIPS, @StateCode=s.Code 
							from Lookups..Counties c
								Join Lookups..States s on s.id=c.StateID
							where c.ID=@CurCountyID;
						if isnull(@CFIPS,'')<>'' set @FullPath=replace(@FullPath,'<CFIP>',@CFIPS)
						if isnull(@CountyName,'')<>'' set @FullPath=replace(@FullPath,'<CN>',@CountyName)
					End
				else
					Begin
						set @dSQL= 'Select @CurStateID=StateID from ' + @LoopTableName + ' where ProcessFlag=1'
						exec sp_executesql @dSQL, N' @CurStateID int Output', @CurStateID output;
						Select @StateName=s.FullName, @SFIPS=s.StateFIPS, @StateCode=s.Code 
							from Lookups..States s
							where s.ID=@CurStateID;
					End
				if isnull(@CurState,'')<>'' set @FullPath=replace(@FullPath,'<ST>',@CurState)
				if isnull(@SFIPS,'')<>'' set @FullPath=replace(@FullPath,'<SFIP>',@SFIPS)
				if isnull(@StateCode,'')<>'' set @FullPath=replace(@FullPath,'<ST>',@StateCode)
			End
		End


	DECLARE curFileName CURSOR FOR

select fullPath, code, ReplacementValue
	from (
	select fullPath, code, ReplacementValue
		, PrioritySeq = ROW_NUMBER() OVER (PARTITION BY code ORDER BY PriOrder)
		 from (
		select coalesce(case when coalesce(@FullPath,'') > '' then @FullPath else null end, js.StepFileNameAlgorithm) FullPath
				, fc.Code
				, case when fc.Code = '<YYYYMMDD>' then convert(varchar(50),@JobStartStamp,112)
					when fc.Code = '<MMDDYYYY>' then replace(convert(varchar(10),@JobStartStamp,101),'/','')
					when fc.Code = '<MM-DD-YYYY>' then replace(convert(varchar(10),@JobStartStamp,101),'/','-')
					when fc.Code = '<RO>' then case when jp.ParamValue = 'FullLoad' then js.FullRunOption else js.NormalRunOption end
					when fc.Code = '<HH>' then left(convert(varchar(50),@JobStartStamp,108),2)
					when fc.Code = '<MI>' then substring(convert(varchar(50),@JobStartStamp,108),4,2)
					when fc.Code = '<TMY>' then case when jp.ParamName = 'IssueWeek' then left(datename(month,dateadd(wk,convert(int,left(jp.ParamValue,2)),'1/1/' + left(jp.ParamValue,4))),3) + left(jp.ParamValue,4)
													 when jp.ParamName = 'IssueMonth' then left(datename(month,convert(datetime,left(jp.ParamValue,2)  + '/1/' +  right(jp.ParamValue,4))),3) + right(jp.ParamValue,4)
													 --when jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod' then left(datename(month,convert(datetime,left(jp.ParamValue,2)  + '/1/' +  right(jp2.ParamValue,4))),3) + right(jp2.ParamValue,4)
													 -- Replaced the line above with the line below.  Mark W.  2/21/2019
													 when jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod' and jp.ParamValue between '01' and '12' then left(datename(month,convert(datetime,left(jp.ParamValue,2)  + '/1/' +  right(jp2.ParamValue,4))),3) + right(jp2.ParamValue,4)
													 --Added the line below to accomodate Annual reports.  Mark W. 02/19/2020
 													 when jp2.ParamName = 'CalYear' and jp.ParamName = 'CalPeriod' and jp.ParamValue='YR' then right(jp2.ParamValue,4)+'Annual'
													else left(datename(month,@JobStartStamp),3) + ltrim(str(year(@JobStartStamp))) end
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
								when fc.Code = '<IMY4>' then right(jp.ParamValue,4)
						else null end
					when jp.ParamName = 'CalYear' then
						case when fc.Code = '<CY>' then jp.ParamValue
							when fc.Code = '<CY2>' then right(jp.ParamValue,2)
							when fc.Code = '<IMY2>' then right(jp.ParamValue,2)
							when fc.Code = '<IMY4>' then jp.ParamValue
						else null end
					when jp.ParamName = 'CalPeriod' then
						case when fc.Code = '<CP>' then jp.ParamValue
							when fc.Code = '<CP1>' then case when left(jp.ParamValue,1) = 'Q' then 'Q'
															 when jp.ParamValue = 'YR' then 'A'
															 else 'M' end
							when fc.Code = '<IM2>' then left(jp.ParamValue,2)
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

					when QueryRangeMinDate is not null then
						case when fc.Code = '<QRSY2>' then right(convert(varchar(50), Year(QueryRangeMinDate)),2)
							 when fc.Code = '<QRSY4>' then convert(varchar(50), Year(QueryRangeMinDate))
							 when fc.Code = '<QRSM2>' then Support.FuncLib.PadWithLeft(convert(varchar(50), month(QueryRangeMinDate)),2,'0')
							 when fc.Code = '<QRSM3>' then left(datename(month,QueryRangeMinDate),3)
						else null end

					when QueryRangeMaxDate is not null then
						case when fc.Code = '<QREY2>' then right(convert(varchar(50), Year(QueryRangeMaxDate)),2)
							 when fc.Code = '<QREY4>' then convert(varchar(50), Year(QueryRangeMaxDate))
							 when fc.Code = '<QREM2>' then Support.FuncLib.PadWithLeft(convert(varchar(50), month(QueryRangeMaxDate)),2,'0')
							 when fc.Code = '<QREM3>' then left(datename(month,QueryRangeMaxDate),3)
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
				left outer join (select js.QueryCriteriaID, j.JobID, convert(date,MinValue) QueryRangeMinDate,convert(date, MaxValue) QueryRangeMaxDate
									, rowid = ROW_NUMBER() OVER (PARTITION BY j.JobID ORDER BY js.StepOrder, qr.ID)
								from JobCOntrol..JobSteps js
									join JobControl..Jobs j on js.JobID = j.JobID and coalesce(j.disabled,0) = 0
									join QueryEditor..QueryRanges qr on qr.QueryID = js.QueryCriteriaID and isdate(coalesce(MinValue,'1/1/1980')) = 1 
																								 and isdate(coalesce(MaxValue,'1/1/1980')) = 1 
								where coalesce(js.Disabled,0) = 0
									and js.StepTypeID in (21,1124)
									and js.QueryCriteriaID > 0) qjs on qjs.JobID = j.JobID and qjs.rowid = 1

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

	-- Added 5/15/2019 - Mark W.
	-- If this is an iterative report, we set the County or Town name here.
	Declare @SCT varchar(100)='', @ReturnID int=0;
	exec Iterative_SCT @JobStepID, 'N', @SCT = @SCT OUTPUT, @ReturnID = @ReturnID OUTPUT
	if isnull(@SCT, '')<>''
		Begin
			if left(@SCT,7)='County:' 
				Begin
					set @ResultPath = Replace(@ResultPath, '<CN>', substring(@SCT, 9, len(@SCT)-8));
					if CHARINDEX('<CFIP>',@ResultPath)>0
						Begin
							Declare @CountyFips varchar(10)
							select @CountyFips=CountyFIPS from lookups..counties where ID=@ReturnID;
							set @ResultPath = Replace(@ResultPath, '<CFIP>', rtrim(ltrim(isnull(@CountyFips,''))));
						End
				End
			if left(@SCT,5)='Town:' set @ResultPath = Replace(@ResultPath, '<TN>', substring(@SCT, 7, len(@SCT)-6));
		End


	if @ResultPath is null
		set @ResultPath = @FullPath


     DECLARE curFileName CURSOR FOR

		select distinct fullPath, code, ReplacementValue from (
			select coalesce(@ResultPath, js.StepFileNameAlgorithm) FullPath
					, fc.Code
					, case when fc.Code = '<TN>' and ql.TownID is not null then replace(t.FullName,' ','_')  -- Modified 2/27/19 to replace blank spaces with underscores.  Mark W.
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

-- Removed this line from the above case statement.  As of 11/6/2019, no jobsteps use '<RN>' in their StepFileNameAlgorithm.  Mark W.
--	when fc.Code = '<RN>' and ql.TownID is not null then replace(t.Registry,' ','')


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
