/****** Object:  Procedure [dbo].[CheckDataTruncation]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.CheckDataTruncation @JobStepID int

-- into JC_Transform between Xform and layout
-- exec JobControl..CheckDataTruncation @JobStepID
 
AS
BEGIN
	SET NOCOUNT ON;

	declare @SrcTable varchar(100)
	declare @TruncTestTable varchar(100)
	declare @FileLayoutID int
	declare @JobID int
	declare @LayoutMode int
	declare @IgnoreDataTruncation bit
	declare @cmd varchar(max)
	declare @FieldMode varchar(10)

	select @SrcTable = jst.StepName + 'StepResultsA_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
			, @TruncTestTable = jst.StepName + 'TruncTest_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
			, @FileLayoutID = js.FileLayoutID
			, @JobID = js.JobID
			, @LayoutMode = coalesce(js.LayoutFormattingMode,1)
			, @IgnoreDataTruncation = coalesce(js.IgnoreDataTruncation,0)
			, @FieldMode = coalesce(fl.FieldMode,'')
		from JobSteps js 
			left outer join JobStepTypes jst on jst.StepTypeID = js.StepTypeID
			left outer join FileLayouts fl on fl.ID = js.FileLayoutID

		where js.StepID = @JobStepID

	declare @FldSrc varchar(500)
	declare @FldID int
	declare @OutName varchar(100)
	declare @OutWidth int
	declare @outorder int
	declare @padding varchar(20)
	declare @AdjSrc varchar(600)

	Declare @WorkDB varchar(50) = 'JobControlWork'

	if @IgnoreDataTruncation = 0 and @FieldMode <> 'BKI'
	begin

	set @cmd = 'drop table if exists ' + @WorkDB + '..' + @TruncTestTable
	exec(@cmd)

	set @cmd = 'create table ' + @WorkDB + '..' + @TruncTestTable + ' (FieldID int, MaxDataLength int)'
	exec(@cmd)

		 DECLARE LayoutTruncCur CURSOR FOR

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
							'coalesce(convert(varchar(1000)'
							+ ', ' + case when ltrim(SrcName) = '' then '''''' else '[' + SrcName + ']' end + '),'''')'
						else
							case when coalesce(outwidth,0) > 0 then
								'coalesce(convert(varchar(1000)'
								+ ', JobControl.dbo.ApplyLayoutFormat(' + case when ltrim(SrcName) = '' then '''''' else '[' + SrcName + ']' end + ',' + ltrim(str(LayoutFormatID)) + ')),'''')'
							else
								'coalesce(JobControl.dbo.ApplyLayoutFormat(' + case when ltrim(SrcName) = '' then '''''' else '[' + SrcName + ']' end + ',' + ltrim(str(LayoutFormatID)) + '),'''')'
							end
						end


					+ case when coalesce(DoNotTrim, 0) = 1 or @LayoutMode = 2 then '' else '))' end
					+ case when coalesce(Padding,'None') in ('Left','Right') then ',' + ltrim(str(coalesce(PaddingLength,outwidth))) + ',''' + right(PaddingChar,1) + ''')' else  '' end
					+ case when coalesce(CaseChange,'None') not in ('None','') then ')' else  '' end
					 end FldSrc
					, RecID
					, Padding

				FROM JobControl..FileLayoutFields
				where FileLayoutID  = @FileLayoutID
					and OutOrder is not null and coalesce(disabled,0) = 0
					and coalesce(Hide,0) = 0
					and coalesce(outwidth,0) > 0
					and coalesce(IgnoreDataTruncation,0) = 0
				order by outorder

		 OPEN LayoutTruncCur

		 FETCH NEXT FROM LayoutTruncCur into @FldSrc, @FldID, @Padding
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
			
			set @AdjSrc = case when @Padding = 'Left' then 'rtrim(' + @FldSrc + ')'
								else 'ltrim(rtrim(' + @FldSrc + '))' end

			set @cmd = 'insert ' + @WorkDB + '..' + @TruncTestTable + ' (FieldID, MaxDataLength)
						select ' + ltrim(str(@FldID)) + ', Max(Len(' + @AdjSrc + '))
							from ' + @WorkDB + '..' + @SrcTable
			print @cmd
			exec(@cmd)
			print '====================================='

			  FETCH NEXT FROM LayoutTruncCur into @FldSrc, @FldID, @Padding
		 END
		 CLOSE LayoutTruncCur
		 DEALLOCATE LayoutTruncCur

		 set @cmd = 'insert JobStepLog (JobId, JobStepID, LogStamp, LogInformation, LogInfoType, LogInfoSource )
			select ' + ltrim(str(@JobID)) + ', ' + ltrim(str(@JobStepID)) + ', getdate()
				, ''Layout Truncation '' + ltrim(str(f.OutOrder)) + '' - '' + OutName + '' Limit:'' + ltrim(str(f.OutWidth)) + '' Max:'' + ltrim(str(t.MaxDataLength)) + '' [ID:'' + ltrim(str(t.FieldID)) + '']''
				, case when IgnoreDataTruncation = 1 then 2 else 3 end
				, ''XForm CheckDataTruncation SP''
				from ' + @WorkDB + '..' + @TruncTestTable + ' t
					join JobControl..FileLayoutFields f on f.recid = t.Fieldid and f.FileLayoutID = ' + ltrim(str(@FileLayoutID)) + '
				where t.MaxDataLength > f.OutWidth
			order by f.OutOrder '

		print @cmd
		exec(@cmd)

		set @cmd = replace(@cmd,' JobStepLog ',' JobStepLogHist ')
		exec(@cmd)

		declare @TrunErrors int = 0

		select @TrunErrors = count(*)
			from JobStepLog
			where JobID = @JobID
				and JobStepID = @JobStepID
				and LogInfoType = 3
				and LogInformation like 'Layout Truncation %'

		if @TrunErrors > 0
		Begin
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
			RAISERROR ('Validation forced step failure', 16, 1)
		end

	end
END
