/****** Object:  Procedure [dbo].[VFP_XFORM_W3Build]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFP_XFORM_W3Build @XFORM varchar(50), @create bit
AS
BEGIN
	SET NOCOUNT ON;

declare @XFORM2 varchar(50)
declare @TransformTemplateID int , @FileLayoutID int
if @create is null
	set @create = 0

if @create = 1
	begin
		insert JobControl..TransformationTemplates (ShortTransformationName, Description)
		select xform, val from VFP_XFORMOpts where XFORM = @XFORM and opt = 'Title'

		select @TransformTemplateID = max(id) from TransformationTemplates where ShortTransformationName = @XFORM

		insert JobControl..FileLayouts (TransformationTemplateId, ShortFileLayoutName, Description)
		select @TransformTemplateID, xform, val from VFP_XFORMOpts where XFORM = @XFORM and opt = 'Title'

		select @FileLayoutID = max(id) from FileLayouts where TransformationTemplateId = @TransformTemplateID
	end
else
	begin

		select @TransformTemplateID = max(id) from TransformationTemplates where ShortTransformationName = @XFORM

		select @FileLayoutID = max(id) from FileLayouts where TransformationTemplateId = @TransformTemplateID

	end 

if @TransformTemplateID is null
	set @TransformTemplateID = -1

if @FileLayoutID is null
	set @FileLayoutID = -1

-- Options
select '#### Options based on ' + @XFORM + ' ####' [VFP XFORM Options]
select * from VFP_XFORMOpts where XFORM = @XFORM and val > ''

select @XFORM2 = replace(val,'.DBF','') from VFP_XFORMOpts where XFORM = @XFORM and opt = 'template'

-- Full Fields
select '#### XForm fields for ' + @XFORM + '/' + @XFORM2 + ' ####' [VFP XFORM / Template]
select x.FieldName, x.FieldOrder, x.FieldType, x.width, x.Dec, o.OutSrc 
	from VFP_XFORMXLate o
		left outer join VFP_XFORMShells x on o.OutName = x.FieldName
	where o.XFORM = @XFORM and x.XForm = @XFORM2
	order by x.FieldOrder

if @create = 1
	begin
		-- TransformationTemplateColumns
		insert JobControl..TransformationTemplateColumns (TransformTemplateID, OutName, VFPSourceCode)
			select @TransformTemplateID, dbo.VFP_XFORMW3FieldRename(x.FieldName), o.OutSrc
				from VFP_XFORMXLate o
					left outer join VFP_XFORMShells x on o.OutName = x.FieldName
				where o.XFORM = @XFORM and x.XForm = @XFORM2
					and x.FieldName <> o.OutSrc
				order by x.FieldOrder

		--FileLayoutFields
		insert JobControl..FileLayoutFields (FileLayoutID, OutOrder, OutType, OutWidth, SrcName, OutName)
			select @FileLayoutID, x.FieldOrder * 10
							, case when x.FieldType = 'Integer' then 'int'
									when x.FieldType in ('Numeric','Double','Float') then 'decimal'
									else 'text' end
							, convert(int,x.width) + case when x.Dec > '' then convert(int,x.Dec) else 0 end
							, case when x.FieldName <> o.OutSrc then 'XF_' + x.FieldName else dbo.VFP_XFORMW3FieldRename(x.FieldName) end
							, x.FieldName 
						from VFP_XFORMXLate o
							left outer join VFP_XFORMShells x on o.OutName = x.FieldName
						where o.XFORM = @XFORM and x.XForm = @XFORM2
						order by x.FieldOrder
	end
select '#### ' + case when @TransformTemplateID > -1 then 'Was' else 'Would' end  + ' be inserted into TransformationTemplateColumns ####' [Action]

	if @TransformTemplateID > -1
	begin
		select @TransformTemplateID TransformTemplateID, dbo.VFP_XFORMW3FieldRename(x.FieldName) OutName, o.OutSrc VFPSourceCode
				,'### --> Actual --> ###'
				, atc.* 
			from VFP_XFORMXLate o
				left outer join VFP_XFORMShells x on o.OutName = x.FieldName
				full outer join TransformationTemplateColumns atc on atc.TransformTemplateID = @TransformTemplateID and atc.OutName = x.FieldName
			where o.XFORM = @XFORM and x.XForm = @XFORM2
				and x.FieldName <> o.OutSrc
			order by x.FieldOrder

		update JobControl..TransformationTemplates set ShortTransformationName = ShortTransformationName  + ' (Imported)' where id = @TransformTemplateID

	end
	else
	begin
		select @TransformTemplateID TransformTemplateID, dbo.VFP_XFORMW3FieldRename(x.FieldName) OutName, o.OutSrc VFPSourceCode
			from VFP_XFORMXLate o
				left outer join VFP_XFORMShells x on o.OutName = x.FieldName
			where o.XFORM = @XFORM and x.XForm = @XFORM2
				and x.FieldName <> o.OutSrc
			order by x.FieldOrder
	end


select '#### ' + case when @FileLayoutID > -1 then 'Was' else 'Would' end  + ' be inserted into FileLayoutFields ####' [Action]

	if @FileLayoutID > -1
	begin	
			select @FileLayoutID FileLayoutID, x.FieldOrder * 10 OutOrder
							, case when x.FieldType = 'Integer' then 'int'
									when x.FieldType in ('Numeric','Double','Float') then 'decimal'
									else 'text' end OutType
							, convert(int,x.width) + case when x.Dec > '' then convert(int,x.Dec) else 0 end OutWidth
							, case when x.FieldName <> o.OutSrc then 'XF_' + x.FieldName else dbo.VFP_XFORMW3FieldRename(x.FieldName) end SrcName
							, x.FieldName OutName
							,'### --> Actual --> ###'
							, afl.* 
						from VFP_XFORMXLate o
							left outer join VFP_XFORMShells x on o.OutName = x.FieldName
							full outer join FileLayoutFields afl on afl.FileLayoutID = @FileLayoutID and afl.OutName = x.FieldName
						where o.XFORM = @XFORM and x.XForm = @XFORM2
						order by x.FieldOrder

	end
	else
	begin
			select @FileLayoutID FileLayoutID, x.FieldOrder * 10 OutOrder
							, case when x.FieldType = 'Integer' then 'int'
									when x.FieldType in ('Numeric','Double','Float') then 'decimal'
									else 'text' end OutType
							, convert(int,x.width) + case when x.Dec > '' then convert(int,x.Dec) else 0 end OutWidth
							, case when x.FieldName <> o.OutSrc then 'XF_' + x.FieldName else dbo.VFP_XFORMW3FieldRename(x.FieldName) end SrcName
							, x.FieldName OutName
						from VFP_XFORMXLate o
							left outer join VFP_XFORMShells x on o.OutName = x.FieldName
						where o.XFORM = @XFORM and x.XForm = @XFORM2
						order by x.FieldOrder	
	end

END
