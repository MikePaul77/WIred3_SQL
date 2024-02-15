/****** Object:  Procedure [dbo].[JC_QueryStepV2_Init]    Committed by VersionSQL https://www.versionsql.com ******/

Create PROCEDURE dbo.JC_QueryStepV2_Init @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

	Begin Try
	
		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

		declare @SQLCmd Varchar(max),
			@SQLCmdLevel2 Varchar(max),
			@SQLCmdCount Varchar(max),
			@SQLCmdLog Varchar(max),
			@SQLDropCmd Varchar(max),
			@JobID int,
			@PreBuildQuery int,
			@StepOrder int,
			@NextStepID int,
			@DependsOnStepIDs varchar(500)='',
			@QuerySourceStepID int,
			@QuerySourceStepName varchar(500),
			@StartMark int, 
			@EndMark int,
			@QuerySourceID int,
			@JobParamValue varchar(10)

		exec JobControl..UpdateQueryParams @JobStepID, 0

		select @JobID = js.JobID
				, @StepOrder=js.StepOrder
				, @SQLCmd = coalesce(q.SQLCmd, q2.SQLCmd)
				, @SQLCmdLevel2 = coalesce(q.Level2Conds, '')
				, @QuerySourceStepID = js.QuerySourceStepID
				, @QuerySourceStepName = ajst.StepName + 'StepResults_J' + ltrim(str(ajs.JobID)) + '_S' + ltrim(str(ajs.StepID)) 
				, @PreBuildQuery = isnull(js.PreBuildQuery,0)
				, @DependsOnStepIDs = js.DependsOnStepIDs
				, @QuerySourceID = qty.QuerySourceID
				, @JobParamValue = jpw.ParamValue
			from JobControl..JobSteps js 
				left outer join QueryEditor..Queries q on js.QueryCriteriaID = q.ID
				left outer join JobControl..JobSteps ajs on ajs.StepID = js.QuerySourceStepID
				left outer join QueryEditor..Queries q2 on ajs.QueryCriteriaID = q2.ID
				join JobControl..Jobs j on j.JobID=js.JobID
				left outer join JobStepTypes ajst on ajst.StepTypeID = ajs.StepTypeID
				left outer Join JobControl..QueryTemplates qtp on qtp.Id = q.TemplateID
				left outer join JobControl..QueryTypes qty on qty.QueryTypeID = qtp.QueryTypeID
				left outer join JobControl..JobParameters jpW on jpW.JobID = js.JobID
			where js.StepID = @JobStepID;


		if @SQLCmd is null
		begin
			set @SQLCmd = '
			  select *   
				--#INTO TABLE#   
				   --#FromClauseStart#  
				from TWG_PropertyData_Rep..TBD   
				   --#FromClauseEnd#    
				
				Where 1=1  
					and (  (  
					--#LocationClauseStart1#   
					TBD
					--#LocationClauseEnd1#
					)   )     '
		end

print 'Qv2A'

		-- If no location in query the and is missing
		--declare @QSeg varchar(100)
		--set @QSeg = SUBSTRING(@SqlCmd, charindex('1=1',@SQLCmd), CHARINDEX('--#LocationClauseStart1#',@SQLCmd) - charindex('1=1',@SQLCmd))
		--if charindex('and',@QSeg) = 0
		--	set @SQLCmd = replace(@SQLCmd,'1=1', '1=1 and ')

print 'Qv2B'

		-- Added 5/14/2019 - Mark W.
		-- If the next step is a Begin Loop step, Drop the BeginLoop table if it still exists from a previous run
		Select @NextStepID=StepID from JobControl..JobSteps where JobID=@JobID and StepOrder=@StepOrder+1 and StepTypeID = 1107
		if @NextStepID is not null
			Begin
				Declare @TargetFile varchar(100);
				set @TargetFile = 'JobControlWork..BeginLoopStepResults_J' + convert(varchar, @JobID) + '_S' + convert(varchar, @NextStepID);
				IF OBJECT_ID(@TargetFile, 'U') IS NOT NULL
					Exec('Drop Table ' + @TargetFile);
			End

print 'Qv2C'

		--Added 7/5/2018 - Mark W.
		if @SQLCmd is null
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 3,'*** QueryEditor..Queries.SQLCmd is null','SP JobControl..JC_QueryStep'

print 'Qv2D'
		
		if @PreBuildQuery=1
			Begin
				Declare @NewFileName varchar(max)
				Print 'JC_QueryStep: ### STARTING PreBuildQuery ###';
				exec PreBuildQuery @JobStepID, @SQLCMD, @NewFileName OUTPUT;
				Print 'JC_QueryStep: @NewFileName=' + @NewFileName
				Print 'JC_QueryStep: ### PreBuildQuery Complete ###';
				set @StartMark = CHARINDEX('#FromClauseStart#',@SQLCmd) + len('#FromClauseStart#') + 1
				set @EndMark = CHARINDEX('--#FromClauseEnd#',@SQLCmd) - 1
				Print 'JC_QueryStep: ### End Section after From Clause ###'
				Print substring(@SQLCmd,@EndMark,len(@SQLCmd))	
				Print 'JC_QueryStep: #####################################'
				if @StartMark > 0 and @EndMark > 0
					set @SQLCmd = left(@SQLCmd, @StartMark) + 'from ' + @NewFileName + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))				

				--Set @SQLCmd = substring(@SQLCmd, 1, CHARINDEX('from ', @SQLCmd) + 4) + 
				--		@NewFileName + ' ' +
				--		substring(@SQLCmd, CHARINDEX('where ', @SQLCmd)-1, 5000);
				Print 'JC_QueryStep: --------------------------------------------------------------'
				Print 'JC_QueryStep: @SQLCmd value after PreBuildQuery: ' + @SQLCmd
				Print 'JC_QueryStep: --------------------------------------------------------------'
			End

print 'Qv2E'

		declare @StepTable varchar(100);
		set @StepTable = 'JobControlWork..QueryV2StepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID));

		declare @LogInfo varchar(200)
		set @LogInfo = 'SP Result Location:' + @StepTable;
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;

		set @SQLCmd = replace(@SQLCmd,'--#INTO TABLE#', 'INTO ' + @StepTable);
		print 'JC_QueryStep: @SQLcmd: ' + iif(@SQLCmd is null, 'NULL', @SQLCmd);
		set @SQLDropCmd = 'IF OBJECT_ID(''' + @StepTable + ''', ''U'') IS not NULL drop TABLE ' + @StepTable + ' ';
	
		print 'JC_QueryStep: @SQLDropCmd: ' + @SQLDropCmd;
		exec(@SQLDropCmd);

print 'Qv2F'

		-- Added this section 02-11-2020 - Mark W.  If the query depends on a Begin Loop step, it is running inside a loop.
		-- This code will figure out if the loop is based on State, County or Town and replace the expected query location
		-- with a new location value.
		if isnull(@DependsOnStepIDs,'')<>'' and CHARINDEX(',', @DependsOnStepIDs)=0
			Begin
				Declare @SCT varchar(10)
				Select @SCT=(	CASE WHEN BeginLoopType=1 THEN 'State'
								     WHEN BeginLoopType=2 THEN 'County'
								     ELSE 'Town' END)
					from JobControl..JobSteps 
					where StepID=convert(int, @DependsOnStepIDs)
						and StepTypeID=1107;
				Print 'JC_QueryStep: @SCT: ' + @SCT;
				if isnull(@SCT,'')<>''
					Begin
						Declare @LoopTable varchar(100), @Q1 nvarchar(max), @SCTval int;
						set @LoopTable = 'JobControlWork..BeginLoopStepResults_J' + ltrim(str(@JobID)) + '_S' + @DependsOnStepIDs;
						if OBJECT_ID(@LoopTable, 'U') is not null
							Begin
								set @Q1='Select @SCTval=' + @SCT + 'ID from ' + @LoopTable + ' where ProcessFlag=1'
								Execute sp_executesql @Q1, N'@SCTval int OUTPUT', @SCTval = @SCTval output;
							End
						if isnull(@SCTval,0)<>0
							Begin
								Print 'JC_QueryStep: @SQLCmd before location update: ' + char(10) + @SQLCmd
								set @SQLCmd = JobControl.dbo.QueryLocationCleanUp(@SQLCmd)
								Print char(10) +'JC_QueryStep: @SQLCmd after QueryLocationCleanUp: ' + char(10) + @SQLCmd

								--set @StartMark = CHARINDEX('#LocationClauseStart1#',@SQLCmd) + len('#LocationClauseStart1#') + 1
								--set @EndMark = CHARINDEX('#LocationClauseEnd1#',@SQLCmd) - 3
								--if @StartMark > 0 and @EndMark > 0
								--	set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + '[' + @SCT + 'ID]=' + convert(varchar, @SCTval) + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))

								-- MP commented out above 4 lines to add loop below to cancel out Location clauses 2-?

								declare @seq int = 1
								begin
									while CHARINDEX('#LocationClauseStart' + ltrim(str(@seq)) + '#',@SQLCmd) > 0
									begin
										set @StartMark = CHARINDEX('#LocationClauseStart' + ltrim(str(@seq)) + '#',@SQLCmd) + len('#LocationClauseStart' + ltrim(str(@seq)) + '#') + 1
										set @EndMark = CHARINDEX('#LocationClauseEnd' + ltrim(str(@seq)) + '#',@SQLCmd) - 3

										declare @UseField varchar(20) = @SCT + 'ID'
										declare @UseVal varchar(20) = convert(varchar, @SCTval)
										if @QuerySourceID = 2 and @SCT = 'State'
										begin
											set @UseField = 'State'
											select @UseVal = '''' + Code + '''' from Lookups..States where ID = @SCTval
										end
										if @QuerySourceID = 2 and @SCT = 'County'
										Begin
											set @UseField = 'CountyFIPS'
											select @UseVal = '''' + s.StateFIPS + CountyFIPS + ''''
													from Lookups..Counties c
														join Lookups..States s on s.ID = c.StateID
													 where c.ID = @SCTval
										end

										if @seq = 1
											set @SQLCmd = left(@SQLCmd, @StartMark) + char(10) + ' ' + '[' + @UseField + '] = ' + @UseVal + ' ' + char(10) + substring(@SQLCmd,@EndMark,len(@SQLCmd))
										else
											set @SQLCmd = left(@SQLCmd, @StartMark) + char(10) + ' 1=2 ' + char(10) + substring(@SQLCmd,@EndMark,len(@SQLCmd))

										set @seq = @seq + 1
									end
								end

								Print char(10) +'JC_QueryStep: @SQLCmd after location update: ' + char(10) + @SQLCmd
							End
					End
			End

print 'Qv2G'

		if isnull(@QuerySourceStepID,0)>0
			Begin
				Print Char(10)+Char(10)+'JC_QueryStep: ### Alternate Source ###'
				Print 'JC_QueryStep: '+ @SQLCmd;
				Declare @SourceVal varchar(100)=' from JobControlWork..' + @QuerySourceStepName + ' '
				set @StartMark = CHARINDEX('#FromClauseStart#',@SQLCmd) + len('#FromClauseStart#') + 1
				set @EndMark = CHARINDEX('#FromClauseEnd#',@SQLCmd) - 4 --3
				if @StartMark > 0 and @EndMark > 0
					set @SQLCmd = left(@SQLCmd, @StartMark) + Char(10) + @SourceVal + ' ' + Char(10) + substring(@SQLCmd,@EndMark,len(@SQLCmd))
				Print Char(10)+Char(10)+'JC_QueryStep: @SQL variable after Alternate Source: ' + char(10) + @SQLCmd				
			End

		-- this is for a special situation where the scalar funtion below in the Where clause take 4 hours ?????
		-- But replaceing the function with the calulated values takes 30 seconds
		if @SQLCmd like '%JobcontrolCust.RogersGray.BackDataMonth%'
		Begin

			set @SQLCmd = JobcontrolCust.RogersGray.FunctionReplace(@SQLCmd)

		End

print 'Qv2H'

		print 'JC_QueryStep: exec JobControl.dbo.JobStepLogInsert ' + convert(varchar(10), @JobStepID) + ', 1, ' + @SQLCmd + ', ''QuerySQLCMD''';
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @SQLCmd, 'QuerySQLCMD'

		print 'JC_QueryStep: Final @SQLcmd: ' + @SQLCmd;
		--exec(@SQLCmd);
		declare @ActualSQLCmd varchar(max)
		set @ActualSQLCmd = @SQLCmd + char(10) + 'OPTION (MAXDOP 1)'
		exec(@ActualSQLCmd);
		--Inserting a blank Log Info and count the no of entries in thr StepTable
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1,'','StepRecordCount'

print 'Qv2I'
		if @JobParamValue <> 'FullLoad'
			exec JobControl.dbo.AdjustQueryData @JobStepID

print 'Qv2J'

		if @SQLCmdLevel2 > ''
		begin
			print 'JC_QueryStep: SQL CondsLevel2'
			declare @SQLLevel2 Varchar(max)
			set @SQLLevel2 = 'delete ' + @StepTable + ' where case when 1=1 ' +  @SQLCmdLevel2 + ' then 1 else 0 end = 0'
			print @SQLLevel2
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @SQLLevel2, 'QuerySQLCMDLevel2'
			exec(@SQLLevel2);
		end

print 'Qv2K'

		------------------------------------------------------------------------------------------------------------
		-- Modified this section 12-16-2018 - Mark W.
			--set @SQLCmdCount = 'Select Count(*) From ' + @StepTable
			--exec JobControl.dbo.JobStepLogInfoUpdate @JobStepID, 'StepRecordCount', @SQLCmdCount 
			--exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
			Declare @RowCount int;
			--Exec JobControlWork.dbo.GetTableRowCount @StepTable, @RowCount output;
			Exec GetTableRowCount @StepTable, @RowCount output;
			Declare @cRowCount varchar(20) ;
			Print 'StepTable: ' + @StepTable;
			Print 'RowCount: ' + convert(varchar, @RowCount);
			set @cRowCount = convert(varchar, @RowCount);
			exec JobControl.dbo.JobStepLogInfoUpdate @JobStepID, 'StepRecordCount', @cRowCount
			select @cRowCount=value from JobControl..Settings where Property='Maximum Query Results'
			if @RowCount>=convert(int, @cRowCount)
				-- More records were returned than anticipated.  Abort this job
				Begin
					--Insert into JobStepLog(JobId, JobStepID, LogInformation, LogInfoType, LogInfoSource, LogStamp)
					--	values(@JobID, @JobStepID, 'Job Cancelled due to query exceeding maximum number of ' 
					--	+ convert(varchar, @cRowCount) + ' records',1,'JobControl.dbo.JC_QueryStep', getdate());

						declare @LogInfoRowCount varchar(50) = 'Job Cancelled due to query exceeding maximum number of ' 
						+ convert(varchar, @cRowCount) + ' records' 

						exec JobControl.dbo.JobStepLogInsert @jobstepID, 1,@LogInfoRowCount, 'JobControl.dbo.JC_QueryStep' 

					Print 'JC_QueryStep: exec JobControl.dbo.JobControlStepUpdate ' + convert(varchar, @JobStepID) + ', ''Fail''';
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
				End
			else
				Begin
					Print 'JC_QueryStep: exec JobControl.dbo.JobControlStepUpdate ' + convert(varchar, @JobStepID) + ', ''Complete''';
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
				End
		-----------------------------------------------------------------------------------------------------------

	end Try

	begin catch

		DECLARE @ErrorMessage NVARCHAR(4000);  
		DECLARE @ErrorSeverity INT;  
		DECLARE @ErrorState INT;  
		DECLARE @ErrorNumber INT;  
		DECLARE @ErrorLine INT;  

		SELECT   
			@ErrorMessage = ERROR_MESSAGE(),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorNumber = ERROR_NUMBER(),  
			@ErrorLine = ERROR_LINE(),  
			@ErrorState = ERROR_STATE();  

		declare @logEntry varchar(500)

		set @logEntry ='Error Number ' + cast(@ErrorNumber AS nvarchar(50))+ ', ' +
                         'Error Line '   + cast(@ErrorLine AS nvarchar(50)) + ', ' +
                         'Error Message : ''' + @ErrorMessage + ''''

		print @logEntry

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, @LogSourceName

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

		RAISERROR (@ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  

	end catch


END
