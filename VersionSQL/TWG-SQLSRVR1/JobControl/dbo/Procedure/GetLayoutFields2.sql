/****** Object:  Procedure [dbo].[GetLayoutFields2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetLayoutFields2 @LayoutID int, @FieldRecID int
AS
BEGIN
	SET NOCOUNT ON;

	set @LayoutID = coalesce(@LayoutID,0)
	set @FieldRecID = coalesce(@FieldRecID,0)


	declare @ViewName varchar(100)
	declare @extname varchar(50) = 'TWG_Description'

	select @ViewName = qt.FromPart
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


	select distinct x.*
			, case when coalesce(vi.ViewColDescrip,vi2.ViewColDescrip) > '' then coalesce(vi.ViewColDescrip,vi2.ViewColDescrip)
								when coalesce(vi.SourceColDescrip,vi2.SourceColDescrip) > '' then coalesce(vi.SourceColDescrip,vi2.SourceColDescrip)
								when ot.ColDescip > '' then ot.ColDescip
								else '' end TWGDataDescPreLayout
	        from (
        select RecID
	        , OutOrder
	        , SortOrder
	        , SortDir
	        --, OutType
	        , OutWidth
	        , sum(case when coalesce(Disabled, 0) = 0 then OutWidth else 0 end) over (order by OutOrder) EndPosition
	        , SrcName
	        , OutName
	        , coalesce(Disabled, 0) Disabled
	        , coalesce(FutureUse, 0) FutureUse
	        , CaseChange
	        , coalesce(DoNotTrim, 0) DoNotTrim
	        , coalesce(Padding, 'None') Padding
	        , PaddingLength
	        , PaddingChar
	        , coalesce(XLNoFormat, 0) XLNoFormat
	        , XLAlign
	        , coalesce(Hide, 0) Hide
			, coalesce(LayoutFormatID, 0) LayoutFormatID
			, coalesce(FieldDescrip,'') FieldDescrip
			, coalesce(ConformToWidth, 0) ConformToWidth
			, coalesce(IgnoreDataTruncation, 0) IgnoreDataTruncation
			, FileLayoutID
			, coalesce(DataTypeID,0) DataTypeID
			, coalesce(LookupID,0) LookupID
	        from JobControl..FileLayoutFields 
	        where FileLayoutID = @LayoutID 
		        or FileLayoutID = (select FileLayoutID from JobControl..FileLayoutFields where RecID = @FieldRecID)
        ) x
		join JobControl..FileLayouts fl on fl.Id = x.FileLayoutID
		left outer join JobControl..TransformationTemplateColumns ttc on 'XF_' + ttc.OutName = x.SrcName and coalesce(ttc.Disabled,0) = 0
																				and ttc.TransformTemplateID = fl.TransformationTemplateId

		---- two commented out lines below cause dups not sure they are needed 2/10/23 Mike P
		--left outer join #ViewInfo vi on x.SrcName = vi.ViewColName
		--									or x.SrcName like '%.' + vi.ViewColName
		--									--or ttc.SourceCode + ' ' like '%.' + vi.ViewColName + '[ ,)=><]%'   
		--									--or x.SrcName = vi.SourceColName    -- Mike P 6/29/23 removed this was causing dups when view field and source field are same
		--									or x.SrcName like '%.' + vi.SourceColName
		--									--or ttc.SourceCode + ' ' like '%.' + vi.SourceColName + '[ ,)=><]%'

		left outer join #ViewInfo vi on x.SrcName = vi.ViewColName
											or x.SrcName like '%.' + vi.ViewColName
											or (ttc.SourceCode + ' ' like '%.' + vi.ViewColName + '[ ,)=><]%' and Jobcontrol.dbo.CountAppearances(ttc.SourceCode,'x.') < 2)
		left outer join #ViewInfo vi2 on vi.ViewColName is null and (x.SrcName = vi2.ViewColName
											or x.SrcName like '%.' + vi2.SourceColName
											or (ttc.SourceCode + ' ' like '%.' + vi2.SourceColName + '[ ,)=><]%' and Jobcontrol.dbo.CountAppearances(ttc.SourceCode,'x.') < 2))


		left outer join (select oc.DBName, oc.TblName, oc.ColName, oc.ColDescip, oc.ColType, oi.TblAlias + '.' + oc.ColName AliasCol
								from #OtherInfo oi
									join #OtherColumns oc on oi.DBName = oc.DBName and oi.TblName = oc.TblName
							) ot on ttc.SourceCode like '%' + ot.AliasCol + '%'


	order by x.OutOrder

END
