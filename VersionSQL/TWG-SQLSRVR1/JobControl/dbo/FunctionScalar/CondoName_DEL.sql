/****** Object:  ScalarFunction [dbo].[CondoName_DEL]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION [dbo].[CondoName]
(
	@PropID int
)
RETURNS varchar(200)
AS
BEGIN
	DECLARE @result varchar(200)

	select top 1 @result = ca.StreetCore
		from TWG_PropertyData..PropertyAddresses cpa 
			left outer join TWG_PropertyData..Addresses ca on cpa.AddressId = ca.id
		where cpa.AddressSource = 'C'
			and cpa.PropertyId = @PropID
		order by cpa.AddressId desc

	RETURN @result

END
