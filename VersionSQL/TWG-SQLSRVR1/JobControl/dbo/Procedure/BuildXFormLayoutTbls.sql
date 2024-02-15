/****** Object:  Procedure [dbo].[BuildXFormLayoutTbls]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.BuildXFormLayoutTbls @JobStepID int, @FieldMode varchar(20), @debug bit
as
BEGIN
	SET NOCOUNT ON;

		declare @FromClause varchar(max), @WhereClause varchar(max), @JoinClause varchar(max), @IntoClause varchar(max), @SourceFields varchar(max), @OrderIndex varchar(max)
		declare @FieldList1 varchar(max), @FieldList2 varchar(max), @FieldList3 varchar(max), @FieldList4 varchar(max), @FieldList5 varchar(max), @FieldList6 varchar(max), @ClauseFrameWork varchar(max)
		declare @cmd  varchar(max)
		declare @ncmd nvarchar(max)
		declare @rowcnt int

		declare @XFormDistinct bit = 0
		declare @FileLayoutID int = 0 

		select @XFormDistinct = coalesce(js.XFormDistinct,0)
				, @FileLayoutID = js.FileLayoutID
		from JobControl..JobSteps js
		where js.StepID = @JobStepID

			select @FromClause = FromClause
				, @IntoClause = IntoClause
				, @FieldList1 = FieldList1
				, @FieldList2 = FieldList2
				, @FieldList3 = FieldList3
				, @FieldList4 =  FieldList4
				, @OrderIndex =  OrderIndex
				, @ClauseFrameWork = ClauseFrameWork
			from JobControl.dbo.LayoutSQLParts(@JobStepID, null, null, @FieldMode)

		--select #FieldList1# #FieldList2# #FieldList3# #FieldList4# #IndexCol# #IntoClause# From #FromClause# 

		set @cmd = 'IF OBJECT_ID(''' + replace(@IntoClause,'Into ','') + ''', ''U'') IS not NULL drop TABLE ' + replace(@IntoClause,'Into ','') + ' '
		if @debug = 1
			print @cmd
		exec(@cmd)

		--declare @DistOps varchar(50) = ''

		--if @XFormDistinct = 1
		--begin
		--	set @DistOps = ' distinct '
		--	set @OrderIndex = ''
		--end

		if @debug = 1
		begin
			print '---------------Layout-Start---------------------'
			print '---------------@FieldList1---------------------'
			print @FieldList1
			print '---------------@FieldList2---------------------'
			print @FieldList2
			print '---------------@FieldList3---------------------'
			print @FieldList3
			print '---------------@FieldList4---------------------'
			print @FieldList4
			print '---------------@OrderIndex---------------------'
			print @OrderIndex
			print '---------------@IntoClause---------------------'
			print @IntoClause
			print '---------------@FromClause---------------------'
			print @FromClause
			print '---------------Combined---------------------'
			print 'select ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' ' + @OrderIndex + ' ' + @IntoClause + ' from ' + @FromClause + ' x'
			print '---------------Run---------------------'
		end

		if @XFormDistinct = 1
		begin

			declare @AdjOrderIndex varchar(500) = ''

			declare @SpecialOrderClause varchar(2000), @OrderIndexCol varchar(2000), @SortDir varchar(10), @sep varchar(10), @FldSrc varchar(1000)
			set @SpecialOrderClause = ''
			set @sep = ''

			 DECLARE TransTempCol CURSOR FOR

				SELECT OutName FldSrc
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
						and coalesce(Hide,0) = 0
					order by SortOrder

			 OPEN TransTempCol

			 FETCH NEXT FROM TransTempCol into @FldSrc, @SortDir
			 WHILE (@@FETCH_STATUS <> -1)
			 BEGIN

					--set @OrderClause = @OrderClause + @sep + @FldSrc + ' ' + @SortDir
					set @SpecialOrderClause = @SpecialOrderClause + @sep + @FldSrc + ' ' + iif(@SortDir='0','asc', @SortDir) -- Added 10/20/2018 - Mark W.
					set @sep = ','

				  FETCH NEXT FROM TransTempCol into @FldSrc, @SortDir
			 END
			 CLOSE TransTempCol
			 DEALLOCATE TransTempCol

			 if @SpecialOrderClause > ''
				set @AdjOrderIndex = ' , ROW_NUMBER() over ( order by ' + @SpecialOrderClause + ') [_IndexOrderKey] '


			print 'select ds.* ' + @AdjOrderIndex + ' ' +  @IntoClause + ' from ( select distinct ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' from ' + @FromClause + ' x ) ds'
			print '---------------Run---------------------'

			exec('select ds.* ' + @AdjOrderIndex + ' ' +  @IntoClause + ' from ( select distinct ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' from ' + @FromClause + ' x ) ds')
		end
		else
		begin

			print 'select ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' ' + @OrderIndex + ' ' + @IntoClause + ' from ' + @FromClause + ' x'
			print '---------------Run---------------------'

			exec('select ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' ' + @OrderIndex + ' ' + @IntoClause + ' from ' + @FromClause + ' x')
		end

		--set @cmd = 'IF OBJECT_ID(''' + replace(@IntoClause,'Into ','') + ''', ''U'') IS not NULL
		--			insert JobStepLog (JobId, JobStepID, LogStamp, LogInformation, LogInfoType, LogInfoSource )
		--			select JobID, StepID, getdate(), (select count(*) from ' + replace(@IntoClause,'Into ','') + '), 1, ''StepRecordCount''
		--					from JobSteps where StepID = ' + ltrim(str(@JobStepID))
		--exec(@cmd)

		exec JobControl..AppendTotals @JobStepID, @FieldMode

		set @ncmd = 'select @cnt = count(*) from ' + replace(@IntoClause,'Into ','')
		execute sp_executesql @ncmd,N'@cnt int OUTPUT', @cnt=@rowcnt OUTPUT

		set @cmd = 'IF OBJECT_ID(''' + replace(@IntoClause,'Into ','') + ''', ''U'') IS not NULL
					exec JobControl..JobStepLogInsert ' + ltrim(str(@JobStepID)) + ',1, ''' + ltrim(str(@rowcnt)) + ''',''LayoutRecordCount'''
		exec(@cmd)

		set @cmd = 'IF OBJECT_ID(''' + replace(@IntoClause,'Into ','') + ''', ''U'') IS not NULL
					exec JobControl..JobStepLogInsert ' + ltrim(str(@JobStepID)) + ',1, ''' + ltrim(str(@rowcnt)) + ''',''StepRecordCount'''
		exec(@cmd)

		if @debug = 1
		begin
			print '---------------Layout-End---------------------'
		end


END
