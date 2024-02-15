/****** Object:  Procedure [dbo].[GetBestQueryTemplateID]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE GetBestQueryTemplateID @DateTypes varchar(500), @HasNELoc bit, @HasNonNELoc bit
AS
BEGIN
	SET NOCOUNT ON;


	select qt.ID, qt.TemplateName
		--, qt.FromPart
		--, qty.*
		--, qs.*
		FROM JobControl..QueryTemplates qt
			join JobControl..QueryTypes qty on qty.QueryTypeID = qt.QueryTypeID
			join JobControl..QuerySources qs on qs.ID = qty.QuerySourceID
			join (select count(*) QueryCount, TemplateID from QueryEditor..Queries group by TemplateID) qc on qc.TemplateID = qt.Id
		where coalesce(qt.disabled,0) = 0
			and @DateTypes like '%' + qty.ReqDataType + '%'
			and case when @HasNELoc = 1 and @HasNonNELoc = 1 then 1
					when @HasNELoc = 1 and @HasNonNELoc = 0 and qs.ID = 1 then 1
					when @HasNELoc = 0 and @HasNonNELoc = 1 and qs.ID = 2 then 1
				else 0 end = 1
		order by QueryCount desc
		



END
