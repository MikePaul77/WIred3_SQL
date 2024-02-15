/****** Object:  Procedure [dbo].[Get_LPS_Report_Towns]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE Get_LPS_Report_Towns
AS
BEGIN
	SET NOCOUNT ON;

	select s.code state, t.FullName townname, t.Code town
		, d.* 
	from WiredJobControlWork..LPSRepWork2 d
		join Lookups..Towns t on t.Id = d.TownID and t.code > '' and t.code <> 'ZZZZ'
		join Lookups..States s on s.Id = t.StateID and s.code in ('CT','RI','VT')
	order by d.RecType, s.code, t.Code


END
