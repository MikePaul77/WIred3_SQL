/****** Object:  Procedure [dbo].[GetQueryTemplates]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE GetQueryTemplates
AS
BEGIN
	SET NOCOUNT ON;

	select qs.DisplayName SourceDisplayName
		, coalesce(qty.ReqDataType,'Other') DataType
		, gt.GroupName DataGroupName
		, qty.DefaultID DefaultQueryID, qty.DefaultXFormID
		, qt.ID 
		, qt.TemplateName
		, qt.TemplateName + ' (' + ltrim(str(qt.ID)) + ') v' + ltrim(str(qt.QueryVersion)) + coalesce(' | ' + gt.GroupName,'') ShowTemplateName
	from JobControl..QueryTemplates qt
		join JobControl..QueryTypes qty on qt.QueryTypeID = qty.QueryTypeID
		join JobControl..QuerySources qs on qs.ID = qty.QuerySourceID
		left outer join JobControl..DataGroupTypes gt on gt.ID = qt.DataGroupTypeID
	where coalesce(qt.disabled,0) = 0
	order by qs.SrcPriority, qs.DisplayName, coalesce(qty.QueryTypeID,9999), qty.ReqDataType, case when qt.ID = qty.DefaultID then 1 else 10 end, qt.QueryVersion desc , gt.GroupName

END
