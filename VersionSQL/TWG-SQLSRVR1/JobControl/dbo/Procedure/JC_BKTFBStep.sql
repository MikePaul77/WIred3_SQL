/****** Object:  Procedure [dbo].[JC_BKTFBStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_BKTFBStep @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);
	declare @LogInfo varchar(500) = '';
	declare @cmd varchar(max), @base varchar(max)

	declare @debug bit = 1

	
	begin try

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1,'','StepRecordCount'

		declare @DependsOnStepIDs varchar(2000)
		declare @ResultsTableName varchar(2000)
		select @DependsOnStepIDs = DependsOnStepIDs
				, @ResultsTableName = 'JobControlWork..BKTranFileAppendStepResults_J' + ltrim(str(JobID)) + '_S' + ltrim(str(StepID))
			from JobControl..JobSteps where StepID = @JobstepID

		declare @JobStartStamp datetime

		select @JobStartStamp = coalesce(min(jsl.LogStamp), getdate())
		from JobControl..JobStepLog jsl
			join JobControl..JobSteps js on js.JobID = jsl.JobID
		where js.StepID = @JobStepID

		declare @StepID int, @StepOrder int, @ReportName varchar(500), @RecordCount int, @SourceTable varchar(500), @JobRunDate Datetime, @DocType Varchar(20)

		 DECLARE BKTFB_curA CURSOR FOR
			select js.StepID, js.StepOrder, JobControl.dbo.GetJustFileName(jl.LogInformation) ReportName, jl2.LogInformation RecordCount
					, 'JobControlWork..' + Djst.StepName + 'StepResults_J' + ltrim(str(Djs.JobID)) + '_S' + ltrim(str(Djs.StepID)) SourceTable
					, @JobStartStamp JobRunDate
					, case when Djs.TransformationID = 397 then 'SAM'
							when Djs.TransformationID = 395 then 'ASN'
							when Djs.TransformationID = 396 then 'REL'
							when Djs.TransformationID = 398 then 'DED'
							when Djs.TransformationID = 456 then 'FCL' else '' end DocType
				from JobControl..JobSteps js
					left outer join JobControl..JobStepLog jl on jl.JobStepID = js.StepID and jl.LogInfoSource = 'ReportFileName'
					left outer join JobControl..JobStepLog jl2 on jl2.JobStepID = js.StepID and jl2.LogInfoSource = 'StepRecordCount'
					join JobControl..JobSteps Djs on js.JobID = Djs.JobID and JobControl.dbo.GetDependsJobStepID(js.StepID) = Djs.StepID
					join JobControl..JobStepTypes Djst on Djst.StepTypeID = Djs.StepTypeID
				where ',' + @DependsOnStepIDs + ',' like '%,' + ltrim(str(js.StepID)) + ',%'
				order by js.StepOrder

		 OPEN BKTFB_curA

		 FETCH NEXT FROM BKTFB_curA into @StepID, @StepOrder, @ReportName, @RecordCount, @SourceTable, @JobRunDate, @DocType
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				set @base = ' select ''TWG'' vendorcode, id vendorrecordid, ''' + convert(varchar(50), @JobRunDate, 101) + ''' transmissiondate '
				set @base = @base + ', fips, state, countyname county, ''' + @DocType + ''' doctype '
				set @base = @base + ', date recordingdate, book, page, docketref instrumentnumber '
				set @base = @base + ', convert(varchar(100),''' + @ReportName + ''') filename '
				set @base = @base + ', '''' concurmortgage, '''' concurdoctype, '''' concurrecordingdate, '''' concurbook, '''' concurpage, '''' concurinstrumentnumber'
				if @DocType = 'SAM'
				begin
					set @base = ' select ''TWG'' vendorcode, id vendorrecordid,''' + convert(varchar(50), @JobRunDate, 101) + ''' transmissiondate '
					set @base = @base + ', fips, st state, countyname county, ''' + @DocType + ''' doctype '
					set @base = @base + ', date recordingdate, book, page, docketref instrumentnumber '
					set @base = @base + ', convert(varchar(100),''' + @ReportName + ''') filename '
					set @base = @base + ', '''' concurmortgage, '''' concurdoctype, '''' concurrecordingdate, '''' concurbook, '''' concurpage, '''' concurinstrumentnumber'
				end
				if @DocType = 'ASN'
				begin
					set @base = ' select ''TWG'' vendorcode, id vendorrecordid,''' + convert(varchar(50), @JobRunDate, 101) + ''' transmissiondate '
					set @base = @base + ', fips, state, countyname county, ''' + @DocType + ''' doctype '
					set @base = @base + ', filingdate recordingdate, book, page, docref instrumentnumber '
					set @base = @base + ', convert(varchar(100),''' + @ReportName + ''') filename '
					set @base = @base + ', '''' concurmortgage, '''' concurdoctype, '''' concurrecordingdate, '''' concurbook, '''' concurpage, '''' concurinstrumentnumber'
				end
				if @DocType = 'REL'
				begin
					set @base = ' select ''TWG'' vendorcode, id vendorrecordid,''' + convert(varchar(50), @JobRunDate, 101) + ''' transmissiondate '
					set @base = @base + ', fips, state, countyname county, ''' + @DocType + ''' doctype '
					set @base = @base + ', filingdate recordingdate, book, page, docref instrumentnumber '
					set @base = @base + ', convert(varchar(100),''' + @ReportName + ''') filename '
					set @base = @base + ','''' concurmortgage, '''' concurdoctype, '''' concurrecordingdate, '''' concurbook, '''' concurpage, '''' concurinstrumentnumber'
				end
				if @DocType = 'DED'
				begin
					set @base = ' select ''TWG'' vendorcode, id vendorrecordid,''' + convert(varchar(50), @JobRunDate, 101) + ''' transmissiondate '
					set @base = @base + ', fips, st state, countyname county, ''' + @DocType + ''' doctype '
					set @base = @base + ', date recordingdate, book, page, '''' instrumentnumber '
					set @base = @base + ', convert(varchar(100),''' + @ReportName + ''') filename '
					set @base = @base + ', '''' concurmortgage, '''' concurdoctype, '''' concurrecordingdate, '''' concurbook, '''' concurpage, '''' concurinstrumentnumber'
				end
				if @DocType = 'FCL'
				begin
					set @base = ' select ''TWG'' vendorcode, prefid vendorrecordid,''' + convert(varchar(50), @JobRunDate, 101) + ''' transmissiondate '
					set @base = @base + ', fips, state, county, ''' + @DocType + ''' doctype '
					set @base = @base + ', filingdate recordingdate, book, page, docnum instrumentnumber '
					set @base = @base + ', convert(varchar(100),''' + @ReportName + ''') filename '
					set @base = @base + ', '''' concurmortgage, '''' concurdoctype, '''' concurrecordingdate, '''' concurbook, '''' concurpage, '''' concurinstrumentnumber'
				end


				if OBJECT_ID(@ResultsTableName,'U') IS NULL
					set @cmd = @base + ' into ' + @ResultsTableName + ' from ' +  @SourceTable
				else
					set @cmd = ' insert ' + @ResultsTableName + ' ' + @base + ' from ' +  @SourceTable

				if @debug = 1
					print @cmd
				exec(@cmd)

			  FETCH NEXT FROM BKTFB_curA into @StepID, @StepOrder, @ReportName, @RecordCount, @SourceTable, @JobRunDate, @DocType
		 END
		 CLOSE BKTFB_curA
		 DEALLOCATE BKTFB_curA

		Declare @RowCount int;
		Exec JobControlWork.dbo.GetTableRowCount @ResultsTableName, @RowCount output;
		Declare @cRowCount varchar(20) ;
		set @cRowCount = convert(varchar, @RowCount);
		exec JobControl.dbo.JobStepLogInfoUpdate @JobStepID, 'StepRecordCount', @cRowCount

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
