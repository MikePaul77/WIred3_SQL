/****** Object:  Procedure [dbo].[JC_TransformStep_TotWork]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_TransformStep_TotWork @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_WARNINGS ON;
	SET ANSI_NULLS ON ;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);
	declare @LogInfo varchar(500) = '';
	declare @goodparams bit = 1;

	declare @debug bit = 1
	
	begin try

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

		declare @StepTypeID int = 0
		declare @CTLFileSource varchar(max)
		declare @InLoop bit = 0
		declare @DependentCreateZeroRecordReport bit = 0
		declare @FieldMode varchar(10)
		declare @GrpByTotal bit = 0
		declare @GrpBySubTotal bit = 0
		declare @XFormID int = 0

		select @StepTypeID = js.StepTypeID
			, @InLoop = JobControl.dbo.InLoop(js.StepID)
			, @DependentCreateZeroRecordReport = coalesce(rjs.CreateZeroRecordReport,0)
			, @FieldMode = coalesce(fl.FieldMode,'')
			, @GrpByTotal = coalesce(tt.GrpByTotal,0)
			, @GrpBySubTotal = coalesce(tt.GrpBySubTotal,0)
			, @XFormID = tt.ID
		from JobControl..JobSteps js
			left outer join JobControl..JobSteps rjs on js.JobID = rjs.jobid and rjs.StepTypeID = 22 
														and ',' + rjs.DependsOnStepIDs + ',' like '%,' + ltrim(str(js.StepID)) + ',%'
			left outer join JobControl..FileLayouts fl on fl.ID = js.FileLayoutID
			left outer join JobControl..TransformationTemplates tt on tt.ID = js.TransformationID
		where js.StepID = @JobStepID

-- XForm

		declare @FromClause varchar(max), @WhereClause varchar(max), @JoinClause varchar(max), @IntoClause varchar(max), @SourceFields varchar(max), @OrderIndex varchar(max)
		declare @FieldList1 varchar(max), @FieldList2 varchar(max), @FieldList3 varchar(max), @FieldList4 varchar(max), @FieldList5 varchar(max), @FieldList6 varchar(max), @ClauseFrameWork varchar(max)
		declare @cmd  varchar(max)

		-- For a Pivot Transform we need the distinct values of a column to for the column headers
		-- We can not get that from inside of a function so we get then here
		-- and pass them into the functionJobControl.dbo.XFORMTSQLParts
		declare @PivotValueCSV varchar(max) = ''
		exec JobControl.dbo.GetPivotDistinctCSV @JobStepID, @builtcsv = @PivotValueCSV Output


		select @FromClause = FromClause
				, @JoinClause = JoinClause
				, @WhereClause = WhereClause
				, @IntoClause = IntoClause
				, @SourceFields = SourceFields
				, @FieldList1 = FieldList1
				, @FieldList2 = FieldList2
				, @FieldList3 = FieldList3
				, @FieldList4 =  FieldList4
				, @FieldList5 =  FieldList5
				, @FieldList6 =  FieldList6
				, @ClauseFrameWork = ClauseFrameWork
			from JobControl.dbo.XFORMTSQLParts(@JobStepID, null, null, @PivotValueCSV)

		if @FromClause is null
		Begin
			print 'Aborting because there is no DependsOnStepID for this Transform';
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, 'No DependsOnStepID for this Transform', 'JC_TransformStep';
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
			Return
		End

		if @StepTypeID = 1101
			set @CTLFileSource = @FromClause

		--select #SourceFields# #FieldList1# #FieldList2# #FieldList3# #FieldList4# #FieldList4# #IntoClause# From #FromClause# x #JoinClause# 

		set @cmd = 'IF OBJECT_ID(''' + replace(@IntoClause,'Into ','') + ''', ''U'') IS not NULL drop TABLE ' + replace(@IntoClause,'Into ','') + ' '
		if @debug = 1
			print @cmd
		exec(@cmd)

		--set @FromClause = replace(@FromClause, 'JobControlWork..ReportStepRepCount', 'WiredJobControlWork..ReportStepRepCount')

		if @debug = 1
		begin
			print '@StepTypeID: ' + ltrim(str(@StepTypeID))
			print '---------------XForm-Start---------------------'
			print '---------------@SourceFields-------------------'
			print @SourceFields
			print '---------------@FieldList1---------------------'
			print @FieldList1
			print '---------------@FieldList2---------------------'
			print @FieldList2
			print '---------------@FieldList3---------------------'
			print @FieldList3
			print '---------------@FieldList4---------------------'
			print @FieldList4
			print '---------------@FieldList5---------------------'
			print @FieldList5
			print '---------------@FieldList6---------------------'
			print @FieldList6
			print '---------------@OrderIndex---------------------'
			print @OrderIndex
			print '---------------@IntoClause---------------------'
			print @IntoClause
			print '---------------@FromClause---------------------'
			print @FromClause
			print '---------------@JoinClause---------------------'
			print @JoinClause
			print '---------------@WhereClause---------------------'
			print @WhereClause
			print '---------------Combined---------------------'
			print 'select ' + @SourceFields + ' ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' ' + @FieldList5 + ' ' + @FieldList6  + ' ' + @IntoClause + ' from ' + @FromClause + ' x ' + @JoinClause + ' ' + @WhereClause
			print '---------------Run---------------------'
		end

		exec('select ' + @SourceFields + ' ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' ' + @FieldList5 + ' ' + @FieldList6 + ' ' + @IntoClause + ' from ' + @FromClause + ' x ' + @JoinClause + ' ' + @WhereClause )

		if @StepTypeID = 1117 -- Group By
		begin
			Print 'GroupBy Step'

			declare @GBFields varchar(1000) = substring(@WhereClause,charindex(' Group By ',@WhereClause) + 10,1000)
			Print '@GBFields: ' + @GBFields


			if @GrpBySubTotal = 1  -- MikePaul May 12, 2023 SubTotals are tricky becuse of unknown Priority / Higharchy so that is not funtional yet
			begin
				Print 'GroupBy w SubTotal'
			end
			if @GrpByTotal = 1
			begin
				Print 'GroupBy w Total'
				
					declare @GBTotFld varchar(50)
					declare @GBFieldList1 varchar(max) = @Fieldlist1

				     DECLARE GBTotalcurA CURSOR FOR
							select OutName
								from JobControl..TransformationTemplateColumns 
								where TransformTemplateID = @XFormID
									and GroupByCol = 1
									and coalesce(Disabled,0) = 0

					 OPEN GBTotalcurA

					 FETCH NEXT FROM GBTotalcurA into @GBTotFld
					 WHILE (@@FETCH_STATUS <> -1)
					 BEGIN
							set @GBTotFld = ltrim(rtrim(@GBTotFld))

							set @GBFieldList1 = replace(@GBFieldList1,', ' + @GBTotFld + ' [',' '''' [')

						  FETCH NEXT FROM GBTotalcurA into @GBTotFld
					 END
					 CLOSE GBTotalcurA
					 DEALLOCATE GBTotalcurA

					Print '@GBFieldList1: ' + @GBFieldList1


				--exec('select ' + @SourceFields + ' ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' ' + @FieldList5 + ' ' + @FieldList6 + ' ' + @IntoClause + ' from ' + @FromClause + ' x ' + @JoinClause + ' ' + @WhereClause )
			end
		end
		--set @cmd = 'IF OBJECT_ID(''' + replace(@IntoClause,'Into ','') + ''', ''U'') IS not NULL
		--			insert JobStepLog (JobId, JobStepID, LogStamp, LogInformation, LogInfoType, LogInfoSource )
		--			select JobID, StepID, getdate(), (select count(*) from ' + replace(@IntoClause,'Into ','') + '), 1, ''XFormRecordCount''
		--					from JobSteps where StepID = ' + ltrim(str(@JobStepID))

		declare @rowcnt int
		declare @ncmd nvarchar(max)
		set @ncmd = 'select @cnt = count(*) from ' + replace(@IntoClause,'Into ','')
		execute sp_executesql @ncmd,N'@cnt int OUTPUT', @cnt=@rowcnt OUTPUT

		set @cmd = 'IF OBJECT_ID(''' + replace(@IntoClause,'Into ','') + ''', ''U'') IS not NULL
					exec JobControl..JobStepLogInsert ' + ltrim(str(@JobStepID)) + ',1, ''' + ltrim(str(@rowcnt)) + ''',''XFormRecordCount'''
		exec(@cmd)

		if @debug = 1
		begin
			print '---------------XForm-End---------------------'
		end

-- After Xform and before layout Process Log Key fields in Xform
-- Log and then possiblely removing previously send records

	exec JobControl.dbo.LogKeyProcess @JobStepID

-- Group by's with Median's must be calculated here becuse there is not a SQL Median function
	exec JobControl.dbo.CalcAnyMedians @JobStepID, @PivotValueCSV

-- After Xform and Key field work 
-- Record Counts using GroupCountCol field and set create "Acumulating Table" for ALTDataSteps

	if @StepTypeID <> 1101
		exec JobControl.dbo.GroupCountProcessXForm @JobStepID

	--  forward looking if control file data step (1101) 
	--		is in a loop and has a report step that should not create CTL file when Zero recs
	--  then delete 0 file reocrds before report is created
	if @InLoop = 1 and @DependentCreateZeroRecordReport = 0 and @StepTypeID = 1101
	begin
		set @cmd = 'delete ' + replace(@IntoClause,'Into ','') + ' where __RecCount = 0 '
		print @cmd
		exec(@cmd)
	end


	exec JobControl.dbo.ALTDataProcess @JobStepID

	exec JobControl..CheckDataTruncation @JobStepID

-- Layout

	exec JobControl..BuildXFormLayoutTbls @JobStepID, '', @debug

	if @FieldMode = 'BKI'
		exec JobControl..BuildXFormLayoutTbls @JobStepID, @FieldMode, @debug

		--select @FromClause = FromClause
		--		, @IntoClause = IntoClause
		--		, @FieldList1 = FieldList1
		--		, @FieldList2 = FieldList2
		--		, @FieldList3 = FieldList3
		--		, @FieldList4 =  FieldList4
		--		, @OrderIndex =  OrderIndex
		--		, @ClauseFrameWork = ClauseFrameWork
		--	from JobControl.dbo.LayoutSQLParts(@JobStepID, null, null, @FieldMode)

		----select #FieldList1# #FieldList2# #FieldList3# #FieldList4# #IndexCol# #IntoClause# From #FromClause# 

		--set @cmd = 'IF OBJECT_ID(''' + replace(@IntoClause,'Into ','') + ''', ''U'') IS not NULL drop TABLE ' + replace(@IntoClause,'Into ','') + ' '
		--if @debug = 1
		--	print @cmd
		--exec(@cmd)

		--if @debug = 1
		--begin
		--	print '---------------Layout-Start---------------------'
		--	print '---------------@FieldList1---------------------'
		--	print @FieldList1
		--	print '---------------@FieldList2---------------------'
		--	print @FieldList2
		--	print '---------------@FieldList3---------------------'
		--	print @FieldList3
		--	print '---------------@FieldList4---------------------'
		--	print @FieldList4
		--	print '---------------@OrderIndex---------------------'
		--	print @OrderIndex
		--	print '---------------@IntoClause---------------------'
		--	print @IntoClause
		--	print '---------------@FromClause---------------------'
		--	print @FromClause
		--	print '---------------Combined---------------------'
		--	print 'select ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' ' + @OrderIndex + ' ' + @IntoClause + ' from ' + @FromClause + ' x'
		--	print '---------------Run---------------------'
		--end

		--exec('select ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' ' + @OrderIndex + ' ' + @IntoClause + ' from ' + @FromClause + ' x')

		----set @cmd = 'IF OBJECT_ID(''' + replace(@IntoClause,'Into ','') + ''', ''U'') IS not NULL
		----			insert JobStepLog (JobId, JobStepID, LogStamp, LogInformation, LogInfoType, LogInfoSource )
		----			select JobID, StepID, getdate(), (select count(*) from ' + replace(@IntoClause,'Into ','') + '), 1, ''StepRecordCount''
		----					from JobSteps where StepID = ' + ltrim(str(@JobStepID))
		----exec(@cmd)

		--set @ncmd = 'select @cnt = count(*) from ' + replace(@IntoClause,'Into ','')
		--execute sp_executesql @ncmd,N'@cnt int OUTPUT', @cnt=@rowcnt OUTPUT

		--set @cmd = 'IF OBJECT_ID(''' + replace(@IntoClause,'Into ','') + ''', ''U'') IS not NULL
		--			exec JobControl..JobStepLogInsert ' + ltrim(str(@JobStepID)) + ',1, ''' + ltrim(str(@rowcnt)) + ''',''LayoutRecordCount'''
		--exec(@cmd)

		--set @cmd = 'IF OBJECT_ID(''' + replace(@IntoClause,'Into ','') + ''', ''U'') IS not NULL
		--			exec JobControl..JobStepLogInsert ' + ltrim(str(@JobStepID)) + ',1, ''' + ltrim(str(@rowcnt)) + ''',''StepRecordCount'''
		--exec(@cmd)


		--if @debug = 1
		--begin
		--	print '---------------Layout-End---------------------'
		--end

		set @LogInfo = 'SP Result Location: ' + replace(@IntoClause,'Into ','');
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;

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

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, 'JC_TransformStep'

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

		RAISERROR (@ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  

	end catch

END
