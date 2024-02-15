/****** Object:  Procedure [dbo].[GetExtendedFilters2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetExtendedFilters2  @Username varchar(50)
AS
BEGIN
	SET NOCOUNT ON;

	select case when SQLCOde > '' then 30 when ef.CreatedByUserID > 0 and coalesce(ef.IsPublic,0) = 0 then 70 else 50 end GroupOrder
				, coalesce(DisplayOrder,1000) ItemOrder
				, ef.ID
				, ef.FilterName
				, ef.IsPublic
				, case when SQLCOde > '' then 1 when ef.CreatedByUserID > 0 and coalesce(ef.IsPublic,0) = 0 then 3 else 2 end GroupNum
				, case when SQLCOde > '' then 1 else 0 end IsAuto
			from JobControl..ExtendedFilters ef
				left outer join Support..MasterUser mu on mu.UserID = ef.CreatedByUserID and (mu.UserName = @UserName or mu.UserName2 = @UserName) and coalesce(mu.disabled,0) = 0
			where coalesce(ef.disabled,0) = 0
				and ID > 0 
				and (IsPublic = 1
				or CreatedByUserID = mu.UserID)
		union select 0, 1, 0, 'No Filter', 1, 0, 0
		union select 20, 1, -1, 'Auto Filers', 1, 1, 0
		union select 40, 1, -2, 'Manual Filters', 1, 2, 0
		union select 60, 1, -3, 'My Filters', 1, 3, 0

	order by 1, 2, 4

END
