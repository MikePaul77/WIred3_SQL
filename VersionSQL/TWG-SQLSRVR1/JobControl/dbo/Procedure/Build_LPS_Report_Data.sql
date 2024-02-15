/****** Object:  Procedure [dbo].[Build_LPS_Report_Data]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE Build_LPS_Report_Data
AS
BEGIN
	SET NOCOUNT ON;

	drop table if exists WiredJobControlWork..LPSRepWork

	select StateID, CountyID, TownID, 'Assignments' RecType, Year(FilingDate) * 100 + Month(FilingDate) FilingMonth, count(*) Recs
		into WiredJobControlWork..LPSRepWork
		from TWG_PropertyData_Rep..MortgageAssignments
		where ModificationType <> 'D'
		group by StateID, CountyID, TownID, Year(FilingDate) * 100 + Month(FilingDate)
	union 
	select StateID, CountyID, TownID, 'Discharges' RecType, Year(FilingDate) * 100 + Month(FilingDate) FilingMonth, count(*) Recs 
		from TWG_PropertyData_Rep..MortgageDischarges
		where ModificationType <> 'D'
		group by StateID, CountyID, TownID, Year(FilingDate) * 100 + Month(FilingDate)
	union 
	select StateID, CountyID, TownID, 'Sales' RecType, Year(FilingDate) * 100 + Month(FilingDate) FilingMonth, count(*) Recs 
		from TWG_PropertyData_Rep..SalesTransactions
		where ModificationType <> 'D'
		group by StateID, CountyID, TownID, Year(FilingDate) * 100 + Month(FilingDate)
	union 
	select StateID, CountyID, TownID, 'Mortgages' RecType, Year(FilingDate) * 100 + Month(FilingDate) FilingMonth, count(*) Recs 
		from TWG_PropertyData_Rep..MortgageTransactions
		where ModificationType <> 'D'
		group by StateID, CountyID, TownID, Year(FilingDate) * 100 + Month(FilingDate)
	union 
	select StateID, CountyID, TownID, 'PreForeclosures' RecType, Year(FilingDate) * 100 + Month(FilingDate) FilingMonth, count(*) Recs 
		from TWG_PropertyData_Rep..PreForeclosureTransactions
		where ModificationType <> 'D'
		group by StateID, CountyID, TownID, Year(FilingDate) * 100 + Month(FilingDate)


	drop table if exists WiredJobControlWork..LPSRepWork2
	drop table if exists WiredJobControlWork..LPSRepWork3

	create table WiredJobControlWork..LPSRepWork2 (TownID int, RecType varchar(50))
	create table WiredJobControlWork..LPSRepWork3 (CountyID int, RecType varchar(50))

	insert WiredJobControlWork..LPSRepWork2 (TownID, RecType)
	select t.ID, RecType
		from Lookups..Towns t
			join Lookups..States s on s.Id = t.StateID --and s.Mode <> 'None'
			join ( select 'Assignments' RecType
					union select 'Discharges' RecType
					union select 'Sales' RecType
					union select 'Mortgages' RecType
					union select 'PreForeclosures' RecType) x on 1=1

	insert WiredJobControlWork..LPSRepWork3 (CountyID, RecType)
	select c.ID, RecType
		from Lookups..Counties c
			join Lookups..States s on s.Id = c.StateID --and s.Mode <> 'None'
			join ( select 'Assignments' RecType
					union select 'Discharges' RecType
					union select 'Sales' RecType
					union select 'Mortgages' RecType
					union select 'PreForeclosures' RecType) x on 1=1


	declare @FilingMonth int

	select @FilingMonth = Max(FilingMonth)
		from WiredJobControlWork..LPSRepWork

	declare @cmd varchar(max)

	while @FilingMonth > 201001
	begin


		set @cmd = 'alter table WiredJobControlWork..LPSRepWork2 add m' + ltrim(str(@FilingMonth)) + ' int'
		exec(@cmd)

		set @cmd = 'alter table WiredJobControlWork..LPSRepWork3 add m' + ltrim(str(@FilingMonth)) + ' int'
		exec(@cmd)

		set @cmd = 'update x set m' + LTRIm(STR(@FilingMonth)) + ' = w.Recs
						from WiredJobControlWork..LPSRepWork2 x
					join (select sum(Recs) Recs, TownID, RecType
							from WiredJobControlWork..LPSRepWork 
							where FilingMonth = ' + LTRIm(STR(@FilingMonth)) + '
							group by TownID, RecType ) w on w.RecType = x.RecType and w.TownID = x.TownID '
		exec(@cmd)

		set @cmd = 'update x set m' + LTRIm(STR(@FilingMonth)) + ' = w.Recs
						from WiredJobControlWork..LPSRepWork3 x
					join (select sum(Recs) Recs, CountyID, RecType
							from WiredJobControlWork..LPSRepWork 
							where FilingMonth = ' + LTRIm(STR(@FilingMonth)) + '
							group by CountyID, RecType ) w on w.RecType = x.RecType and w.CountyID = x.CountyID '
		--print @cmd
		exec(@cmd)

		if convert(int,right(ltrim(str(@FilingMonth)),2)) = 1
			set @FilingMonth = ((convert(int,left(ltrim(str(@FilingMonth)),4)) - 1) * 100 ) + 12
		else
			set @FilingMonth = @FilingMonth - 1


	end



END
