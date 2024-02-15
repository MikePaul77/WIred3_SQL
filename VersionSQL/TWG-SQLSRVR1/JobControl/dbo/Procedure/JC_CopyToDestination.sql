/****** Object:  Procedure [dbo].[JC_CopyToDestination]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 07-08-2020
-- Description:	Copies Job Control tables to a new destination
-- =============================================
CREATE PROCEDURE dbo.JC_CopyToDestination
	@JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	-- Update JobSteps for custom status updates in the interface
	Update JobControl..JobSteps set CompletedStamp = null, FailedStamp = null, StartedStamp=getdate() where StepID=@JobStepID;
	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

	Begin Try

		--Get the JobID and the DependsOnStepID for the Source
		Declare @JobID int, @SourceStepID int = 0, @dIDs varchar(100), @DependsOnJobStepID int, @TargetFile varchar(100),
			@ErrorMsg varchar(100);
		Declare @SourceFile varchar(200)
		Select @JobID=js.JobID
			, @dIDs=isnull(js.DependsOnStepIDs,'')
			, @TargetFile=isnull(js.CopyToDestTargetTableName,'')
			, @SourceFile = 'JobControlWork..' + dst.StepName + 'StepResults_J' + ltrim(str(djs.JobID)) + '_S' + ltrim(str(djs.StepID)) 
			from JobSteps js
				left outer join JobControl..JobSteps djs on js.JobID = djs.jobid
					and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(djs.StepID)) + ',%'
				left outer join JobStepTypes dst on djs.StepTypeID = dst.StepTypeID
			where js.StepID=@JobStepID

		Declare @cJobStepID varchar(10) = convert(varchar, @JobStepID);
		If @dIDs='' or @TargetFile=''
			Begin
				If @dIDs=''
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'No Depends on Step Selected';
				else
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'No Target File Name';
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
				RETURN;
			End

		--Make sure the TargetFile is fully qualified
		Declare @TargetDB varchar(100)
		if charindex('.', @TargetFile)=0
			Begin
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'The target filename must be fully qualified (i.e. dbname..filename)';
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
				RETURN;
			End

		if charindex(',', @dIDs)>0 set @dIDs=substring(@dIDs,1, charindex(',', @dIDs)-1)
		set @DependsOnJobStepID=convert(int, @dIDs);
		Declare @SourceJobStepType int;
		Select @SourceJobStepType=StepTypeID from JobSteps where StepID=@DependsOnJobStepID;
		if @SourceJobStepType not in (29,1116,1117)   -- Transform, GroupData, PivotData
			Begin
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'The DependsOnStep is not a Transform, GroupData or PivotData Step';
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
				RETURN;
			End

		IF OBJECT_ID(@SourceFile, 'U') IS NULL
			Begin
				set @ErrorMsg='The Source File (' + @SourceFile + ') does not exist.';
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, @ErrorMsg;
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
				RETURN;
			End

		print @TargetFile
		print @TargetDB
		set @TargetDB = substring(@TargetFile,1,charindex('.', @TargetFile)-1);
		IF DB_ID(@TargetDB) IS NULL 
			Begin
				set @ErrorMsg='The Target File Database (' + @TargetDB + ') does not exist.';
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, @ErrorMsg;
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
				RETURN;
			End

		Declare @PS int, @PIW int, @PIM int, @PCY int, @PCP int, @LastJobParam varchar(20);
		Select @PS=PromptState, @PIW=PromptIssueWeek, @PIM=PromptIssueMonth, 
				@PCY=PromptCalYear, @PCP=PromptCalPeriod, @LastJobParam=LastJobParameters 
			from Jobs where JobID=@JobID
			
		Declare @X varchar(10), @IW varchar(6)='', @IM varchar(6), @CP varchar(2),
			@CY varchar(4), @ST varchar(2)

		if left(@LastJobParam,4)='IW: '
			Begin
				set @IW=substring(@LastJobParam, 5,6)
				set @LastJobParam=substring(@LastJobParam,12, 20)
			End

		if left(@LastJobParam,4)='IM: '
			Begin
				set @IM=substring(@LastJobParam, 5,6)
				set @LastJobParam=substring(@LastJobParam,12, 20)
			End

		if left(@LastJobParam,4)='CP: '
			Begin
				set @CP=substring(@LastJobParam, 5,2)
				set @LastJobParam=substring(@LastJobParam,8, 20)
			End

		if left(@LastJobParam,4)='CY: '
			Begin
				set @CY=substring(@LastJobParam, 5,4)
				set @LastJobParam=substring(@LastJobParam,8, 10)
			End

		if left(@LastJobParam,4)='ST: '
			set @ST=substring(@LastJobParam, 5,2)





		IF OBJECT_ID(@TargetFile, 'U') IS NULL
			Begin
				-- Target does not exist.  Do an INSERT
				Exec('Select *, ' + @JobStepID + ' as Param_JobStepID into ' + @TargetFile + ' from ' + @SourceFile);
				Print 'Select * into ' + @TargetFile + ' from ' + @SourceFile;
				Declare @SQL varchar(Max);
				Set @SQL = 'Update ' + @TargetFile + ' set '
				If @PS=1
					Begin
						Exec('Alter Table ' + @TargetFile + ' add Param_State varchar(2)');
						Print 'Alter Table ' + @TargetFile + ' add Param_State varchar(2)';
						Set @SQL = @SQL + 'Param_State=''' + @ST + ''', '
					End
				If @PIW=1
					Begin
						Exec('Alter Table ' + @TargetFile + ' add Param_IssueWeek varchar(6)');
						Print 'Alter Table ' + @TargetFile + ' add Param_IssueWeek varchar(6)';
						Set @SQL = @SQL + 'Param_IssueWeek=''' + @IW + ''', '
					End
				If @PIM=1
					Begin
						Exec('Alter Table ' + @TargetFile + ' add Param_IssueMonth varchar(6)');
						Print 'Alter Table ' + @TargetFile + ' add Param_IssueMonth varchar(6)';
						Set @SQL = @SQL + 'Param_IssueMonth=''' + @IM + ''', '
					End
				If @PCP=1
					Begin
						Exec('Alter Table ' + @TargetFile + ' add Param_CalPeriod varchar(2)');
						Print 'Alter Table ' + @TargetFile + ' add Param_CalPeriod varchar(2)';
						Set @SQL = @SQL + 'Param_CalPeriod=''' + @CP + ''', '
					End
				If @PCY=1
					Begin
						Exec('Alter Table ' + @TargetFile + ' add Param_CalYear varchar(4)');
						Print 'Alter Table ' + @TargetFile + ' add Param_CalYear varchar(4)'
						Set @SQL = @SQL + 'Param_CalYear=''' + @CY + ''', '
					End

				-- POPULATE THE NEW PARAMETER FIELDS
				Set @SQL = Left(@SQL, len(@SQL)-1);
				Print @SQL;
				Exec(@SQL);
			End
		ELSE
			Begin
				--Set up variables for deleting and then inserting records based on the parameters
				Declare @dSQL varchar(Max), @iSQL varchar(max);
				Set @dSQL = 'Delete from ' + @TargetFile + ' where Param_JobStepID=' + @cJobStepID + ' and ';
				Set @iSQL='Insert into ' + @TargetFile + ' Select *, ' + @cJobStepID + ' as Param_JobStepID, ';
				If @PS=1
					Begin
						Set @dSQL = @dSQL + 'Param_State=''' + @ST + ''' and '
						Set @iSQL = @iSQL + '''' + @ST + ''' as Param_State, '
					End
				If @PIW=1
					Begin
						Set @dSQL = @dSQL + 'Param_IssueWeek=''' + @IW + ''' and '
						Set @iSQL = @iSQL + '''' + @IW + ''' as Param_IssueWeek, '
					End
				If @PIM=1
					Begin
						Set @dSQL = @dSQL + 'Param_IssueMonth=''' + @IM + ''' and '
						Set @iSQL = @iSQL + '''' + @IM + ''' as Param_IssueMonth, '
					End
				If @PCP=1
					Begin
						Set @dSQL = @dSQL + 'Param_CalPeriod=''' + @CP + ''' and '
						Set @iSQL = @iSQL + '''' + @CP + ''' as Param_CalPeriod, '
					End
				If @PCY=1
					Begin
						Set @dSQL = @dSQL + 'Param_CalYear=''' + @CY + ''' and '
						Set @iSQL = @iSQL + '''' + @CY + ''' as Param_CalYear, '
					End

				Set @dSQL = left(@dSQL, len(@dSQL)-3);
				Print @dSQL;
				Exec(@dSQL);

			
				--Add Records with the parameter fields
				Set @iSQL = left(@iSQL, len(@iSQL)-1) + ' from ' + @SourceFile;
				Print @iSQL;
				Exec(@iSQL);
			End
	
		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

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
