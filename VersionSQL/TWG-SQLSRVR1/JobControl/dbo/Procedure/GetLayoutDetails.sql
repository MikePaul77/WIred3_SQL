/****** Object:  Procedure [dbo].[GetLayoutDetails]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetLayoutDetails @LayoutID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @ViewName varchar(100)
	declare @extname varchar(50) = 'TWG_Description'
	declare @LongName varchar(500)
	declare @ShortName varchar(500)

	select @ViewName = qt.FromPart
			, @LongName = fl.Description
			, @ShortName = fl.ShortFileLayoutName
		from JobControl..FileLayouts fl
			join JobControl..TransformationTemplates tt on tt.Id = fl.TransformationTemplateId
			join JobControl..QueryTemplates qt on qt.Id = tt.QueryTemplateID
		where fl.ID = @LayoutID

	CREATE TABLE #ViewInfo(
		[ViewColName] [varchar](128) NULL,
		[SourceDB] [varchar](128) NULL,
		[SourceTable] [varchar](128) NULL,
		[SourceColName] [varchar](128) NULL,
		[ColType] [varchar](128) NULL,
		[ViewColDescrip] [varchar] (max) NULL,
		[SourceColDescrip] [varchar] (max) NULL,
		[ColIDA] int null,
		[ColIDB] int null

	) 

	INSERT INTO #ViewInfo
	select ViewColName, SourceDB, SourceTable, SourceColName, ColType, ViewColDescrip
		, SourceColDescrip, ColIDA, ColIDB
	from Support..DataDictionary
		where SrcName = @ViewName
	--exec TWG_PropertyData_Rep..GetViewDataDic @ViewName

	create table #OtherInfo(
		DBName varchar(100) NULL,
		TblName varchar(100) NULL,
		TblAlias varchar(50) NULL
	)

	create table #OtherColumns(
		DBName varchar(100) NULL,
		TblName varchar(100) NULL,
		ColName varchar(100) null,
		ColType varchar(50) null,
		ColDescip varchar(max) null
	)

	INSERT INTO #OtherInfo
		select z.*
		from (
			select Support.FuncLib.GetSplitSeg(x.FullVal,'|',1) DB
				, Support.FuncLib.GetSplitSeg(x.FullVal,'|',2) Tbl
				, Support.FuncLib.GetSplitSeg(x.FullVal,'|',3) Alias
				from (
				select FL.ID LayoutID
					, replace(replace(replace(ltrim(support.FuncLib.StringFromTo(fct.Value,null,'on',1)),'..','|'),'.dbo.','|') ,' ','|') FullVal
					from JobControl..FileLayouts fl
						join JobControl..TransformationTemplates tt on tt.Id = fl.TransformationTemplateId
						join JobControl..QueryTemplates qt on qt.Id = tt.QueryTemplateID
						cross apply Support.FuncLib.SplitString(tt.TransformJoinClause,'join') fct
					where fct.seq > 1
						and tt.TransformJoinClause > ''
						and FL.ID = @LayoutID
				) x
			) z
		where z.Alias is not null
			and z.DB not like '(%'
		and z.DB > ''

	--select * from #ViewInfo
	--	order by ViewColName

	insert #OtherColumns
		select 'Lookups' 
			, tab.name as table_name
			, col.name as column_name
			, t.name + case when t.name in ('nvarchar', 'nchar','varchar', 'char') then '('
							+ case when t.name in ('nvarchar', 'nchar') then ltrim(str(col.max_length / 2)) else ltrim(str(col.max_length)) end + ')'
							else '' end
			, convert(varchar(max), ep.value)
		from lookups.sys.tables as tab
			inner join lookups.sys.columns as col on tab.object_id = col.object_id
			left join lookups.sys.types as t on col.user_type_id = t.user_type_id
			LEFT OUTER JOIN lookups.sys.extended_properties ep ON ep.major_id = col.object_id AND ep.minor_id = col.column_id and ep.name = @extname

	--select * 
	--	from #OtherInfo oi
	--		join #OtherColumns oc on oi.DBName = oc.DBName and oi.TblName = oc.TblName

	select flf.OutOrder
			, flf.OutName
            , coalesce(flf.OutWidth,0) OutWidth
			, case when flf.OutWidth > 0 and fs.EndPosition is not null then
					fs.EndPosition - flf.OutWidth + 1
				else 0 end StartPos
			, fs.EndPosition EndPos
			, flf.SrcName
			, coalesce(flf.Hide,0) Hide
			, ttc.SourceCode
			, coalesce(vi.ViewColName,vi2.ViewColName) ViewColName
			, coalesce(vi.SourceDB, ot.DBName) SourceDB
			, coalesce(vi.SourceTable, ot.TblName) SourceTable
			, coalesce(vi.SourceColName, ot.ColName) SourceColName
			, coalesce(vi.ColType, ot.ColType) ColType
			, coalesce(vi.ViewColDescrip,vi2.ViewColDescrip) ViewColDescrip
			, coalesce(vi.SourceColDescrip,vi2.SourceColDescrip) SourceColDescrip
			, coalesce(vi.ColIDA,vi2.ColIDA) ColIDA
			, coalesce(vi.ColIDB,vi2.ColIDB) ColIDB
			, ot.ColDescip
			, flf.FieldDescrip + case when TWGLUs.LookupID > 0 then '  >>>  See Lookup ' + TWGLUs.Lookup
										when FALUs.ID > 0 then '  >>>  See Lookup ' + FALUs.UCodeType else '' end FieldDescrip
			, ltrim(rtrim(case when flf.CaseChange <> 'None' and flf.CaseChange > '' then 'To ' + Support.FuncLib.ProperCase(flf.CaseChange) + 'case' else '' end
				+ ' '
				+ case when flf.Padding > '' then 'Pad ' + Support.FuncLib.ProperCase(flf.Padding) + ' w/ ' + ltrim(str(flf.PaddingLength)) + ' '
						+ case when PaddingChar = '0' then 'Zeros' when PaddingChar = ' ' then 'Spaces' else PaddingChar end
				  else '' end
				+ ' '
				 + case when flf.LayoutFormatID > 0 then lf.FormatExample else '' end)) ShowFormat
			, coalesce(FutureUse,0) FutureUse
			, ldt.FullName DataType
		into #Final
		from JobControl..FileLayoutFields flf
			join JobControl..FileLayouts fl on fl.Id = flf.FileLayoutID
			join JobControl..TransformationTemplates tt on tt.Id = fl.TransformationTemplateId
			left outer join JobControl..QueryTemplates qt on qt.Id = tt.QueryTemplateID
			left outer join JobControl..LayoutFormats lf on lf.ID = flf.LayoutFormatID
			left outer join JobControl..LayoutDataTypes ldt on ldt.ID = coalesce(flf.DataTypeID,1)
			join (select RecID
					, OutOrder
					--, OutType
					, OutWidth
					, sum(OutWidth) over (order by OutOrder) EndPosition
					from JobControl..FileLayoutFields
					where FileLayoutID = @LayoutID 
				) fs on fs.RecID = flf.RecID
			left outer join JobControl..TransformationTemplateColumns ttc on 'XF_' + ttc.OutName = FLF.SrcName and coalesce(ttc.Disabled,0) = 0
																					and ttc.TransformTemplateID = fl.TransformationTemplateId
			--left outer join #ViewInfo vi on flf.SrcName = vi.ViewColName
			--								or flf.SrcName like '%.' + vi.ViewColName
			--								or (ttc.SourceCode + ' ' like '%.' + vi.ViewColName + '[ ,)=><]%' and ttc.SourceCode not like 'iif%')
			--								--or flf.SrcName = vi.SourceColName
			--								or flf.SrcName like '%.' + vi.SourceColName
			--								or (ttc.SourceCode + ' ' like '%.' + vi.SourceColName + '[ ,)=><]%' and ttc.SourceCode not like 'iif%')


			left outer join #ViewInfo vi on flf.SrcName = vi.ViewColName
												or flf.SrcName like '%.' + vi.ViewColName
												or (ttc.SourceCode + ' ' like '%.' + vi.ViewColName + '[ ,)=><]%' and Jobcontrol.dbo.CountAppearances(ttc.SourceCode,'x.') < 2)
			left outer join #ViewInfo vi2 on vi.ViewColName is null and (flf.SrcName = vi2.ViewColName
												or flf.SrcName like '%.' + vi2.SourceColName
												or (ttc.SourceCode + ' ' like '%.' + vi2.SourceColName + '[ ,)=><]%' and Jobcontrol.dbo.CountAppearances(ttc.SourceCode,'x.') < 2))



			left outer join (select oc.DBName, oc.TblName, oc.ColName, oc.ColDescip, oc.ColType, oi.TblAlias + '.' + oc.ColName AliasCol
								from #OtherInfo oi
									join #OtherColumns oc on oi.DBName = oc.DBName and oi.TblName = oc.TblName
							) ot on ttc.SourceCode like '%' + ot.AliasCol + '%'
			left outer join (select cs.id, ct.UCodeType
								from UniversalCodeMapper..CodeSources cs
									join UniversalCodeMapper..CodeTypes ct on ct.ID = cs.TypeID
								where ProviderID = 2 ) FALUs on FALUs.ID = flf.LookupID and qt.SourceCompany = 'FA'
			left outer join (select distinct Lookup, LookupID from Lookups..vAllLookups) TWGLUs on TWGLUs.LookupID = flf.LookupID and qt.SourceCompany = 'TWG'
		where FileLayoutID = @LayoutID
			and coalesce(flf.Disabled,0) = 0


--basic, detail, wDic

	--if @DetailTypeID = 1	--'Basic'
	--	select distinct OutOrder, OutName
	--		from #Final
	--	order by OutOrder

	--if @DetailTypeID = 2	--'Detail'
	--	select distinct OutOrder, OutName, OutWidth, StartPos, EndPos
	--		from #Final
	--	order by OutOrder

	--if @DetailTypeID = 3	--'BasicwDic'
	--select x.*, z.TWGDataDesc
	--	from (
	--		select distinct OutOrder, OutName
	--			from #Final
	--		) x
	--	left outer join (
	--		select distinct OutOrder, OutName
	--			, coalesce(ViewColDescrip, SourceColDescrip, ColDescip) TWGDataDesc
	--		from #Final
	--		where coalesce(ViewColDescrip, SourceColDescrip, ColDescip) is not null
	--		) z on z.OutOrder = x.OutOrder and z.OutName = x.OutName

	--	order by OutOrder

	--if @DetailTypeID = 4	--'DetailwNotes'
	--	select distinct OutOrder, OutName, OutWidth, StartPos, EndPos, FieldDescrip
	--		from #Final
	--	order by OutOrder

	--if @DetailTypeID = 5	--'Everything'
	select x.*, z.TWGDataDesc, @LongName LayoutLongName, @ShortName LayoutShortName, z.TWGDataDescPreLayout
		from (
			select distinct OutOrder, OutName, OutWidth, StartPos, EndPos, Hide, FieldDescrip, ShowFormat, SourceCode, FutureUse, DataType
				from #Final
			) x
		left outer join (
			select OutOrder, OutName, TWGDataDesc, TWGDataDescPreLayout
				from (
					select distinct OutOrder, OutName
						, case when FieldDescrip > '' then FieldDescrip
								when ViewColDescrip > '' then ViewColDescrip
								when SourceColDescrip > '' then SourceColDescrip
								when ColDescip > '' then ColDescip
								else '' end TWGDataDesc
						, case when ViewColDescrip > '' then ViewColDescrip
								when SourceColDescrip > '' then SourceColDescrip
								when ColDescip > '' then ColDescip
								else '' end TWGDataDescPreLayout
						, RankNum = ROW_NUMBER() OVER (PARTITION BY OutOrder, OutName ORDER BY ColIDA, ColIDB)
					from #Final
					where case when FieldDescrip > '' then FieldDescrip
								when ViewColDescrip > '' then ViewColDescrip
								when SourceColDescrip > '' then SourceColDescrip
								when ColDescip > '' then ColDescip
								else '' end is not null
				) zz
				where zz.RankNum = 1
			) z on z.OutOrder = x.OutOrder and z.OutName = x.OutName

		order by OutOrder


	--if @DetailTypeID = 6	--'DetailwSrc'
	--	select distinct OutOrder, OutName, OutWidth, StartPos, EndPos
	--			, SrcName, SourceCode, ViewColName
	--			, SourceDB, SourceTable, SourceColName
	--			, ColType
	--		from #Final
	--	order by OutOrder


	--if @DetailTypeID = 7	--'All'
	--	select distinct 
	--			OutOrder
	--			, OutName
	--			, OutWidth
	--			, StartPos
	--			, EndPos
	--			, SrcName
	--			, SourceCode
	--			, ViewColName
	--			, SourceDB
	--			, SourceTable
	--			, SourceColName
	--			, ColType
	--			, ViewColDescrip
	--			, SourceColDescrip
	--			, ColDescip
	--		from #Final
	--	order by OutOrder




END
