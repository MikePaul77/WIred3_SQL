/****** Object:  Procedure [dbo].[JC_ALTDataStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_ALTDataStep @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	begin try

		declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

		declare @AltDataStepID int = 0
		declare @AltDataCond varchar(max)
		declare @Success bit = 1
		declare @logEntry varchar(500)

		select @AltDataStepID = AltDataStepID 
				,@AltDataCond = ltrim(coalesce(AltDataCond,''))
			from JobControl..JobSteps 
			where StepID = @JobStepID

		if @AltDataStepID > 0
		begin

			declare @Cmd varchar(max)

			declare @SrcAltDataTableName varchar(500)
			declare @DestAltDataTableName varchar(500)

			select @DestAltDataTableName = 'JobControlWork..' + Djst.StepName + 'StepResults_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
				from JobControl..JobSteps js
					join JobControl..JobStepTypes Djst on Djst.StepTypeID = js.StepTypeID
				where js.StepID = @JobStepID

			select @SrcAltDataTableName = 'JobControlWork..' + Djst.StepName + 'StepResults_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
				from JobControl..JobSteps js
					join JobControl..JobStepTypes Djst on Djst.StepTypeID = js.StepTypeID
				where js.StepID = @AltDataStepID

			set @cmd = 'IF OBJECT_ID(''' + @DestAltDataTableName + ''', ''U'') IS not NULL drop TABLE ' + @DestAltDataTableName + ' '
			print @cmd
			exec(@cmd)

				IF OBJECT_ID(@SrcAltDataTableName, 'U') IS not NULL
					begin
						set @Cmd = 'select x.* into ' + @DestAltDataTableName + ' from ' + @SrcAltDataTableName + ' x '
						if @AltDataCond > ''
						begin

							declare @ParamValue varchar(50), @ParamName varchar(50), @ParamValue2 varchar(50)

							--select @ParamValue = jpw.ParamValue
							--	, @ParamName = jpw.ParamName
							--from JobControl..JobSteps js 
							--	left outer join JobControl..JobParameters jpW on jpW.JobID = js.JobID
							--where js.StepID = @JobStepID

							select @ParamValue = jpw.ParamValue
								, @ParamName = jpw.ParamName
								, @ParamValue2 = coalesce(jpw2.ParamValue,'')
							from JobControl..JobSteps js 
								left outer join JobControl..JobParameters jpW on jpW.JobID = js.JobID and coalesce(jpw.ParamName,'ZZ') <> 'CalYear'
								left outer join JobControl..JobParameters jpW2 on jpW2.JobID = js.JobID and jpw2.ParamName = 'CalYear'
							where js.StepID = @JobStepID


							if @ParamName = 'IssueMonth'
								set @AltDataCond = replace(@AltDataCond,'#IM#',@ParamValue)
							if @ParamName = 'IssueWeek'
								set @AltDataCond = replace(@AltDataCond,'#IW#',@ParamValue)
							if @ParamName = 'CalPeriod'
								set @AltDataCond = replace(@AltDataCond,'#CP#',@ParamValue+@ParamValue2)

							set @Cmd = @Cmd + ' where ' + @AltDataCond
						end
						print @cmd
						exec(@cmd)
					end
				else
					Begin
							set @logEntry = 'AltData Source table ' + @SrcAltDataTableName + ' does not exist.'
							exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, 'JC_ALTDataStep'
							exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
						set @Success = 0
					End

		end

		else
			Begin
					set @logEntry = 'AltData step does not have a AltData StepID specified.'
					exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, 'JC_ALTDataStep'
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
					set @Success = 0
			End

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1,'','StepRecordCount'
		Declare @RowCount int;
		Exec GetTableRowCount @DestAltDataTableName, @RowCount output;
		Declare @cRowCount varchar(20) ;
		set @cRowCount = convert(varchar, @RowCount);
		exec JobControl.dbo.JobStepLogInfoUpdate @JobStepID, 'StepRecordCount', @cRowCount

		declare @LogInfo varchar(500) = ''
		set @LogInfo = 'SP Result Location: ' + @DestAltDataTableName;
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;

		if @Success = 1
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

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

		set @logEntry ='Error Number ' + cast(@ErrorNumber AS nvarchar(50))+ ', ' +
                         'Error Line '   + cast(@ErrorLine AS nvarchar(50)) + ', ' +
                         'Error Message : ''' + @ErrorMessage + ''''

		print @logEntry

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, 'JC_ALTDataStep'

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

		RAISERROR (@ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  

	end catch


end
