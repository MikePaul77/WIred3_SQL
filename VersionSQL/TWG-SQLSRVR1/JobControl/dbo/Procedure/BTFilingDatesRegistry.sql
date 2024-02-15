/****** Object:  Procedure [dbo].[BTFilingDatesRegistry]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.BTFilingDatesRegistry 

	@StateID int

AS
BEGIN
	
	SET NOCOUNT ON;

    select case when RegistryId = 140 then 1 else 2 end ForceRegOrder, x.MaxFilingDate, r.RegistryName, r.Id RegistryID
	from 
	(
	select max(d.filingdate) MaxFilingDate, t.RegistryID
	from TWG_PropertyData_Rep..SalesTransactions d
	left outer join lookups..Towns t on t.Id = d.TownID
	where d.StateID = @StateID
	group by t.RegistryID
	) x
	join Lookups..Registries r on r.Id = x.RegistryId
	order by 1, r.RegistryName, r.Id
END
