/****** Object:  Procedure [dbo].[JC_TransformStep_BeforeTest]    Committed by VersionSQL https://www.versionsql.com ******/

Create PROCEDURE dbo.JC_TransformStep_BeforeTest @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

	declare @LogSourceName varchar(100) = 'SP JobControl.JC_TransformStep';
	declare @LogInfo varchar(500) = '';
	declare @goodparams bit = 1;
	
	begin try

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

		declare @SrcTable varchar(100), @StepTable varchar(100), @DestTable varchar(100)
		declare @TransformJoin varchar(max)
		declare @TemplateID int,  @FileLayoutID int
		declare @cmd varchar(500)

		select @SrcTable = Djst.StepName + 'StepResults_J' + ltrim(str(Djs.JobID)) + '_S' + ltrim(str(Djs.StepID)) 
				, @StepTable = jst.StepName + 'StepResultsA_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
				, @DestTable = jst.StepName + 'StepResults_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
				, @TemplateID = js.TransformationID
				, @FileLayoutID = js.FileLayoutID
				, @TransformJoin = ltrim(coalesce(tt.TransformJoinClause,''))
			from JobSteps js 
				join JobStepTypes jst on jst.StepTypeID =js.StepTypeID
				join JobSteps Djs on js.JobID = Djs.JobID and js.DependsOnStep = Djs.StepOrder
				join JobStepTypes Djst on Djst.StepTypeID = Djs.StepTypeID
				join TransformationTemplates tt on tt.Id = js.TransformationID
			where js.StepID = @JobStepID

		 declare @cmd2A  varchar(max), @cmd2B  varchar(max), @cmd2C  varchar(max), @cmd2D  varchar(max), @sep varchar(10)	
		 declare @FldSrc varchar(1000)
	 
		 set @cmd2A = ''
		 set @cmd2B = ''
		 set @cmd2C = ''
		 set @cmd2D = ''

		 DECLARE TransTempCol CURSOR FOR

			SELECT SourceCode + ' [XF_' + OutName+ ']' FldSrc
				FROM JobControl..TransformationTemplateColumns
				where TransformTemplateID = @TemplateID and coalesce(disabled,0) = 0

		 OPEN TransTempCol

		 FETCH NEXT FROM TransTempCol into @FldSrc
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

			if LEN(@cmd2A) < 4000 
				set @cmd2A = @cmd2A + ', ' + @FldSrc + char(13)
			else
				begin
					if LEN(@cmd2B) < 4000 
						set @cmd2B = @cmd2B + ', ' + @FldSrc + char(13)
					else
					begin
						if LEN(@cmd2C) < 4000 
							set @cmd2C = @cmd2C + ', ' + @FldSrc + char(13)
						else
						begin
							if LEN(@cmd2D) < 4000 
								set @cmd2D = @cmd2D + ', ' + @FldSrc + char(13)
						end
					end
				end

			  FETCH NEXT FROM TransTempCol into @FldSrc
		 END
		 CLOSE TransTempCol
		 DEALLOCATE TransTempCol

		set @cmd = 'IF OBJECT_ID(''JobControlWork..' + @StepTable + ''', ''U'') IS not NULL drop TABLE JobControlWork..' + @StepTable + ' '
		exec(@cmd)

		print 'select x.* ' + @cmd2A + ' ' + @cmd2B + ' ' + @cmd2C + ' ' + @cmd2D + ' into JobControlWork..' + @StepTable + ' from JobControlWork..' + @SrcTable + ' x ' + @TransformJoin

		exec('select x.* ' + @cmd2A + ' ' + @cmd2B + ' ' + @cmd2C + ' ' + @cmd2D + '  into JobControlWork..' + @StepTable + ' from JobControlWork..' + @SrcTable + ' x ' + @TransformJoin )

-- Layout

		 set @cmd2A = ''
		 set @cmd2B = ''
		 set @cmd2C = ''
		 set @cmd2D = ''

		 set @sep = ''

		 DECLARE TransTempCol CURSOR FOR

			SELECT case when coalesce(CaseChange,'') = 'upper' then 'upper(' 
							when coalesce(CaseChange,'') = 'lower' then 'lower(' 
							when coalesce(CaseChange,'') = 'proper' then 'TWG_PropertyData.FuncLib.ProperCase(' 
							else '' end
						+ case when left(padDirChr,1) = 'L' then 'TWG_PropertyData.FuncLib.PadWithLeft(' 
								when left(padDirChr,1) = 'R' then 'TWG_PropertyData.FuncLib.PadWithRight(' 
							else  '' end
						+ case when coalesce(DoNotTrim, 0) = 0 then 'ltrim(rtrim(' else  '' end
						+ 'convert(' + case when outtype = 'text' then 'varchar(' + ltrim(str(coalesce(outwidth,50))) + ')'
								when outtype = 'int' then 'int'
								when outtype = 'money' then 'money'
								when outtype = 'decimal' then 'float'
								else 'varchar(50)' end
					+ ', ' + SrcName + ')'
					+ case when coalesce(DoNotTrim, 0) = 0 then '))' else  '' end
					+ case when left(padDirChr,1) in ('L','R') then ',' + ltrim(str(coalesce(outwidth,50))) + ',''' + right(padDirChr,1) + ''')' else  '' end
					+ case when coalesce(CaseChange,'') <> '' then ')' else  '' end
					+' [' + OutName+ ']' FldSrc

				FROM JobControl..FileLayoutFields
				where FileLayoutID  = @FileLayoutID
					and OutOrder is not null and coalesce(disabled,0) = 0
				order by outorder

		 OPEN TransTempCol

		 FETCH NEXT FROM TransTempCol into @FldSrc
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

			if LEN(@cmd2A) < 4000 
				set @cmd2A = @cmd2A + @sep + @FldSrc + char(13)
			else
				begin
					if LEN(@cmd2B) < 4000 
						set @cmd2B = @cmd2B + @sep + @FldSrc + char(13)
					else
					begin
						if LEN(@cmd2C) < 4000 
							set @cmd2C = @cmd2C + @sep + @FldSrc + char(13)
						else
						begin
							if LEN(@cmd2D) < 4000 
								set @cmd2D = @cmd2D + @sep + @FldSrc + char(13)
						end
					end
				end

			set @sep = ','

			  FETCH NEXT FROM TransTempCol into @FldSrc
		 END
		 CLOSE TransTempCol
		 DEALLOCATE TransTempCol

		set @cmd = 'IF OBJECT_ID(''JobControlWork..' + @DestTable + ''', ''U'') IS not NULL drop TABLE JobControlWork..' + @DestTable + ' '
		exec(@cmd)

		declare @OrderClause varchar(2000), @OrderIndexCol varchar(2000), @SortDir varchar(10)
		set @OrderClause = ''
		set @sep = ''

		 DECLARE TransTempCol CURSOR FOR

			SELECT SrcName FldSrc
				, coalesce(SortDir,'') SortDir
				FROM JobControl..FileLayoutFields
				where FileLayoutID  = @FileLayoutID
					and SortOrder is not null and coalesce(disabled,0) = 0
				order by SortOrder

		 OPEN TransTempCol

		 FETCH NEXT FROM TransTempCol into @FldSrc, @SortDir
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

				set @OrderClause = @OrderClause + @sep + @FldSrc + ' ' + @SortDir

				set @sep = ','

			  FETCH NEXT FROM TransTempCol into @FldSrc, @SortDir
		 END
		 CLOSE TransTempCol
		 DEALLOCATE TransTempCol

		if @OrderClause > ''
			set @OrderIndexCol = ' ,ROW_NUMBER() over ( order by ' + @OrderClause + ') [_IndexOrderKey] '
		else
			set @OrderIndexCol = ' ,convert(int,null) [_IndexOrderKey] '

		print 'select ' + @cmd2A + ' ' + @cmd2B + ' ' + @cmd2C + ' ' + @cmd2D + ' ' + @OrderIndexCol + ' into JobControlWork..' + @DestTable + ' from JobControlWork..' + @StepTable + ' x '

		exec('select ' + @cmd2A + ' ' + @cmd2B + ' ' + @cmd2C + ' ' + @cmd2D + ' ' + @OrderIndexCol + ' into JobControlWork..' + @DestTable + ' from JobControlWork..' + @StepTable + ' x ' )

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

	end try
	begin catch
		declare @logEntry varchar(500)

		set @logEntry ='Error Number ' + cast(ERROR_NUMBER() AS nvarchar(50))+ ', ' +
                         'Error Line '   + cast(ERROR_LINE() AS nvarchar(50)) + ', ' +
                         'Error Message : ''' + error_message() + ''''

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, 'JC_TransformStep'

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

	end catch

END
