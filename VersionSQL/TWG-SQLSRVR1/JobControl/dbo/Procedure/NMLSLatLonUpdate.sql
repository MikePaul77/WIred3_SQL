/****** Object:  Procedure [dbo].[NMLSLatLonUpdate]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.NMLSLatLonUpdate
AS
BEGIN
	SET NOCOUNT ON;


		EXEC [TB12\Devel].AddrStdWork.sys.sp_executesql N'TRUNCATE TABLE dbo.NMLSAddressWork__Addr__'

		EXEC [TB12\Devel].AddrStdWork.sys.sp_executesql N'TRUNCATE TABLE dbo.NMLSAddressWork__Addr____Addr__'

		EXEC [TB12\Devel].AddrStdWork.sys.sp_executesql N'TRUNCATE TABLE dbo.NMLSAddressWork'


		insert [TB12\Devel].AddrStdWork.dbo.NMLSAddressWork (Address, City, State, ZipCode, Country, TBLName, TransactionID, FIPS)

		select *
			from (
			select t.Address, t.City, t.State, t.ZipCode, 'USA' Country
					, t.TBLName, t.TransactionID, T.FiPS
				from [TWGNDSVR].NationalData.dbo.vw_BulkNMLS_current_ACD_LatLon t
				where t.ModiType <> 'D'
			union all 
			select t.Address, t.City, t.State, t.ZipCode, 'USA' Country
					, 'BK_Bulk' TBLName, t.TransactionID, t.FIPS
				FROM [TWGNDSVR].NationalData.dbo.BK_BulkNMLS t
					left outer join [TWGNDSVR].NationalData.dbo.BK_BulkNMLS_LatLon ll on ll.TransactionID = t.TransactionID and ll.FIPS = t.FIPS
				where ll.RecID is null or ltrim(coalesce(ll.Lat,'')) = '' 
			union all
			select t.Address, t.City, t.State, t.ZipCode, 'USA' Country
					, 'TWG_NMLS' TBLName, t.TransactionID, t.FIPS
				FROM [TWGNDSVR].NationalData.dbo.TWG_NMLS t
					left outer join [TWGNDSVR].NationalData.dbo.TWG_NMLS_LatLon ll on ll.TransactionID = t.TransactionID and ll.FIPS = t.FIPS
				where ll.RecID is null or ltrim(coalesce(ll.Lat,'')) = '' 
			) x


		exec [TB12\Devel].AddrStdWork.dbo.NMLSAddressProcess

		EXEC [TWGNDSVR].NationalData.sys.sp_executesql N'TRUNCATE TABLE dbo.AddrStdWork'

		EXEC [TWGNDSVR].NationalData.sys.sp_executesql N'TRUNCATE TABLE dbo.AddrStdWork_Addr'

		insert [TWGNDSVR].NationalData.dbo.AddrStdWork
		select *
			from [TB12\Devel].AddrStdWork.dbo.NMLSAddressWork w

		insert [TWGNDSVR].NationalData.dbo.AddrStdWork_Addr
		select *
			from [TB12\Devel].AddrStdWork.dbo.NMLSAddressWork__Addr____Addr__

		update x set Lat = a.Latitude_corrected
					, Lon = a.Longitude_corrected
					, GeoAccuracy = a.GeoAccuracy_corrected
					, GeoDistance = a.GeoDistance_corrected
			from [TWGNDSVR].NationalData.dbo.AddrStdWork w
				join [TWGNDSVR].NationalData.dbo.AddrStdWork_Addr a on a.recID = w.recID
				join [TWGNDSVR].NationalData.dbo.BK_BulkNMLS_LatLon x on w.TransactionID = x.TransactionID and w.FIPS = x.FIPS
			where w.TBLName = 'BK_Bulk'

		insert [TWGNDSVR].NationalData.dbo.BK_BulkNMLS_LatLon (TransactionID, FIPS, Lat, Lon, GeoAccuracy, GeoDistance)
		select w.TransactionID, w.FIPS
				, a.Latitude_corrected
				, a.Longitude_corrected
				, a.GeoAccuracy_corrected
				, a.GeoDistance_corrected
			from [TWGNDSVR].NationalData.dbo.AddrStdWork w
				join [TWGNDSVR].NationalData.dbo.AddrStdWork_Addr a on a.recID = w.recID
				left outer join [TWGNDSVR].NationalData.dbo.BK_BulkNMLS_LatLon x on w.TransactionID = x.TransactionID and w.FIPS = x.FIPS
			where w.TBLName = 'BK_Bulk' 
				and x.RecID is null	

		update x set Lat = a.Latitude_corrected
					, Lon = a.Longitude_corrected
					, GeoAccuracy = a.GeoAccuracy_corrected
					, GeoDistance = a.GeoDistance_corrected
			from [TWGNDSVR].NationalData.dbo.AddrStdWork w
				join [TWGNDSVR].NationalData.dbo.AddrStdWork_Addr a on a.recID = w.recID
				join [TWGNDSVR].NationalData.dbo.BK_BulkNMLS_LatLon x on w.TransactionID = x.TransactionID and w.FIPS = x.FIPS
			where w.TBLName = 'TWG_NMLS'

		insert [TWGNDSVR].NationalData.dbo.TWG_NMLS_LatLon (TransactionID, FIPS, Lat, Lon, GeoAccuracy, GeoDistance)
		select w.TransactionID, w.FIPS
				, a.Latitude_corrected
				, a.Longitude_corrected
				, a.GeoAccuracy_corrected
				, a.GeoDistance_corrected
			from [TWGNDSVR].NationalData.dbo.AddrStdWork w
				join [TWGNDSVR].NationalData.dbo.AddrStdWork_Addr a on a.recID = w.recID
				join [TWGNDSVR].NationalData.dbo.BK_BulkNMLS_LatLon x on w.TransactionID = x.TransactionID and w.FIPS = x.FIPS
			where w.TBLName = 'TWG_NMLS' 
				and x.RecID is null	


		--- Progress Counts SQL

		--select coalesce(ad.PafDesc, ll.PafDesc) PafDesc
		--	, format(ad.Recs,'#,##0') + ' of ' + format(t.Recs,'#,##0') + ' ' + format((convert(money,ad.recs) / convert(money,t.recs)) * 100,'##0') + '%' AddStd
		--	, format(ll.Recs,'#,##0') + ' of ' + format(T.Recs,'#,##0') + ' ' + format((convert(money,ll.recs) / convert(money,T.recs)) * 100,'##0') + '%' LatLon
		--	from (select PafDesc, count(*) recs 
		--				from [TB12\Devel].AddrStdWork.NMLSAddressWork__Addr__ group by PafDesc) ad
		--		full outer join (select PafDesc, count(*) recs
		--				from [TB12\Devel].AddrStdWork.NMLSAddressWork__Addr____Addr__  group by PafDesc) ll on ll.PafDesc = ad.PafDesc
		--		join (select count(*) recs from NMLSAddressWork) t on 1 = 1
		--order by 1 desc


		--- Has Lat counts

		--select format(convert(int,TotalRecs),'#,##0') TotalRecs
		--		, format(convert(int,wLat),'#,##0') wLat, (WLat / TotalRecs) * 100 WLatPct
		--		, format(convert(int,woLat),'#,##0') woLat, (woLat / TotalRecs) * 100 woLatPct
		--	from (
		--		select convert(money,count(*)) TotalRecs
		--			, convert(money,sum(case when Lat > '' then 1 else 0 end)) wLat
		--			, convert(money,sum(case when Lat > '' then 0 else 1 end)) woLat
		--			FROM [TWGNDSVR].NationalData.dbo.vw_BulkNMLS_LatLon
		--	) x

			--select count(*) from [TWGNDSVR].NationalData.dbo.BK_BulkNMLS_LatLon

			--select count(*) from [TWGNDSVR].NationalData.dbo.TWG_NMLS_LatLon



END
