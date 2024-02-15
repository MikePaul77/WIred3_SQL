/****** Object:  ScalarFunction [dbo].[AutoXFormLayoutName]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.AutoXFormLayoutName
(
	@XFromID int, @LayoutID int
)
RETURNS varchar(200)
AS
BEGIN
	
	DECLARE @Result varchar(200)

	set @Result = ''

	select @Result = case when @XFromID > 0 then x.XFormName
						else x.LayoutName end
		from (
			select top 1 tt.ID XFormID
					, case when tt.QueryTemplateID = -1 then 'XFGroupBy'
							when tt.QueryTemplateID = -2 then 'XFPivot'
							when tt.QueryTemplateID = -3 then 'XFControlFile'
							when tt.QueryTemplateID = -4 then 'XFPassThrough'
						else coalesce(qs.ShortName,'UnkSrc') 
							+ '_' + 
								case when qyt.ReqDataType > '' then replace(replace(qyt.ReqDataType,'&',''),' ','')
									when qyt.QueryTypeID > 0 then 'Cust'
									else 'UNkDT' end

						end	
						
						+ coalesce('_' + tt.CustNamePart,'') 
						+ case when tt.MasterXForm = 1 then '_M' + ltrim(str(tt.ID)) + 'v' + ltrim(str(coalesce(tt.MasterVersion,1)))
													else '_T' + ltrim(str(tt.ID)) + '_M' + ltrim(str(coalesce(tt.SourceMasterXFormID,0))) +'v' + ltrim(str(coalesce(tt.SourceMasterXFormVersion,0))) end
						+ case when tt.MasterXForm = 1 then '_Prim' 
							else '' end XFormName
					, fl.ID LayoutID
					, coalesce(fl.CustNamePart + '_','') + 'L' + ltrim(str(fl.ID)) + case when fl.DefaultLayout = 1 then '_Def' else '' end LayoutName
				from JobControl..TransformationTemplates tt
					left outer join JobControl..QueryTemplates qt on qt.Id = tt.QueryTemplateID
					left outer join JobControl..QueryTypes qyt on qyt.QueryTypeID = qt.QueryTypeID
					left outer join JobControl..QuerySources qs on qs.ID = qyt.QuerySourceID
					left outer join JobControl..FileLayouts fl on fl.TransformationTemplateId = tt.Id
				where case when fl.ID > 0 and fl.Id = @LayoutID then 1 
							when tt.ID > 0 and tt.Id = @XFromID then 1 
						else 0 end = 1
			) x

	RETURN @Result

END
