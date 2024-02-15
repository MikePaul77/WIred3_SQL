/****** Object:  TableFunction [dbo].[LayoutSQLParts_Prev]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE function [dbo].[LayoutSQLParts]
(
	@JobStepID int, @FileLayoutID int, @LayoutFieldID int
)
RETURNS @LayoutmParts table ( FromClause varchar(max) null
							, IntoClause varchar(max) null
							, FieldList1 varchar(max) null
							, FieldList2 varchar(max) null
							, FieldList3 varchar(max) null
							, FieldList4 varchar(max) null
							, OrderIndex varchar(max) null
							, ClauseFrameWork varchar(max) null 
	)
As
Begin

	Declare @FromClause varchar(max) 
	Declare @IntoClause varchar(max)
	Declare @FieldList1 varchar(max) 
	Declare @FieldList2 varchar(max) 
	Declare @FieldList3 varchar(max) 
	Declare @FieldList4 varchar(max)
	
	Declare @WorkDB varchar(50) = 'JobControlWork'
	
	declare @SrcTable varchar(100), @DestTable varchar(100)

	declare @QueryTemplateID int = -1
	declare @QuerySourceID int = 1
	declare @HasNoModiType bit = 0
	declare @LayoutMode int = 1

	declare @sep varchar(10)
	declare @FldSrc varchar(1000), @FldID int, @LayoutFieldSrc varchar(1000)
	declare @StepTypeID int
	declare @QueryTypeID int
	 
	set @FieldList1 = ''
	set @FieldList2 = ''
	set @FieldList3 = ''
	set @FieldList4 = ''
	set @LayoutFieldSrc = ''

	set @sep = ''

	Declare @XFormTempID int
	Declare @UseJobStepID int
	set @UseJobStepID = @JobStepID
	if @JobStepID is not null
		begin
			select @SrcTable = jst.StepName + 'StepResultsA_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
					, @DestTable = jst.StepName + 'StepResults_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
					, @XFormTempID = js.TransformationID
					, @FileLayoutID = js.FileLayoutID
					, @QueryTemplateID = tt.QueryTemplateID
					, @StepTypeID = js.StepTypeID
					, @QueryTypeID = qt.QueryTypeID
					, @QuerySourceID = qs.id 
					, @HasNoModiType = coalesce(qt.HasNoModiType,0)
					, @LayoutMode = coalesce(js.LayoutFormattingMode,1) 
				from JobSteps js 
					left outer join JobStepTypes jst on jst.StepTypeID =js.StepTypeID
					left outer join JobSteps Djs on js.JobID = Djs.JobID and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(Djs.StepID)) + ',%'
					left outer join JobStepTypes Djst on Djst.StepTypeID = Djs.StepTypeID
					left outer join TransformationTemplates tt on js.TransformationID = tt.Id
					left outer join QueryTemplates qt on qt.Id = tt.QueryTemplateID
					left outer join QueryTypes qty on qty.QueryTypeID = qt.QueryTypeID
					left outer join QuerySources qs on qs.ID = qty.QuerySourceID


				where js.StepID = @UseJobStepID
		end
	else
		begin
			set @UseJobStepID = -777
			set @SrcTable = ''

			if @LayoutFieldID is not null
				select @FileLayoutID = FileLayoutID from FileLayoutFields where recID = @LayoutFieldID

			select @XFormTempID = tt.Id
				from TransformationTemplates tt
					join QueryTemplates qt on qt.Id = tt.QueryTemplateID
					left outer join FileLayouts fl on fl.TransformationTemplateId = tt.ID
				where Fl.Id = @FileLayoutID

		end

		 DECLARE TransTempCol CURSOR FOR

			SELECT 	case when @LayoutMode = 3 then 
							'coalesce(convert(varchar(1000), ' + case when ltrim(SrcName) = '' then '''''' else '[' + SrcName + ']' end + '),'''') [' + OutName+ ']'
					else
					case when coalesce(CaseChange,'None') = 'upper' then 'upper(' 
							when coalesce(CaseChange,'None') = 'lower' then 'lower(' 
							when coalesce(CaseChange,'None') = 'proper' then 'Support.FuncLib.ProperCase(' 
							else '' end
						+ case when coalesce(Padding,'None') = 'Left' then 'Support.FuncLib.PadWithLeft(' 
								when coalesce(Padding,'None') = 'Right' then 'Support.FuncLib.PadWithRight(' 
							else  '' end
						+ case when coalesce(DoNotTrim, 0) = 1 or @LayoutMode = 2 then '' else 'ltrim(rtrim(' end
						--+ 'convert(' + case when outtype = 'text' then 'varchar(' + ltrim(str(coalesce(outwidth,50))) + ')'
						--		when outtype = 'int' then 'int'
						--		when outtype = 'money' then 'money'
						--		when outtype = 'decimal' then 'float'
						--		else 'varchar(50)' end
				
					-- ## The 2 lines below were removed and replace with the next 2 that coalesce all null data to ''

					--	+ 'convert(' + case when coalesce(outwidth,0) > 0 then 'varchar(' + ltrim(str(coalesce(outwidth,50))) + ')' else 'varchar(1000)' end
					--+ ', ' + case when ltrim(SrcName) = '' then '''''' else SrcName end + ')'

						--+ 'coalesce(convert(' + case when coalesce(outwidth,0) > 0 then 'varchar(' + ltrim(str(coalesce(outwidth+10,50))) + ')' else 'varchar(1000)' end
						--+ ', ' + case when ltrim(SrcName) = '' then '''''' else '[' + SrcName + ']' end + '),'''')'

						-- MP 10/31/2020 2 line above were upgraded to us the new format function in the X line below

						-- MP 7/10/2021 2 varchar set lines below useed to be + 10 I am not sure why ex. ltrim(str(coalesce(outwidth+10,50)))
						-- Removed the +10 for acurate len triming
						+ case when coalesce(LayoutFormatID,0) = 0 then
							'coalesce(convert(' + case when coalesce(outwidth,0) > 0 then 'varchar(' + ltrim(str(coalesce(outwidth,50))) + ')' else 'varchar(1000)' end
							+ ', ' + case when ltrim(SrcName) = '' then '''''' else '[' + SrcName + ']' end + '),'''')'
						else
							case when coalesce(outwidth,0) > 0 then
								'coalesce(convert(varchar(' + ltrim(str(coalesce(outwidth,50))) + ')'
								+ ', JobControl.dbo.ApplyLayoutFormat(' + case when ltrim(SrcName) = '' then '''''' else '[' + SrcName + ']' end + ',' + ltrim(str(LayoutFormatID)) + ')),'''')'
							else
								'coalesce(JobControl.dbo.ApplyLayoutFormat(' + case when ltrim(SrcName) = '' then '''''' else '[' + SrcName + ']' end + ',' + ltrim(str(LayoutFormatID)) + '),'''')'
							end
						end


					+ case when coalesce(DoNotTrim, 0) = 1 or @LayoutMode = 2 then '' else '))' end
					+ case when coalesce(Padding,'None') in ('Left','Right') then ',' + ltrim(str(coalesce(PaddingLength,outwidth))) + ',''' + right(PaddingChar,1) + ''')' else  '' end
					+ case when coalesce(CaseChange,'None') not in ('None','') then ')' else  '' end
					+' [' + OutName+ ']' end FldSrc
					, RecID


				FROM JobControl..FileLayoutFields
				where FileLayoutID  = @FileLayoutID
					and OutOrder is not null and coalesce(disabled,0) = 0
					and coalesce(Hide,0) = 0
				order by outorder

		 OPEN TransTempCol

		 FETCH NEXT FROM TransTempCol into @FldSrc, @FldID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

			if LEN(@FieldList1) < 4000 
				set @FieldList1 = @FieldList1 + ', ' + @FldSrc + char(13)
			else
				begin
					if LEN(@FieldList2) < 4000 
						set @FieldList2 = @FieldList2 + ', ' + @FldSrc + char(13)
					else
					begin
						if LEN(@FieldList3) < 4000 
							set @FieldList3 = @FieldList3 + ', ' + @FldSrc + char(13)
						else
						begin
							if LEN(@FieldList4) < 4000 
								set @FieldList4 = @FieldList4 + ', ' + @FldSrc + char(13)
						end
					end
				end

			if @FldID = @LayoutFieldID
				set @LayoutFieldSrc = @FldSrc


			  FETCH NEXT FROM TransTempCol into @FldSrc, @FldID
		 END
		 CLOSE TransTempCol
		 DEALLOCATE TransTempCol

		declare @OrderClause varchar(2000), @OrderIndexCol varchar(2000), @SortDir varchar(10)
		set @OrderClause = ''
		set @sep = ''

		 DECLARE TransTempCol CURSOR FOR

			SELECT SrcName FldSrc
				, coalesce(SortDir,'') SortDir
				FROM JobControl..FileLayoutFields
				where FileLayoutID  = @FileLayoutID
					and coalesce(SortOrder,0) > 0 
					--!! MP 6/5/19 
                    --!! The line below was commented out to act a a Hide but still sort
                    --!! Before this change is sort by a column the column must show in the final layout
                    --!! The is that even when you disable a field it still can be used in the sort
                    --!! If this becomes an issue we will need add a Hide column to the LayoutFields table
                    --!! and the corresponding controls in XForm/Layout control
					--and coalesce(disabled,0) = 0
					and ltrim(rtrim(SrcName)) not in ('null')
					and isnull(disabled,0)=0 --  <-- Added 6/18/2020 - Mark W.
				order by SortOrder

		 OPEN TransTempCol

		 FETCH NEXT FROM TransTempCol into @FldSrc, @SortDir
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

				--set @OrderClause = @OrderClause + @sep + @FldSrc + ' ' + @SortDir
				set @OrderClause = @OrderClause + @sep + @FldSrc + ' ' + iif(@SortDir='0','asc', @SortDir) -- Added 10/20/2018 - Mark W.
				set @sep = ','

			  FETCH NEXT FROM TransTempCol into @FldSrc, @SortDir
		 END
		 CLOSE TransTempCol
		 DEALLOCATE TransTempCol

		 if @QueryTemplateID <= 0
			 begin
				if @OrderClause > ''
					set @OrderIndexCol = ' , ROW_NUMBER() over ( order by ' + @OrderClause + ') [_IndexOrderKey] '
				else if @StepTypeID in (1117,1116)
					set @OrderIndexCol = ' , convert(int,null) [_IndexOrderKey] '
				else
					set @OrderIndexCol = ' , convert(varchar(1),null) [_RecordModiType], convert(int,null) [_IndexOrderKey] '
			 end
		 else
			 begin
						-- 1076, 1077 = Stats
--			    if @QueryTemplateID in (1076,1077,1080,1095,1099,1103,1104) or @QueryTypeID = 24 or @QuerySourceID = 2   -- Queries without  ModificationType
				if @HasNoModiType = 1
					begin
						if @OrderClause > ''
							set @OrderIndexCol = ' , convert(varchar(1),null) [_RecordModiType] , ROW_NUMBER() over ( order by ' + @OrderClause + ') [_IndexOrderKey] '
						else
							set @OrderIndexCol = ' , convert(varchar(1),null) [_RecordModiType], convert(int,null) [_IndexOrderKey] '
					end
				else
					begin
						if @OrderClause > ''
							set @OrderIndexCol = ' , ModificationType [_RecordModiType], ROW_NUMBER() over ( order by ' + @OrderClause + ') [_IndexOrderKey] '
						else
							set @OrderIndexCol = ' , ModificationType [_RecordModiType], convert(int,null) [_IndexOrderKey] '
					end
			end


	insert @LayoutmParts (FromClause
						, FieldList1
						, FieldList2, FieldList3, FieldList4
						, IntoClause
						, OrderIndex
						, ClauseFrameWork)

		select case when @JobStepID is not null then @WorkDB + '..' + @SrcTable
						else @WorkDB + '..TestXForm_' + ltrim(str(@XFormTempID)) + ' x '
					end FromClause
				, case when @LayoutFieldID is not null then @LayoutFieldSrc
						else ltrim(substring(@FieldList1,3,len(@FieldList1)))
					end FieldList1
				, case when @LayoutFieldID is not null then '' 
						else @FieldList2 
					end FieldList2
				, case when @LayoutFieldID is not null then ''
						else @FieldList3 
					end FieldList3					
				, case when @LayoutFieldID is not null then ''
						else @FieldList4 
					end FieldList4					
				, case when @JobStepID is not null then 'into ' + @WorkDB + '..' + @DestTable
						when coalesce(ltrim(@FromClause),'') = '' then ''
						else ''
					end IntoClause
			    , case when @JobStepID is not null then @OrderIndexCol else '' end
				, case when @JobStepID is not null then
							'select #FieldList1# #FieldList2# #FieldList3# #FieldList4# #IndexCol# #IntoClause# From #FromClause# '
						when @LayoutFieldID is not null then 
							'select top 100 #FieldList1# From #FromClause# '
						else 
							'select #FieldList1# #FieldList2# #FieldList3# #FieldList4# From #FromClause# '
					end ClauseFrameWork


	RETURN

end
