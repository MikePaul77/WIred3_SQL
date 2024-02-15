/****** Object:  Procedure [dbo].[LogKeyProcess]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.LogKeyProcess @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

declare @KeyFieldOutName varchar(100)
declare @KeyFields varchar(max)
declare @KeyJoinClause varchar(max)
declare @Sep varchar(10)
declare @Sep2 varchar(10)
declare @JobID int

set @KeyFields = ''
set @Sep = ''
set @Sep2 = ''
set @KeyJoinClause = ''

	declare @XFormTableName varchar(500)
	declare @LogKeyTableName varchar(500)
	declare @XFormLogMode varchar(50)

	select @XFormTableName = 'JobControlWork..' + Djst.StepName + 'StepResultsA_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
			, @LogKeyTableName = 'JobControl..' + Djst.StepName + 'XFormKeyLog_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
			, @XFormLogMode = coalesce(js.XFormLogMode,0)
			, @JobID = js.JobID
		from JobControl..JobSteps js
			join JobControl..JobStepTypes Djst on Djst.StepTypeID = js.StepTypeID
		where js.StepID = @JobStepID

	if @XFormLogMode > 0
	begin

		 DECLARE LogKeycurA CURSOR FOR
			select 'XF_' + ttc.OutName
				from JobControl..JobSteps js
					join JobControl..TransformationTemplateColumns ttc on ttc.TransformTemplateID = js.TransformationID
				where StepID = @JobStepID and ttc.LogKeyCol = 1 and coalesce(ttc.Disabled,0) = 0  
				order by ttc.RecID

		 OPEN LogKeycurA

		 FETCH NEXT FROM LogKeycurA into @KeyFieldOutName
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				declare @KeyFieldLeft varchar(20) = 'coalesce('
				declare @KeyFieldRight varchar(20) = ','''')'
				declare @Type varchar(50)

				select @Type = typ.name
					from JobControl.sys.columns col
						join JobControl.sys.objects obj on col.object_id = obj.object_id
						join JobControl.sys.types typ on typ.user_type_id = col.user_type_id
					where obj.name = replace(@LogKeyTableName,'JobControl..','')
						and col.Name = @KeyFieldOutName

				if @Type in ('int', 'bigint')
				begin
					set @KeyFieldLeft = 'coalesce('
					set @KeyFieldRight = ',-999)'
				end
				if @Type in ('date', 'datetime')
				begin
					set @KeyFieldLeft = 'coalesce('
					set @KeyFieldRight = ',''1/1/1980'')'
				end


				set @KeyFields = @KeyFields + @Sep + @KeyFieldOutName
				set @KeyJoinClause = @KeyJoinClause + @Sep2 + @KeyFieldLeft + 'sr.' + @KeyFieldOutName + @KeyFieldRight + ' = ' + @KeyFieldLeft + 'lr.' + @KeyFieldOutName + @KeyFieldRight
				set @Sep = ', '
				set @Sep2 = ' and '

			  FETCH NEXT FROM LogKeycurA into @KeyFieldOutName
		 END
		 CLOSE LogKeycurA
		 DEALLOCATE LogKeycurA

		if @KeyFields > ''
		begin
			declare @Cmd varchar(max)

			Declare @PS int, @PIW int, @PIM int, @PCY int, @PCP int, @LastJobParam varchar(20);
			Select @PS=PromptState, @PIW=PromptIssueWeek, @PIM=PromptIssueMonth, 
					@PCY=PromptCalYear, @PCP=PromptCalPeriod, @LastJobParam=LastJobParameters 
				from Jobs where JobID=@JobID
			
			Declare @X varchar(10), @IW varchar(6)='', @IM varchar(6), @CP varchar(2),
				@CY varchar(4), @ST varchar(2)

			declare @ParamClause varchar(4000) = ''
			declare @ParamVals varchar(4000) = ''
			declare @ParamFields varchar(4000) = ''
			declare @ParamComb varchar(4000) = ''

			if left(@LastJobParam,4)='IW: '
				Begin
					set @IW=substring(@LastJobParam, 5,6)
					set @LastJobParam=substring(@LastJobParam,12, 20)
					set @ParamClause = @ParamClause + ' and Param_IssueWeek = ' + @IW + ' '
					set @ParamComb = @ParamComb + ' , ''' + @IW + ''' Param_IssueWeek '
					set @ParamVals = @ParamVals + ' , ''' + @IW + ''' '
					set @ParamFields = @ParamFields + ' , Param_IssueWeek '
				End

			if left(@LastJobParam,4)='IM: '
				Begin
					set @IM=substring(@LastJobParam, 5,6)
					set @LastJobParam=substring(@LastJobParam,12, 20)
					set @ParamClause = @ParamClause + ' and Param_IssueMonth = ' + @IM + ' '
					set @ParamComb = @ParamComb + ' , ''' + @IM + ''' Param_IssueMonth '
					set @ParamVals = @ParamVals + ' , ''' + @IM + ''' '
					set @ParamFields = @ParamFields + ' , Param_IssueMonth '
				End

			if left(@LastJobParam,4)='CP: '
				Begin
					set @CP=substring(@LastJobParam, 5,2)
					set @LastJobParam=substring(@LastJobParam,8, 20)
					set @ParamClause = @ParamClause + ' and Param_CalPeriod = ' + @CP + ' '
					set @ParamComb = @ParamComb + ' , ''' + @CP + ''' Param_CalPeriod '
					set @ParamVals = @ParamVals + ' , ''' + @CP + ''' '
					set @ParamFields = @ParamFields + ' , Param_CalPeriod '
				End

			if left(@LastJobParam,4)='CY: '
				Begin
					set @CY=substring(@LastJobParam, 5,4)
					set @LastJobParam=substring(@LastJobParam,8, 10)
					set @ParamClause = @ParamClause + ' and Param_CalYear = ' + @CY + ' '
					set @ParamComb = @ParamComb + ' , ''' + @CY + ''' Param_CalYear '
					set @ParamVals = @ParamVals + ' , ''' +@CY + ''' '
					set @ParamFields = @ParamFields + ' , Param_CalYear '
				End



			IF OBJECT_ID(@LogKeyTableName, 'U') IS NOT NULL -- Exists
			begin

				set @Cmd = ' delete ' + @LogKeyTableName + ' where 1=1 ' +  @ParamClause
				print @Cmd
				exec(@cmd)
		
				if @XFormLogMode = 2 -- Remove Previously Sent
				begin
					
					declare @DelCount int
					declare @DelCmd nvarchar(max)
					declare @OutPut nvarchar(100) = ' @retvalOUT  int OUTPUT'

					set @DelCmd = 'select @retvalOUT = count(*) from ' + @XFormTableName + ' sr ' + char(10)
					set @DelCmd = @DelCmd + ' join ' +  @LogKeyTableName + ' lr  on ' + @KeyJoinClause


					EXEC sp_executesql @DelCmd, @outPut, @retvalOUT=@DelCount OUTPUT;

					declare @LogInfo varchar(200)
					set @LogInfo = 'Duplicate Key Records Removed: ' + ltrim(str(@DelCount))
					exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, 'LogKeyProcess';

					Declare @OverrideCond varchar(100)
					Declare @AllOverrideConds varchar(Max) = ''

					 DECLARE OverrideCur CURSOR FOR
						select
							case when seq = 1 then ' where ' else ' and ' end + Cond
							from (
								select daf.UseFieldName + ' <> ' + qda.FieldValue Cond
										, seq = ROW_NUMBER() OVER (order by qda.FieldValue)
									from JobControl..QueryDataAdjust qda
										join JobControl..DataAdjustFields daf on daf.ID = qda.FieldID 
									where qda.LogOverride = 1 and coalesce(qda.ignore,0) = 0 and qda.include = 1
										and qda.IssueWeek = @IW
										and qda.StepID in (select StepID from JobControl..JobSteps where JobID in (select JobID from JobControl..JobSteps where StepID = @JobStepID))
								) z

					 OPEN OverrideCur

					 FETCH NEXT FROM OverrideCur into @OverrideCond
					 WHILE (@@FETCH_STATUS <> -1)
					 BEGIN

							set @AllOverrideConds = @AllOverrideConds + ' ' + @OverrideCond

						  FETCH NEXT FROM OverrideCur into @OverrideCond
					 END
					 CLOSE OverrideCur
					 DEALLOCATE OverrideCur

					set @Cmd = 'delete sr from ' + @XFormTableName + ' sr ' + char(10)
					set @Cmd = @Cmd + ' join ' +  @LogKeyTableName + ' lr  on ' + @KeyJoinClause
					set @Cmd = @Cmd + ' ' + @AllOverrideConds
					print @Cmd
					exec(@cmd)

				end

				set @Cmd = 'insert ' + @LogKeyTableName + '(' + @KeyFields + @ParamFields + ', LogStamp) select ' + @KeyFields + @ParamVals + ', getdate() LogStamp from ' + @XFormTableName
				print @Cmd
				exec(@cmd)

			end
			else
			begin
				set @Cmd = 'select ' + @KeyFields + @ParamComb + ', getdate() LogStamp into ' + @LogKeyTableName + ' from ' + @XFormTableName
				print @Cmd
				exec(@cmd)
			end


		end

	end

END
