/****** Object:  Procedure [dbo].[GetExtendedFilters]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE GetExtendedFilters
AS
BEGIN
	SET NOCOUNT ON;

		select case when SQLCOde > '' then 30 else 50 end GroupOrder
				, coalesce(DisplayOrder,1000) ItemOrder
				, ID
				, FilterName
			from JobControl..ExtendedFilters
			where coalesce(disabled,0) = 0
				and ID > 0
		union select 0, 1, 0, '-- No Filter --'
		union select 20, 1, -1, '     -- Auto Filers --'
		union select 40, 1, -2, '     -- Manual Filters --'

	order by 1, 2, 3

END
