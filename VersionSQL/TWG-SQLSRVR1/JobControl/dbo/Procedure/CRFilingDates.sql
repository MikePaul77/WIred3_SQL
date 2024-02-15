/****** Object:  Procedure [dbo].[CRFilingDates]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE CRFilingDates 

	@StateID int

AS
BEGIN
	
	SET NOCOUNT ON;

    select x.TownID, x.MaxFilingDate, t.FullName TownName, t.trxndefreq, c.FullName CountyName, c.Id CountyID
	from 
	(
	select max(d.filingdate) MaxFilingDate, d.TownID
	from TWG_PropertyData_Rep..SalesTransactions d
	where d.StateID = @StateID
	group by d.TownID
	) x
	join Lookups..Towns t on t.Id = x.TownID
	join Lookups..Counties c on c.Id = t.CountyId
	order by c.FullName, c.Id, t.FullName, t.Id
END
