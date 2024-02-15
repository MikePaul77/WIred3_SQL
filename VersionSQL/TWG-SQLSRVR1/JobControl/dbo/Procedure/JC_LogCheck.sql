/****** Object:  Procedure [dbo].[JC_LogCheck]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_LogCheck @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);
	declare @LogInfo varchar(500) = '';

	declare @JobID int
	declare @DependsOnStepIDs varchar(100)
	declare @DependsOnStepTableName varchar(500)
	declare @CustSchemaName varchar(100)
	declare @LogCheckTableName varchar(100)
	declare @RemoveDuplicates bit

	declare @JobParamValue varchar(20), @JobParamName varchar(100)
	--TODO what do we do about CP, CY ???

	begin try

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

		Select @JobID = js.JobID
			, @DependsOnStepIDs=isnull(DependsOnStepIDs,'')
			, @CustSchemaName = case when coalesce(js.LC_CustSchema, '') = '' then 'Job' + ltrim(str(js.JobID)) else coalesce(js.LC_CustSchema, '') end
			, @RemoveDuplicates = coalesce(LC_RemoveDuplicates,0)
			, @JobParamValue = jpw.ParamValue
			, @JobParamName = jpw.ParamName
		from JobControl..JobSteps js
				left outer join JobControl..JobParameters jpW on jpW.JobID = js.JobID
		where js.StepID=@JobStepID

		--Fail the job if no @DependsOnStepID
		if @DependsOnStepIDs='' 
			Begin
				exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, 'No DependsOn Step Specified.  Audit Aborted.', @LogSourceName
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
				RETURN
			End

		select @DependsOnStepTableName = 'JobControlWork..' + dst.StepName + 'StepResults_J' + ltrim(str(djs.JobID)) + '_S' + ltrim(str(djs.StepID))
			from JobControl..JobSteps djs
				join JobControl..JobStepTypes dst on djs.StepTypeID = dst.StepTypeID
			where  ',' + @DependsonStepIDs + ',' like '%,' + ltrim(str(djs.StepID)) + ',%'

		-- Create LogCheck Table if does not exist

		set @LogCheckTableName = 'JobControlCust.' + @CustSchemaName + '.LogCheck_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID))
		
		declare @KeyFieldListWithType varchar(500)
		declare @KeyFieldList varchar(500)

		select @KeyFieldListWithType = substring((select ', ' + c.name + ' ' + typ.name + case when typ.name like '%varchar' then '(' + ltrim(str(c.max_length))  + ')' else '' end
												from JobControlWork.sys.tables t 
													join JobControlWork.sys.columns c on t.object_id = c.object_id
													join JobControl.sys.types typ on typ.user_type_id = c.user_type_id				
												where 'JobControlWork..' + t.name = @DependsOnStepTableName
													and c.name like '_Key_%'
												order by column_id 
												for XML path('')
										),2,500)
				, @KeyFieldList = substring((select ', ' + c.name
												from JobControlWork.sys.tables t 
													join JobControlWork.sys.columns c on t.object_id = c.object_id
													join JobControl.sys.types typ on typ.user_type_id = c.user_type_id				
												where 'JobControlWork..' + t.name = @DependsOnStepTableName
													and c.name like '_Key_%'
												order by column_id 
												for XML path('')
										),2,500)
		--print @KeyFieldListWithType 
		--print @KeyFieldList

		declare @Cmd varchar(max)
		
		IF OBJECT_ID(@LogCheckTableName, 'U') IS NULL
			begin

				set @Cmd = 'create table ' + @LogCheckTableName + '
								( RecID bigint identity(1,1) not null
									, ParamName varchar(50)
									, ParamVal varchar(20)
									, AddedStamp datetime
									, SentStamp datetime
									, FixedStamp datetime
									, FixedBy varchar(100)
									, ResendParamVal varchar(20)
									, SentPrevious bit
									, NeedAttnCondIDs varchar(200)
									, ' + @KeyFieldListWithType + ' 
									) '

				print @cmd
				print '--------------------------------------------------------'
				exec(@Cmd)

			end
		--else	
		--	Begin  
			--- TODO
		--	-- Alter LogCheck Table if New Keys added

		--	end

		-- Delete records for same Params
			set @cmd = 'delete ' + @LogCheckTableName + '
							where ParamName = ''' + @JobParamName + '''
								and ParamVal = ''' + @JobParamValue + ''' '
			print @cmd
			print '--------------------------------------------------------'
			exec(@Cmd)


		-- insert New Records with ParamName ParamVal
			
			set @cmd = 'insert ' + @LogCheckTableName + '
							(ParamName, ParamVal, AddedStamp, ' + @KeyFieldList  +  ')
							select ''' + @JobParamName + ''', ''' + @JobParamValue + ''', getdate(), ' + @KeyFieldList  +  '
								from ' + @DependsOnStepTableName
			print @cmd
			print '--------------------------------------------------------'
			exec(@Cmd)

		-- Check New Data for Dups and remove if NoResend is set
		if @RemoveDuplicates = 1
		Begin
			declare @KeyMatchingConds varchar(max) = ''
			declare @KeyField varchar(100)

			 DECLARE curKeyMatch CURSOR FOR
				  select Value
						from Support.FuncLib.SplitString(@KeyFieldList, ',')

			 OPEN curKeyMatch

			 FETCH NEXT FROM curKeyMatch into @KeyField
			 WHILE (@@FETCH_STATUS <> -1)
			 BEGIN
				
					set @KeyMatchingConds = @KeyMatchingConds + ' and nd.' + @KeyField + ' = od.' + @KeyField + char(10)

				  FETCH NEXT FROM curKeyMatch into @KeyField
			 END
			 CLOSE curKeyMatch
			 DEALLOCATE curKeyMatch

			set @cmd = 'update nd set SentPrevious = 1
				from ' + @LogCheckTableName + ' nd 
					join ' + @LogCheckTableName + ' od on od.ParamName <> ''' + @JobParamName + ''' 
																			and od.ParamVal <> ''' + @JobParamValue + '''
																			' + @KeyMatchingConds + ' 
				where nd.ParamName = ''' + @JobParamName + '''
					and nd.ParamVal = ''' + @JobParamValue + ''' '
			
			print @cmd
			print '--------------------------------------------------------'
			exec(@Cmd)

			set @Cmd = ' delete nd
							from ' + @DependsOnStepTableName + ' nd
							join ' + @LogCheckTableName + ' od on od.ParamName = ''' + @JobParamName + ''' 
															and od.ParamVal = ''' + @JobParamValue + '''
															and od.SentPrevious = 1
															' + @KeyMatchingConds 

			print @cmd
			print '--------------------------------------------------------'
			exec(@Cmd)
								


		end

		-- Check New Data against Check Conds mark any issues

		declare @RecID int , @CondLogic varchar(max)

		 DECLARE curConds CURSOR FOR
			select RecID, CondLogic 
				from JobControl..LogCheckConds
				where coalesce(disabled,0) = 0
					and JobstepID = @JobStepID

		 OPEN curConds

		 FETCH NEXT FROM curConds into @RecID, @CondLogic
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN


				set @cmd = 'update nd set NeedAttnCondIDs = coalesce(nd.NeedAttnCondIDs,'''') + ''' + ltrim(str(@RecID)) + '''
					from ' + @LogCheckTableName + ' nd 
						join ' + @DependsOnStepTableName + ' od on 1=1 ' + @KeyMatchingConds + ' 
					where nd.ParamName = ''' + @JobParamName + '''
						and nd.ParamVal = ''' + @JobParamValue + '''
						and ' + @CondLogic
					
			
				print @cmd
				print '--------------------------------------------------------'
				exec(@Cmd)


			  FETCH NEXT FROM curConds into @RecID, @CondLogic
		 END
		 CLOSE curConds
		 DEALLOCATE curConds

		-- Remove issues records from Xform table

			set @Cmd = ' delete nd
							from ' + @DependsOnStepTableName + ' nd
							join ' + @LogCheckTableName + ' od on od.ParamName = ''' + @JobParamName + ''' 
															and od.ParamVal = ''' + @JobParamValue + '''
															and coalesce(od.NeedAttnCondIDs,'''') > ''''
															' + @KeyMatchingConds 

			print @cmd
			print '--------------------------------------------------------'
			exec(@Cmd)

		-- Mark Remaing Records as Sent


			set @Cmd = ' update ' + @LogCheckTableName + ' set SentStamp = getdate()
								where ParamName = ''' + @JobParamName + ''' 
									and ParamVal = ''' + @JobParamValue + '''
									and coalesce(NeedAttnCondIDs,'''') = '''' 
									and coalesce(SentPrevious,0) = 0 '

			print @cmd
			print '--------------------------------------------------------'
			exec(@Cmd)


		-- TODO part of UI add Unsent fixed records to adjustments 









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
