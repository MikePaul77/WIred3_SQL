/****** Object:  Procedure [dbo].[CustomerJobsSummary]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.CustomerJobsSummary @CustID int
AS
BEGIN
	SET NOCOUNT ON;

	select distinct j.jobID, j.JobName, qt.TemplateName, J.InProduction, j.TestMode, j.CreatedStamp, j.UpdatedStamp, j.LastJobRunStartTime
		, coalesce(co.CompanyName,'') + ' - ' + coalesce(c.FirstName,'') + ' ' + coalesce(c.LastName,'') + ' (' + ltrim(str(c.CustID)) + ')' ShowCust
		, substring((select distinct ', ' + s.Code
				from JobControl..JobSteps js 
					join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID 
					left outer join Lookups..States s on s.id = ql.StateID
				where js.JobID = j.JobID and js.QueryCriteriaID > 0
				order by ', ' + s.Code
				for XML path('') 
			),2,2000) States
		, substring((select ', ' + c.FullName + ' ' + s.Code
				from QueryEditor..QueryLocations ql
					left outer join Lookups..Counties c on c.Id = ql.CountyID
					left outer join Lookups..States s on s.id = c.StateID
				where ql.QueryID = js.QueryCriteriaID 
				order by s.Code, c.FullName
				for XML path('') 
			),2,2000) Counties
		, substring((select ', ' + t.FullName + ' ' + s.Code
				from QueryEditor..QueryLocations ql
					left outer join Lookups..Towns t on t.Id = ql.TownID
					left outer join Lookups..States s on s.id = t.StateID
				where ql.QueryID = js.QueryCriteriaID 
				order by s.Code, t.FullName
				for XML path('') 
			),2,2000) Towns


	from JobControl..Jobs j
		join JobControl..JobSteps js on js.JobID = j.JobID and js.QueryCriteriaID > 0
		join JobControl..QueryTemplates qt on qt.Id = js.QueryTemplateID and js.QueryTemplateID not in (1060)
		join OrderControl..Customers c on c.CustID = j.CustID
		left outer join OrderControl..Companies co on co.CompanyID = c.CompanyID
	where j.CustID = @CustID
		and coalesce(j.disabled,0) = 0
		and coalesce(j.deleted,0) = 0



END
