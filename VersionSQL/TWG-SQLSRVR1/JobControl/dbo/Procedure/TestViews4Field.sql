/****** Object:  Procedure [dbo].[TestViews4Field]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.TestViews4Field @Field varchar(100), @exact bit
AS
BEGIN
	SET NOCOUNT ON;

	select b.name ColumnName, QTs.ViewName Source, QTs.Id, AltFields.AltName, AltFields.MultiSelect
        from (
			select QT.ID, QT.TemplateName, s.Value + '..' + qt.FromPart FromPart, QT2.QueryTypeName, QT.FromPart ViewName
				from QueryTemplates QT
					left outer join QueryTypes QT2 on QT2.QueryTypeID = QT.QueryTypeID
					join JobControl..Settings s on s.Property = 'ReportDatabase'
				where coalesce(QT.disabled,0) = 0
			) QTs
		outer apply QueryEditor.dbo.GetAltFieldNames(QTs.Id, @Field, null) AltFields
		left outer join TWG_PropertyData.sys.all_objects a on QTs.ViewName = a.name and a.type='V'
		left outer join TWG_PropertyData.sys.all_columns b on a.object_id=b.object_id 
			and b.name like case when coalesce(@exact,1) = 1 then  coalesce(AltFields.AltName,@Field) else '%' + coalesce(AltFields.AltName,@Field) + '%' end

END
