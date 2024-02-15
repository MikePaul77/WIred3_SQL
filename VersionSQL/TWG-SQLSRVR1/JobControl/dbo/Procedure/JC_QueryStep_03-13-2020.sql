/****** Object:  Procedure [dbo].[JC_QueryStep_03-13-2020]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_QueryStep_03-13-2020 @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

	Begin Try
	
		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

		declare @SQLCmd Varchar(max),
			@SQLCmdCount Varchar(max),
			@SQLCmdLog Varchar(max),
			@SQLDropCmd Varchar(max),
			@JobID int,
			@PreBuildQuery int,
			@StepOrder int,
			@NextStepID int,
			@DependsOnStepIDs varchar(500)=''

		exec JobControl..UpdateQueryFromJobParams @JobStepID

		select @JobID = js.JobID, @StepOrder=js.StepOrder, @SQLCmd = q.SQLCmd, 
				@PreBuildQuery = isnull(js.PreBuildQuery,0), @DependsOnStepIDs=js.DependsOnStepIDs
			from JobControl..JobSteps js 
				join QueryEditor..Queries q on js.QueryCriteriaID = q.ID
				join JobControl..Jobs j on j.JobID=js.JobID
			where js.StepID = @JobStepID;
	
	
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

		--Added 7/5/2018 - Mark W.
		if @SQLCmd is null
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 3,'*** QueryEditor..Queries.SQLCmd is null','SP JobControl..JC_QueryStep'
		
		if @PreBuildQuery=1
			Begin
				Declare @NewFileName varchar(max)
				Print '### STARTING PreBuildQuery ###';
				exec PreBuildQuery @JobStepID, @SQLCMD, @NewFileName OUTPUT;
				Print '### PreBuildQuery Complete ###';
				Set @SQLCmd = substring(@SQLCmd, 1, CHARINDEX('from ', @SQLCmd) + 4) + 
						@NewFileName + ' ' +
						substring(@SQLCmd, CHARINDEX('where ', @SQLCmd)-1, 5000);
				Print '--------------------------------------------------------------'
				Print '@SQLCmd value after PreBuildQuery: '
				Print @SQLCmd
				Print '--------------------------------------------------------------'

			End

		declare @StepTable varchar(50);
		set @StepTable = 'JobControlWork..QueryStepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID));

		declare @LogInfo varchar(200)
		set @LogInfo = 'SP Result Location:' + @StepTable;
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;

		set @SQLCmd = replace(@SQLCmd,'--#INTO TABLE#', 'INTO ' + @StepTable);
		print '@SQLcmd: ' + iif(@SQLCmd is null, 'NULL', @SQLCmd);
		set @SQLDropCmd = 'IF OBJECT_ID(''' + @StepTable + ''', ''U'') IS not NULL drop TABLE ' + @StepTable + ' ';
	
		print '@SQLDropCmd: ' + @SQLDropCmd;
		exec(@SQLDropCmd);

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
				Print '@SCT: ' + @SCT;
				if isnull(@SCT,'')<>''
					Begin
						Declare @StartMark int, @EndMark int, @LoopTable varchar(100), @Q1 nvarchar(max), @SCTval int;
						set @LoopTable = 'JobControlWork..BeginLoopStepResults_J' + ltrim(str(@JobID)) + '_S' + @DependsOnStepIDs;
						if OBJECT_ID(@LoopTable, 'U') is not null
							Begin
								set @Q1='Select @SCTval=' + @SCT + 'ID from ' + @LoopTable + ' where ProcessFlag=1'
								Execute sp_executesql @Q1, N'@SCTval int OUTPUT', @SCTval = @SCTval output;
							End
						if isnull(@SCTval,0)<>0
							Begin
								Print '@SQLCmd before location update: ' + @SQLCmd
								set @StartMark = CHARINDEX('#LocationClauseStart1#',@SQLCmd) + len('#LocationClauseStart1#') + 1
								set @EndMark = CHARINDEX('#LocationClauseEnd1#',@SQLCmd) - 3
								if @StartMark > 0 and @EndMark > 0
									set @SQLCmd = left(@SQLCmd, @StartMark) + ' ' + '[' + @SCT + 'ID]=' + convert(varchar, @SCTval) + ' ' + substring(@SQLCmd,@EndMark,len(@SQLCmd))				
							End
					End
			End

		print 'exec JobControl.dbo.JobStepLogInsert ' + convert(varchar(10), @JobStepID) + ', 1, ' + @SQLCmd + ', ''QuerySQLCMD''';
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @SQLCmd, 'QuerySQLCMD'



		print 'Final @SQLcmd: ' + @SQLCmd;
		exec(@SQLCmd);
		--Inserting a blank Log Info and count the no of entries in thr StepTable
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1,'','StepRecordCount'

		------------------------------------------------------------------------------------------------------------
		-- Modified this section 12-16-2018 - Mark W.
			--set @SQLCmdCount = 'Select Count(*) From ' + @StepTable
			--exec JobControl.dbo.JobStepLogInfoUpdate @JobStepID, 'StepRecordCount', @SQLCmdCount 
			--exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
			Declare @RowCount int;
			Exec JobControlWork.dbo.GetTableRowCount @StepTable, @RowCount output;
			Declare @cRowCount varchar(20) ;
			set @cRowCount = convert(varchar, @RowCount);
			exec JobControl.dbo.JobStepLogInfoUpdate @JobStepID, 'StepRecordCount', @cRowCount
			select @cRowCount=value from JobControl..Settings where Property='Maximum Query Results'
			if @RowCount>=convert(int, @cRowCount)
				-- More records were returned than anticipated.  Abort this job
				Begin
					Insert into JobStepLog(JobId, JobStepID, LogInformation, LogInfoType, LogInfoSource, LogStamp)
						values(@JobID, @JobStepID, 'Job Cancelled due to query exceeding maximum number of ' 
						+ convert(varchar, @cRowCount) + ' records',1,'JobControl.dbo.JC_QueryStep', getdate());


						declare @LogInfoRowCount varchar(50) = 'Job Cancelled due to query exceeding maximum number of ' 
						+ convert(varchar, @cRowCount) + ' records'

						exec JobControl.dbo.JobStepLogInsert @jobstepid, 1, @LogInfoRowCount, 'JobControl.dbo.JC_QueryStep'

					Print 'exec JobControl.dbo.JobControlStepUpdate ' + convert(varchar, @JobStepID) + ', ''Fail''';
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
				End
			else
				Begin
					Print 'exec JobControl.dbo.JobControlStepUpdate ' + convert(varchar, @JobStepID) + ', ''Complete''';
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
