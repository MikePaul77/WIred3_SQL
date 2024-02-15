/****** Object:  Procedure [dbo].[CalcAnyMedians]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.CalcAnyMedians @JobStepID int, @PivotCSV varchar(max) 
AS
BEGIN
	SET NOCOUNT ON;

	Declare @WorkDB varchar(50) = 'JobControlWork'

	create table #conds (datacond varchar(max) null, updatecond varchar(max) null)

	Declare @SourceCode varchar(max), @XformColName varchar(500), @FromTable varchar(500), @DestTable varchar(500), @XFormID int
	declare @QueryTemplateID int, @PivotSourceCol varchar(500) 
	declare @GroupByCode varchar(max), @GroupByName varchar(100)

	declare @sepA varchar(20), @sepB varchar(20), @updateval varchar(50)
	declare @cmdA varchar(max)
	declare @cmdB varchar(max)
	declare @line1 varchar(max)
	declare @line2 varchar(max)
	declare @line3 varchar(max)

	DECLARE MedCurA CURSOR FOR
		select ttc.SourceCode
			, 'XF_' + ttc.OutName + '_Median' XFormColName
			, @WorkDB + '..' + Djst.StepName + 'StepResults_J' + ltrim(str(Djs.JobID)) + '_S' + ltrim(str(Djs.StepID)) FromTable
			, @WorkDB + '..' + jst.StepName + 'StepResultsA_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID)) DestTable
			, js.TransformationID
			, coalesce(tt.QueryTemplateID, 0)
			, pttc.SourceCode
		from JobControl..JobSteps js
			join JobControl..TransformationTemplates tt on tt.ID = js.TransformationID
			join JobControl..TransformationTemplateColumns ttc on ttc.TransformTemplateID = js.TransformationID and coalesce(ttc.Disabled,0) = 0
							and (ttc.CalcMedianCol = 1 or ttc.PivotCalcCol = 'Median')
			left outer join JobControl..TransformationTemplateColumns pttc on pttc.TransformTemplateID = js.TransformationID and coalesce(ttc.Disabled,0) = 0
							and pttc.PivotValCol = 1 
			left outer join JobStepTypes jst on jst.StepTypeID =js.StepTypeID
			left outer join JobSteps Djs on js.JobID = Djs.JobID and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(Djs.StepID)) + ',%'
			left outer join JobStepTypes Djst on Djst.StepTypeID = Djs.StepTypeID
		where js.StepID = @JobStepID

		 OPEN MedCurA

		 FETCH NEXT FROM MedCurA into @SourceCode, @XformColName, @FromTable, @DestTable, @XFormID, @QueryTemplateID, @PivotSourceCol
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

			set @sepA = ''
			set @sepB = 'Where '
			set @line1 = ''
			set @line2 = ''
			set @line3 = ''
			 DECLARE ValCurA CURSOR FOR
				select ttc.SourceCode, case when @QueryTemplateID = -2 then 'convert(varchar(100),' + ttc.OutName + ')'
																else 'convert(varchar(100),XF_' + ttc.OutName + ')' end
					from JobControl..TransformationTemplateColumns ttc
					where ttc.TransformTemplateID = @XFormID
						and ttc.GroupByCol = 1 and coalesce(ttc.Disabled,0) = 0

			 OPEN ValCurA

			 FETCH NEXT FROM ValCurA into @GroupByCode, @GroupByName
			 WHILE (@@FETCH_STATUS <> -1)
			 BEGIN

					set @line1 = @line1 + @sepA + @GroupByName
					set @line2 = @line2 + @sepB + @GroupByCode + ' = '''''' + ' + @GroupByName + ' + '''''''
					set @line3 = @line3 + @sepB + @GroupByName + ' = '''''' + ' + @GroupByName + ' + '''''''

					set @sepA = ', '
					set @sepB = ' and '

				  FETCH NEXT FROM ValCurA into @GroupByCode, @GroupByName
			 END
			 CLOSE ValCurA
			 DEALLOCATE ValCurA

			 set @cmdA = 'Select ''' + @line2 + ''' DataCond, ''' + @line3 + ''' UpdateCond  from ' + @DestTable
			 print @cmdA

			insert into #conds execute (@cmdA)

			declare @datacond varchar(max), @updatecond varchar(max)

			DECLARE CalcCurZ CURSOR FOR
				select datacond, updatecond from #conds

			OPEN CalcCurZ

			FETCH NEXT FROM CalcCurZ into @datacond, @updatecond
			WHILE (@@FETCH_STATUS <> -1)
			BEGIN

				declare @Median money

				if @QueryTemplateID = -1  -- GroupBy
				begin
					EXEC Support..Median @FromTable, @SourceCode, @datacond, @CalcMedian = @Median Output

					if @Median is null
						set @updateval = 'null'
					else
						set @updateval = '''' + ltrim(str(@Median)) + ''''

					set @cmdB = 'Update ' + @DestTable + ' set ' + @XformColName + ' = ' + @updateval + ' ' + @updatecond
					print @cmdB
					exec(@cmdB)
				end

				if @QueryTemplateID = -2  -- Pivot
				begin
					
					declare @PVColName varchar(100), @PVColval varchar(100)
					 DECLARE PivotCHcur CURSOR FOR
						select [value] colName, replace(replace([value],'[',''),']','') val
							from Support.FuncLib.SplitString(@PivotCSV,',')

					 OPEN PivotCHcur

					 FETCH NEXT FROM PivotCHcur into @PVColName, @PVColval
					 WHILE (@@FETCH_STATUS <> -1)
					 BEGIN
							declare @datacond2 varchar(max)

							set @datacond2 = @datacond + ' and ' + @PivotSourceCol + ' = ''' + @PVColval + ''''

							EXEC Support..Median @FromTable, @SourceCode, @datacond2, @CalcMedian = @Median Output

							if @Median is null
								set @updateval = 'null'
							else
								set @updateval = '''' + ltrim(str(@Median)) + ''''

							set @cmdB = 'Update ' + @DestTable + ' set ' + @PVColName + ' = ' + @updateval + ' ' + @updatecond 
							print @cmdB
							exec(@cmdB)

						  FETCH NEXT FROM PivotCHcur into @PVColName, @PVColval
					 END
					 CLOSE PivotCHcur
					 DEALLOCATE PivotCHcur


				end

				FETCH NEXT FROM CalcCurZ into @datacond, @updatecond
			END
			CLOSE CalcCurZ
			DEALLOCATE CalcCurZ


			  FETCH NEXT FROM MedCurA into @SourceCode, @XformColName, @FromTable, @DestTable, @XFormID, @QueryTemplateID, @PivotSourceCol
		 END
		 CLOSE MedCurA
		 DEALLOCATE MedCurA


	drop table #conds


END
