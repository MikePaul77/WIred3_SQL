/****** Object:  Procedure [dbo].[JC_AuditStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_AuditStep
	@JobStepID int
AS
BEGIN


	SET NOCOUNT ON;
	Declare @JobID int,
			@XForm bit,
			@AuditID int,
			@SQL varchar(max),
			@LogSourceName varchar(100) = 'JobControl.dbo.JC_AuditStep : [JobControlStepUpdate]',
			@SourceTable varchar(100),
			@DependsOnStepIDs varchar(100);

	declare @StepPass bit = 1

	declare @ValidationClearedStamp datetime
	declare @ValidationClearedBy varchar(50)
	declare @FailedStamp datetime

	-- Get the JobID and DependsOnStep
	Select @JobID=JobID
			, @DependsOnStepIDs = isnull(DependsOnStepIDs,'')
			, @ValidationClearedStamp = ValidationClearedStamp
			, @ValidationClearedBy = coalesce(ValidationClearedBy,'')
			, @FailedStamp = FailedStamp
		from JobControl..JobSteps
		where StepID=@JobStepID

	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

	if @ValidationClearedStamp > @FailedStamp and @FailedStamp is not null and @ValidationClearedStamp is not null
	Begin

		print 'ValCleared'

		declare @LogInfo varchar(200)
		set @LogInfo = 'Previous Validation Failure Approved by ' + @ValidationClearedBy
		exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

	end
	else
	begin

		--Fail the job if no @DependsOnStepID
		if @DependsOnStepIDs='' 
			Begin
				exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, 'No DependsOn Step Specified.  Audit Aborted.', @LogSourceName
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
				RETURN
			End

		create table #AuditResults (AuditRecID int null, AuditType varchar(10) null, Results varchar(1000) null, ResultPass bit null, LogLevelID int null, XFormLayoutID int null)
		create table #RawAuditResults (Results varchar(1000) null, ResultPass bit null, LogLevelID int null)
	
		declare @DependsOnStepTableName varchar(500)
		declare @XFormLayoutID int, @XFormStepID int

		begin Try

     		 DECLARE curDependsOnSteps CURSOR FOR
					select 'JobControlWork..' + dst.StepName + 'StepResults_J' + ltrim(str(djs.JobID)) + '_S' + ltrim(str(djs.StepID))
							, djs.FileLayoutID
							, djs.StepID
						from JobControl..JobSteps djs
							join JobControl..JobStepTypes dst on djs.StepTypeID = dst.StepTypeID
						where  ',' + @DependsonStepIDs + ',' like '%,' + ltrim(str(djs.StepID)) + ',%'

			print @DependsonStepIDs

    			 OPEN curDependsOnSteps

    			 FETCH NEXT FROM curDependsOnSteps into @DependsOnStepTableName, @XFormLayoutID, @XFormStepID
    			 WHILE (@@FETCH_STATUS <> -1)
    			 BEGIN
			print @DependsOnStepTableName
					if coalesce(@XFormLayoutID,0) = 0
						exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, 'Dependent Step Must Be Transform Step', @LogSourceName
					else
						Begin

			print 'Cust @XFormLayoutID: ' + ltrim(str(@XFormLayoutID))


     						 DECLARE CurAudits CURSOR FOR
								Select coalesce(UseXForm,0), code, RecID
									from JobControl..XFormCustValidataions
									where LayoutID = @XFormLayoutID
										and isnull(Disabled,0)=0


    							 OPEN CurAudits

    							 FETCH NEXT FROM CurAudits into @XForm, @SQL, @AuditID
    							 WHILE (@@FETCH_STATUS <> -1)
    							 BEGIN
	
									truncate table #RawAuditResults

									declare @UseTableName varchar(200)
									set @UseTableName = @DependsOnStepTableName
									if @XForm=1 
										set @UseTableName = replace(@UseTableName, 'TransformStepResults_', 'TransformStepResultsA_')

									Set @SQL = Replace(@SQL, '##TargetTable##', @UseTableName) 
									Set @SQL = Replace(@SQL, '@JobID', convert(varchar, @JobID))
									Set @SQL = Replace(@SQL, '@JobStepID', convert(varchar, @JobStepID))

									--print @SQL

									insert #RawAuditResults execute(@SQL)

									insert #AuditResults (AuditRecID, AuditType, Results, ResultPass, LogLevelID, XFormLayoutID)
										select @AuditID, 'Custom', Results, ResultPass, LogLevelID, @XFormLayoutID
											from #RawAuditResults


									FETCH NEXT FROM CurAudits into @XForm, @SQL, @AuditID
    							 END
    							 CLOSE CurAudits
    							 DEALLOCATE CurAudits

							declare @FieldName varchar(100), @FieldSource varchar(100), @SuccessPct int, @CautionPct int, @AbovePct bit, @DataCheck varchar(50), @SpecificValue varchar(50)

							declare @cmdA varchar(max)
							declare @cmdB varchar(max)
							declare @cmdC varchar(max)
							declare @Cond varchar(100)
							declare @eCond varchar(100)
							declare @Targets varchar(200)
							declare @SuccessCond varchar(500)
							declare @LevelCond varchar(500)
							declare @UseXForm bit

		print 'XForm Vals @XFormLayoutID: ' + ltrim(str(@XFormLayoutID))

     						DECLARE CurFieldAudits CURSOR FOR
								select coalesce(fl.OutName, tc.Outname), null, v.SuccessPct, v.CautionPct, coalesce(v.AbovePct,0), v.DataCheck, v.SpecificValue, v.RecID
									, case when Fl.RecID > 0 then 0 else 1 end UseXFrom
								from JobControl..XFormFieldValidations v
									left outer join JobControl..FileLayoutFields fl on fl.RecID = v.LayoutFieldID and fl.FileLayoutID = v.LayoutID and coalesce(Fl.Disabled,0) = 0
									left outer join JobControl..FileLayouts f on f.Id = v.LayoutID
									left outer join JobControl..TransformationTemplateColumns tc on tc.RecID = v.XFormFieldID and tc.TransformTemplateID = f.TransformationTemplateId
								where coalesce(v.disabled,0) = 0
									and v.LayoutID = @XFormLayoutID

    							 OPEN CurFieldAudits

    							 FETCH NEXT FROM CurFieldAudits into @FieldName, @FieldSource, @SuccessPct, @CautionPct, @AbovePct, @DataCheck, @SpecificValue, @AuditID, @UseXForm
    							 WHILE (@@FETCH_STATUS <> -1)
    							 BEGIN

									set @UseTableName = @DependsOnStepTableName

									if @UseXForm=1 
										set @UseTableName = replace(@UseTableName, 'TransformStepResults_', 'TransformStepResultsA_')

									truncate table #RawAuditResults
		
									set @cmdC = JobControl.dbo.ValidationFieldCond(@AuditID,@UseTableName)

									if @cmdC > ''
									Begin
										--print '@@@@@@@@@@@@@@@@@@@@@@@@ After Start @@@@@@@@@@@@@@@@@@@@@@@@@@@@'
										--print @cmdC
										--print '@@@@@@@@@@@@@@@@@@@@@@@@ After End @@@@@@@@@@@@@@@@@@@@@@@@@@@'

										insert #RawAuditResults execute(@cmdC)

										insert #AuditResults (AuditRecID, AuditType, Results, ResultPass, LogLevelID, XFormLayoutID)
											select @AuditID, 'Field', Results, ResultPass, LogLevelID, @XFormLayoutID
												from #RawAuditResults
									End
				
									FETCH NEXT FROM CurFieldAudits into @FieldName, @FieldSource, @SuccessPct, @CautionPct, @AbovePct, @DataCheck, @SpecificValue, @AuditID, @UseXForm
    							 END
    							 CLOSE CurFieldAudits
    							 DEALLOCATE CurFieldAudits

							-- select * from #AuditResults where ResultPass = 0

							declare @Results varchar(1000)
							declare @CodeDescrip varchar(1000)
							declare @ResultPass bit
							declare @LogType int

		print 'Layout Vals @XFormLayoutID: ' + ltrim(str(@XFormLayoutID))


     						 DECLARE CurAudits CURSOR FOR
								select a.AuditRecID, a.Results + case when f.Note > '' then ' Note:' + f.Note else '' end
											, a.ResultPass, 'Audit ' + a.AuditType + ' ' + ltrim(str(a.AuditRecID)) + ': '
														+ case when a.AuditType = 'Custom' then c.CodeDescription 
															when a.AuditType = 'Field' and fl.RecID > 0 then upper(F2.ShortFileLayoutName) + '.' + upper(fl.OutName) + ' LayoutFieldID: ' + ltrim(str(f.LayoutFieldID))
															when a.AuditType = 'Field' and tc.RecID > 0 then upper(tt.ShortTransformationName) + '.' + upper(TC.OutName) + ' XFormFieldID: ' + ltrim(str(f.XFormFieldID))
														else '' end
											, a.LogLevelID  
									from #AuditResults a
										left outer join JobControl..XFormCustValidataions c on c.RecID = a.AuditRecID and a.AuditType = 'Custom' and c.LayoutID = @XFormLayoutID
										left outer join JobControl..XFormFieldValidations f on f.RecID = a.AuditRecID and a.AuditType = 'Field' and f.LayoutID = @XFormLayoutID
										left outer join JobControl..FileLayoutFields fl on fl.RecID = f.LayoutFieldID and fl.FileLayoutID = f.LayoutID
										left outer join JobControl..FileLayouts f2 on f2.Id = F.LayoutID
										left outer join JobControl..TransformationTemplateColumns tc on tc.RecID = f.XFormFieldID and tc.TransformTemplateID = f2.TransformationTemplateId
										left outer join JobControl..TransformationTemplates tt on tt.id = f2.TransformationTemplateId
									where a.XFormLayoutID = @XFormLayoutID

    							 OPEN CurAudits

    							 FETCH NEXT FROM CurAudits into @AuditID, @Results, @ResultPass, @CodeDescrip, @LogType
    							 WHILE (@@FETCH_STATUS <> -1)
    							 BEGIN
	
										if @ResultPass = 0
											set @StepPass = 0

										exec JobControl.dbo.JobStepLogInsert @JobStepID, @LogType, @Results, @CodeDescrip

									FETCH NEXT FROM CurAudits into @AuditID, @Results, @ResultPass, @CodeDescrip, @LogType
    							 END
    							 CLOSE CurAudits
    							 DEALLOCATE CurAudits


		-- We need this table because we can't nest this type of command
							--insert into #ValsOtherCount
							--exec JobControl..JC_AuditStep_LocCheck @XFormStepID

							declare @GroupRecID int = 0
							declare @GroupStamp DateTime = getdate()
	
							insert JobControl..ValsOtherCount (GroupRecID, GroupStamp) values(-1, @GroupStamp)
	
							select @GroupRecID = Max(RecID) 
								from JobControl..ValsOtherCount
								where GroupStamp = @GroupStamp

		print 'Layout Locataion Checks @XFormLayoutID: ' + ltrim(str(@XFormLayoutID))

							exec JobControl..JC_AuditStep_LocCheck @XFormStepID, @GroupRecID

		print 'Layout Dup Checks @XFormLayoutID: ' + ltrim(str(@XFormLayoutID))

							exec JobControl..JC_AuditStep_DupCheck @JobStepID, @GroupRecID

		print 'Layout Run Counts @XFormLayoutID: ' + ltrim(str(@XFormLayoutID))

							exec JobControl..JC_AuditStep_CountCheck @XFormStepID, @GroupRecID

							declare @ValPass bit, @ValLevel int, @ValResult varchar(2000), @ValType varchar(50)

							declare @LastType varchar(50)
							set @CodeDescrip = ''
							set @LastType = ''

							 DECLARE curOCVals CURSOR FOR
								  select ValPass, ValLevel, ValResult, ValType 
										from JobControl..ValsOtherCount
										where GroupRecID = @GroupRecID

							 OPEN curOCVals

							 FETCH NEXT FROM curOCVals into @ValPass, @ValLevel, @ValResult, @ValType
							 WHILE (@@FETCH_STATUS <> -1)
							 BEGIN

									if @LastType = '' or @LastType <> @ValType
									Begin
										if @ValType = 'DupCheck'
											select @CodeDescrip = 'DuplicateCheck: Fail if any duplicate records are found'
												from JobControl..XFormOtherValidataions
												where LayoutID = @XFormLayoutID
										if @ValType = 'LocCheck'
											select @CodeDescrip = 'LocationCheck: Fail if Each Query Location has less then ' + ltrim(str(LocationFailRecs)) + ' Records, Warn if less then ' + ltrim(str(LocationwarnRecs)) + ' Records '
												from JobControl..XFormOtherValidataions
												where LayoutID = @XFormLayoutID

										if @ValType = 'CountCheck'
											select @CodeDescrip = 'CountCheck: Compare Last ' + ltrim(str(LastRuns)) + ' Runs, Fail above ' + ltrim(str(PctFail)) + '% change, Warn above ' + ltrim(str(PctWarn)) + '% change'
												from JobControl..XFormRunCountValidataions
												where LayoutID = @XFormLayoutID

									end

									exec JobControl.dbo.JobStepLogInsert @JobStepID, @ValLevel, @ValResult, @CodeDescrip

									set @LastType = @ValType

									if @ValPass = 0
										set @StepPass = 0

								  FETCH NEXT FROM curOCVals into @ValPass, @ValLevel, @ValResult, @ValType
							 END
							 CLOSE curOCVals
							 DEALLOCATE curOCVals


		--						declare @LastRuns int
		--						declare @FailPct int
		--						declare @WarnPct int
		--						declare @ValID int

		--						select @LastRuns = LastRuns
		--								, @FailPct = PctFail
		--								, @WarnPct = PctWarn
		--								, @ValID = RecID
		--							from JobControl..XFormRunCountValidataions
		--							where LayoutID = @XFormLayoutID
		--								and coalesce(disabled,0) = 0

		--						if @ValID > 0
		--						begin

		--							declare @PctDif money

		--							declare @LastAvgTot money
		--							declare @CurrRunTot money

		--							drop table if exists #last

		--							select jl.ID RunID, jl.starttime, convert(int,slh.LogInformation) StepRecords
		--								, seq = ROW_NUMBER() OVER (PARTITION BY jl.JobID ORDER BY jl.starttime desc)
		--								into #last
		--								from JobControl..JobStepLogHist slh
		--									join JobControl..JobLog jl on jl.JobID = slh.JobID
		--																and coalesce(jl.TestMode,0) = 0
		--																and slh.LogStamp >= jl.starttime and slh.LogStamp <= jl.endtime
		--								where isnumeric(slh.LogInformation) = 1
		--									and slh.LogInfoSource in ('StepRecordCount') 
		--									and slh.LogInfoType = 1
		--									and slh.JobStepID = @JobStepID

		--							select @LastAvgTot = Avg(x.StepRecords)
		--								from (
		--									select hrA.StepRecords
		--										from #last hrA
		--											join #last hrB on hrA.seq + 1 = HrB.seq
		--										where hrA.Seq > 1
		--											and hrA.seq <= @LastRuns + 1
		--									) x

		--							select @CurrRunTot = x.StepRecords
		--								from (
		--									select hrA.StepRecords
		--										from #last hrA
		--											join #last hrB on hrA.seq + 1 = HrB.seq
		--										where hrA.Seq = 1
		--									) x

		--							select @PctDif = Abs(((@CurrRunTot - @LastAvgTot) / @LastAvgTot) *100) 

		--							select @ResultPass = case when @PctDif > @FailPct then 3 when @PctDif > @WarnPct then 2 else 1 end 
		--									, @Results = 'Cur: ' + ltrim(str(@CurrRunTot)) + ' Last ' + ltrim(str(@LastRuns)) +  ':' + ltrim(str(@LastAvgTot)) + ' (' + ltrim(str(@PctDif)) + '% Chg)'

		--print @Results
		--print @ResultPass
	
		--							if @ResultPass = 0
		--								set @StepPass = 0

		--							set @Results = coalesce(@Results, 'None')

		--							exec JobControl.dbo.JobStepLogInsert @JobStepID, @ResultPass, @Results, 'Audit Run Count Validation'

		--						end



					End
         		  FETCH NEXT FROM curDependsOnSteps into @DependsOnStepTableName, @XFormLayoutID, @XFormStepID
    		 END
    		 CLOSE curDependsOnSteps
    		 DEALLOCATE curDependsOnSteps

				if @StepPass = 0
				Begin
					Print 'Failed'
					--exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
					RAISERROR ('Validation forced step failure', 16, 1)
				end
				else
				Begin
					Print 'Passed'
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
				End

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

				if @StepPass = 1 -- Allready Logged issue above if step did not pass
					exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, @LogSourceName

				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

				RAISERROR (@ErrorMessage, -- Message text.  
					@ErrorSeverity, -- Severity.  
					@ErrorState -- State.  
					);  

			end catch


	end


END
