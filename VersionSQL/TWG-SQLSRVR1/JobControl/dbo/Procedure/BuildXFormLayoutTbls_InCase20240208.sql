/****** Object:  Procedure [dbo].[BuildXFormLayoutTbls_InCase20240208]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.BuildXFormLayoutTbls_InCase20240208 @JobStepID int, @FieldMode varchar(20), @debug bit
as
BEGIN
	SET NOCOUNT ON;

		declare @FromClause varchar(max), @WhereClause varchar(max), @JoinClause varchar(max), @IntoClause varchar(max), @SourceFields varchar(max), @OrderIndex varchar(max)
		declare @FieldList1 varchar(max), @FieldList2 varchar(max), @FieldList3 varchar(max), @FieldList4 varchar(max), @FieldList5 varchar(max), @FieldList6 varchar(max), @ClauseFrameWork varchar(max)
		declare @cmd  varchar(max)
		declare @ncmd nvarchar(max)
		declare @rowcnt int

		declare @XFormDistinct bit = 0

		select @XFormDistinct = coalesce(js.XFormDistinct,0)
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

		declare @DistOps varchar(50) = ''

		if @XFormDistinct = 1
		begin
			set @DistOps = ' distinct '
			set @OrderIndex = ''
		end

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
			print 'select ' + @DistOps + ' ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' ' + @OrderIndex + ' ' + @IntoClause + ' from ' + @FromClause + ' x'
			print '---------------Run---------------------'
		end

		exec('select ' + @DistOps + ' ' + @FieldList1 + ' ' + @FieldList2 + ' ' + @FieldList3 + ' ' + @FieldList4 + ' ' + @OrderIndex + ' ' + @IntoClause + ' from ' + @FromClause + ' x')

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
