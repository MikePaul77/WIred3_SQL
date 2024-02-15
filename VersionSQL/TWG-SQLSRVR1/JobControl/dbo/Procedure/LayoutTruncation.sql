/****** Object:  Procedure [dbo].[LayoutTruncation]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE LayoutTruncation @LayoutMode int, @FileLayoutID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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

END
