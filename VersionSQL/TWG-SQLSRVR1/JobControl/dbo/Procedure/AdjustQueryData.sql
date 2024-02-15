/****** Object:  Procedure [dbo].[AdjustQueryData]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.AdjustQueryData @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

		declare @ParamVal varchar(10)
		declare @ParamName varchar(20)

		select @ParamVal = jp.ParamValue
				, @ParamName = jp.ParamName
			from JobControl..JobParameters jp
				join JobControl..JobSteps js on jp.JobID = js.JobID
			where js.StepID = @JobStepID and jp.ParamName in ('IssueWeek','IssueMonth')

		declare @AdjRecs int, @IncRecs int, @ExcRecs int, @FieldName varchar(100)


     DECLARE DACurA CURSOR FOR
          		select count(*)
					, sum(case when coalesce(Include,0) = 1 then 1 else 0 end)
					, sum(case when coalesce(Include,0) = 0 then 1 else 0 end)
					, daf.UseFieldName
				from JobControl..QueryDataAdjust qda
					join JobControl..DataAdjustFields daf on daf.ID = qda.FieldID
				where qda.StepID = @JobStepID
					and (qda.IssueWeek = @ParamVal or qda.IssueMonth = @ParamVal)
					and coalesce(qda.Ignore,0) = 0
				group by daf.UseFieldName

     OPEN DACurA

     FETCH NEXT FROM DACurA into @AdjRecs, @IncRecs, @ExcRecs, @FieldName
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN


		--select @AdjRecs = count(*)
		--		, @IncRecs = sum(case when coalesce(Include,0) = 1 then 1 else 0 end)
		--		, @ExcRecs = sum(case when coalesce(Include,0) = 0 then 1 else 0 end)
		--		, @FieldName = max(daf.UseFieldName)

		--	from JobControl..QueryDataAdjust qda
		--		join JobControl..DataAdjustFields daf on daf.ID = qda.FieldID
		--	where qda.StepID = @JobStepID
		--		and (qda.IssueWeek = @ParamVal or qda.IssueMonth = @ParamVal)
		--		and coalesce(qda.Ignore,0) = 0

		declare @OrigStepCount int

		select @OrigStepCount = convert(int,LogInformation)
			from JobControl..JobStepLog
			where LogInfoSource = 'StepRecordCount'
					and JobStepID = @JobStepID

		set @OrigStepCount = coalesce(@OrigStepCount,0)
			
		if @AdjRecs > 0
		begin

			declare @SQLCmd Varchar(max)
					, @JobID int
					, @StepTable varchar(100)
					, @QuerySource varchar(100)
					, @LogInfo varchar(200)

			select @JobID = js.JobID
					, @StepTable = 'JobControlWork..' + jst.StepName + 'StepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID))
					, @QuerySource = coalesce(AlternateDB,'TWG_PropertyData_Rep') + '.dbo.' + FromPart
				from JobControl..JobSteps js
					left outer join jobControl..JobStepTypes jst on jst.StepTypeID = js.StepTypeID
					left outer Join JobControl..QueryTemplates qtp on qtp.Id = js.QueryTemplateID
				where js.StepID = @JobStepID;

			if @ExcRecs > 0
			begin

	
				set @SQLCmd = 'delete x	
						from ' + @StepTable + ' x
							join JobControl..QueryDataAdjust qda on x.' + @FieldName + ' = qda.FieldValue
																	and coalesce(qda.Ignore,0) = 0
																	and qda.StepID = ' + ltrim(str(@JobStepID)) + '
																	and qda.Include = 0
							join JobControl..JobParameters jp on jp.JobID = ' + ltrim(str(@JobID)) + '
																and ParamName = ''' + @ParamName + '''
																and jp.ParamValue = qda.' + @ParamName + ' '
				print @SQLCmd
				exec(@SQLCmd)

				set @LogInfo = 'Excluded Recs:' + ltrim(str(@IncRecs));
				exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, 'Query AdjustQueryData SP Exclude';

			end

			if @IncRecs > 0
			begin

					--!!!!!!   Important   !!!!!!!!
					-- The orignal plan was for all off these Sales and Mtg transactions to work like Properties
					-- But because of Mike not being able to index the Transaction ID's accross the Partioned Trans tables that works well in the views
					-- The performance is so slow it is un-usable
					-- The code below for mtgs and sales is an auful kludge to work around this problem
					-- 
					-- We use the base tables to look up the fileingdate and town of the incuded records
					-- then we get all the records fromt he view for that town and the date, this takes under a min, while trying to get a single ID take forever
					-- they are stored in the AdjustRecsTable
					-- then we insert them from there

					declare @AdjustRecsTable varchar(500)
					set @AdjustRecsTable = 'JobControlWork..QAdjustResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID));

					set @SQLCmd = 'drop TABLE if exists ' + @AdjustRecsTable + ' '
					print @SQLCmd
					exec(@SQLCmd)

					Declare @RowCountBefore int;
					Exec GetTableRowCount @StepTable, @RowCountBefore output;
					print '@StepTable: ' + @StepTable
					Print '@RowCountBefore:' + ltrim(str(@RowCountBefore))

					declare @FilingDate DateTime, @TranID bigint, @StateID int, @TownID int

					if @FieldName = 'SalesTransactionID'
					begin

						 DECLARE curA CURSOR FOR
								select t.FilingDate, t.ID, t.StateID, t.TownID
											from JobControl..QueryDataAdjust qda
												join JobControl..JobParameters jp on jp.JobID = @JobID
																		and ParamName = @ParamName
																		and (qda.IssueWeek = jp.ParamValue or qda.IssueMonth = jp.ParamValue)
												join TWG_PropertyData_Rep.dbo.SalesTransactions t on t.stateID = qda.StateID 
																								and t.ID = qda.FieldValue
											where coalesce(qda.Ignore,0) = 0
													and qda.StepID = @JobStepID
													and qda.Include = 1 
						 OPEN curA

						 FETCH NEXT FROM curA into @FilingDate, @TranID, @StateID, @TownID
						 WHILE (@@FETCH_STATUS <> -1)
						 BEGIN
			

								set @SQLCmd = '	##DestClauseA##
										select x.*
										##DestClauseB##
										from ' + @QuerySource + ' x
										where x.SaleFilingDate = ''' + convert(varchar(50),@FilingDate,101) + '''
											and x.StateID = ' + ltrim(str(@StateID)) + '
											and x.TownID = ' + ltrim(str(@TownID)) + '
											and x.SalesTransactionID = ' + ltrim(str(@TranID)) + ' '

								IF OBJECT_ID(@AdjustRecsTable, 'U') > 1
								Begin
									set @SQLCmd = REPLACE(@SQLCmd,'##DestClauseA##', ' insert ' + @AdjustRecsTable)
									set @SQLCmd = REPLACE(@SQLCmd,'##DestClauseB##', '')
								end
								else
								Begin
									set @SQLCmd = REPLACE(@SQLCmd,'##DestClauseA##', '')
									set @SQLCmd = REPLACE(@SQLCmd,'##DestClauseB##', ' into ' + @AdjustRecsTable)
								end

								print @SQLCmd;
								exec(@SQLCmd);

							  FETCH NEXT FROM curA into @FilingDate, @TranID, @StateID, @TownID
						 END
						 CLOSE curA
						 DEALLOCATE curA



	
					end

					if @FieldName = 'MortgageTransactionID'
					begin

						 DECLARE curA CURSOR FOR
								select t.FilingDate, t.ID, t.StateID, t.TownID
											from JobControl..QueryDataAdjust qda
												join JobControl..JobParameters jp on jp.JobID = @JobID
																		and ParamName = 'IssueWeek'
																		and (qda.IssueWeek = jp.ParamValue or qda.IssueMonth = jp.ParamValue)
												join TWG_PropertyData_Rep.dbo.MortgageTransactions t on t.stateID = qda.StateID 
																								and t.ID = qda.FieldValue
											where coalesce(qda.Ignore,0) = 0
													and qda.StepID = @JobStepID
													and qda.Include = 1 
						 OPEN curA

						 FETCH NEXT FROM curA into @FilingDate, @TranID, @StateID, @TownID
						 WHILE (@@FETCH_STATUS <> -1)
						 BEGIN
			

								set @SQLCmd = '	##DestClauseA##
										select x.*
										##DestClauseB##
										from ' + @QuerySource + ' x
										where x.MtgFilingDate = ''' + convert(varchar(50),@FilingDate,101) + '''
											and x.StateID = ' + ltrim(str(@StateID)) + '
											and x.TownID = ' + ltrim(str(@TownID)) + '
											and x.MortgageTransactionID = ' + ltrim(str(@TranID)) + ' '

								IF OBJECT_ID(@AdjustRecsTable, 'U') > 1
								Begin
									set @SQLCmd = REPLACE(@SQLCmd,'##DestClauseA##', ' insert ' + @AdjustRecsTable)
									set @SQLCmd = REPLACE(@SQLCmd,'##DestClauseB##', '')
								end
								else
								Begin
									set @SQLCmd = REPLACE(@SQLCmd,'##DestClauseA##', '')
									set @SQLCmd = REPLACE(@SQLCmd,'##DestClauseB##', ' into ' + @AdjustRecsTable)
								end

								print @SQLCmd;
								exec(@SQLCmd);

							  FETCH NEXT FROM curA into @FilingDate, @TranID, @StateID, @TownID
						 END
						 CLOSE curA
						 DEALLOCATE curA



	
					end

					if @FieldName in ('SalesTransactionID','MortgageTransactionID')
					begin

						set @SQLCmd = ' insert ' + @StepTable + ' 
										select x.*
											from JobControl..QueryDataAdjust qda
												join JobControl..JobParameters jp on jp.JobID = ' + ltrim(str(@JobID)) + ' 
																		and ParamName = ''' + @ParamName + '''
																		and jp.ParamValue = qda.' + @ParamName + '
												join ' + @AdjustRecsTable + ' x on x.stateID = qda.StateID 
																								and x.' + @FieldName + ' = qda.FieldValue
											where coalesce(qda.Ignore,0) = 0
													and qda.StepID = ' + ltrim(str(@JobStepID)) + ' 
													and qda.Include = 1 
													and convert(bigint,qda.FieldValue) not in (select distinct ' + @FieldName + ' from ' + @StepTable + ' where ' + @FieldName + ' is not null) ' 

						print @SQLCmd;
						exec(@SQLCmd);


						Declare @RowCountAfter int;
						Exec GetTableRowCount @StepTable, @RowCountAfter output;
						print '@StepTable: ' + @StepTable
						Print '@RowCountAfter:' + ltrim(str(@RowCountAfter)) + '  @RowCountBefore:' + ltrim(str(@RowCountBefore))

						if @RowCountAfter > @RowCountBefore
						begin

							set @LogInfo = 'Included Recs:' + ltrim(str((@RowCountAfter - @RowCountBefore)))
							exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, 'Query AdjustQueryData SP Include'
						end

					end 
					if @FieldName = 'PropertyID'
					begin

								set @SQLCmd = 'insert ' + @StepTable + '
											select x.* 
												from JobControl..QueryDataAdjust qda
													join JobControl..JobParameters jp on jp.JobID = ' + ltrim(str(@JobID)) + ' 
																			and ParamName = ''' + @ParamName + '''
																			and jp.ParamValue = qda.' + @ParamName + '
													join ' + @QuerySource + ' x on x.stateID = qda.StateID 
																									and x.' + @FieldName + ' = qda.FieldValue
											where coalesce(qda.Ignore,0) = 0
													and qda.StepID = ' + ltrim(str(@JobStepID)) + '
													and qda.Include = 1 
													and qda.FieldValue not in (select ' + @FieldName + ' from ' + @StepTable + ') '

								print @SQLCmd
								exec(@SQLCmd)

								set @LogInfo = 'Included Recs:' + ltrim(str(@IncRecs));
								exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, 'Query AdjustQueryData SP Include';
					end

					if @FieldName = 'MortgageAssignmentID' or @FieldName = 'MortgageDischargeID'
					begin

								set @SQLCmd = 'insert ' + @StepTable + '
											select x.* 
												from JobControl..QueryDataAdjust qda
													join JobControl..JobParameters jp on jp.JobID = ' + ltrim(str(@JobID)) + ' 
																			and ParamName = ''' + @ParamName + '''
																			and jp.ParamValue = qda.' + @ParamName + '
													join ' + @QuerySource + ' x on x.stateID = qda.StateID 
																									and x.' + @FieldName + ' = qda.FieldValue
											where coalesce(qda.Ignore,0) = 0
													and qda.StepID = ' + ltrim(str(@JobStepID)) + '
													and qda.Include = 1 
													and qda.FieldValue not in (select ' + @FieldName + ' from ' + @StepTable + ') '

								print @SQLCmd
								exec(@SQLCmd)

								set @LogInfo = 'Included Recs:' + ltrim(str(@IncRecs));
								exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, 'Query AdjustQueryData SP Include';
					end



			end  --End of Inc Code 
		

			declare @NewStepCount int 
			set @NewStepCount = @OrigStepCount + @IncRecs - @ExcRecs

			exec JobControl.dbo.JobStepLogInfoUpdate @JobStepID, 'StepRecordCount', @NewStepCount

		end

          FETCH NEXT FROM DACurA into  @AdjRecs, @IncRecs, @ExcRecs, @FieldName
     END
     CLOSE DACurA
     DEALLOCATE DACurA

END
