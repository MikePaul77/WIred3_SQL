/****** Object:  Procedure [dbo].[Get_LPS_Report_Counties]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE Get_LPS_Report_Counties
AS
BEGIN
	SET NOCOUNT ON;

	select s.code state, c.FullName County, c.Code CCode 
		, d.* 
	from WiredJobControlWork..LPSRepWork3 d
		join Lookups..Counties c on c.Id = d.CountyID and c.code > ''
		join Lookups..States s on s.Id = c.StateID
	order by d.RecType, s.code, c.Code

END
