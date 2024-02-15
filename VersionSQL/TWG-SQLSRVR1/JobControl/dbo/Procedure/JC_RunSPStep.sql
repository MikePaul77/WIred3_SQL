/****** Object:  Procedure [dbo].[JC_RunSPStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_RunSPStep @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_WARNINGS ON;
	SET ANSI_NULLs ON;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);
	declare @LogInfo varchar(500) = '';

	declare @debug bit = 1

	declare @IssueMonthParam varchar(50)
	declare @IssueWeekParam varchar(50)
	declare @CalYearParam varchar(50)
	declare @CalPeriodParam varchar(50)
	declare @StateParam varchar(50)
	
	begin try

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

		declare @SQLSP Varchar(max),
			@SQLSPParams Varchar(max),
			@SQLToStepTable bit,
			@SQLDropCmd Varchar(max),
			@SQLCmd Varchar(max),
			@JobID int,
			@StepOrder int, @DependsOnStepIDs varchar(100)

		select @JobID = js.JobID, @StepOrder=js.StepOrder
				, @SQLSP = coalesce(RunSP_Procedure,'')
				, @SQLSPParams = coalesce(RunSP_Params,'')
				, @SQLToStepTable = coalesce(RunSP_ToStepTable,0)
				, @CalPeriodParam = coalesce(jpCP.ParamValue,'')
				, @CalYearParam = coalesce(jpCY.ParamValue,'')
				, @IssueWeekParam = coalesce(jpIW.ParamValue,'')
				, @IssueMonthParam = coalesce(jpIM.ParamValue,'')
				, @DependsOnStepIDs = coalesce(js.DependsOnStepIDs,'')
			from JobControl..JobSteps js
				join JobControl..Jobs j on j.JobID=js.JobID
				left outer join JobControl..JobParameters jpCP on jpCP.JobID = js.JobID and jpCP.ParamName in ('CalPeriod') 
				left outer join JobControl..JobParameters jpCY on jpCY.JobID = js.JobID and jpCY.ParamName in ('CalYear')
				left outer join JobControl..JobParameters jpIW on jpIW.JobID = js.JobID and jpIW.ParamName in ('IssueWeek')
				left outer join JobControl..JobParameters jpIM on jpIM.JobID = js.JobID and jpIM.ParamName in ('IssueMonth') 
			where js.StepID = @JobStepID;

		if @SQLSPParams > ''
		begin
			set @SQLSPParams = replace(@SQLSPParams,'#IM#',@IssueMonthParam)
			set @SQLSPParams = replace(@SQLSPParams,'#IW#',@IssueWeekParam)
			set @SQLSPParams = replace(@SQLSPParams,'#CY#',@CalYearParam)
			set @SQLSPParams = replace(@SQLSPParams,'#CP#',@CalPeriodParam)
			set @SQLSPParams = replace(@SQLSPParams,'#JobID#',@JobID)
			set @SQLSPParams = replace(@SQLSPParams,'#StepID#',@JobStepID)
			set @SQLSPParams = replace(@SQLSPParams,'#DepOnStepIDs#', @DependsOnStepIDs)
		end
	
		if @SQLToStepTable = 1
			Begin

				--Inserting a blank Log Info and count the no of entries in thr StepTable
				exec JobControl.dbo.JobStepLogInsert @JobStepID, 1,'','StepRecordCount'

				declare @StepTable varchar(50);
				set @StepTable = 'JobControlWork..RunSQLSPStepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID));
				print '@StepTable: ' + @StepTable;

				set @LogInfo = 'SP Result Location:' + @StepTable;
				exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;

				set @SQLDropCmd = 'IF OBJECT_ID(''' + @StepTable + ''', ''U'') IS not NULL drop TABLE ' + @StepTable + ' ';
				print '@SQLDropCmd: ' + @SQLDropCmd;
				exec(@SQLDropCmd);

				print '@SQLSP: ' + @SQLSP
				print '@SQLSPParams: ' + @SQLSPParams

				declare @ResultSet varchar(500) = ''
				if @JobStepID in (37110,37179,37178, 40156,40155)
					set @ResultSet = ' with result sets ((LocName varchar(100), c1 varchar(100),c2 varchar(100),c3 varchar(100),c4 varchar(100), PrimOrder int, Outorder int, RecType varchar(20))) '


				set @SQLCmd = ' SELECT * INTO ' + @StepTable + 
								' FROM OPENROWSET(''SQLNCLI'' ' + 
								', ''Server=' + @@SERVERNAME + ';Trusted_Connection=yes;'' ' +
								', ''exec ' + @SQLSP + ' ' + replace(@SQLSPParams,'''','''''') + ' ' + @ResultSet + ' '') '

				print '@SQLCmd: ' + @SQLCmd;
				exec(@SQLCmd);

				Declare @RowCount int;
				--Exec JobControlWork.dbo.GetTableRowCount @StepTable, @RowCount output;
				Exec GetTableRowCount @StepTable, @RowCount output;
				Declare @cRowCount varchar(20) ;
				set @cRowCount = convert(varchar, @RowCount);
				exec JobControl.dbo.JobStepLogInfoUpdate @JobStepID, 'StepRecordCount', @cRowCount

				Print 'exec JobControl.dbo.JobControlStepUpdate ' + convert(varchar, @JobStepID) + ', ''Complete''';
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
			end
		else
			Begin

				set @SQLCmd = ' exec ' + @SQLSP + ' ' + @SQLSPParams
				print '@SQLCmd: ' + @SQLCmd;
				exec(@SQLCmd);				

				Print 'exec JobControl.dbo.JobControlStepUpdate ' + convert(varchar, @JobStepID) + ', ''Complete''';
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

			end

	end try
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
