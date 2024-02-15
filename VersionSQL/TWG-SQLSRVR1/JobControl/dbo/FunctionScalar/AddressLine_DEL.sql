/****** Object:  ScalarFunction [dbo].[AddressLine_DEL]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION [dbo].[AddressLine]
(@StreetNumber int, @StreetNumberExtension varchar(10), @StreetCore varchar(200), @UnitType varchar(50), @UnitNumber varchar(50))
RETURNS varchar(500)
AS
BEGIN
	DECLARE @result varchar(500)

	set @result = ltrim(rtrim(case when coalesce(@StreetNumber,0) = 0 then '' else ltrim(rtrim(@StreetNumber)) end
						+ case when @StreetNumberExtension is null or coalesce(@StreetNumber,0) = 0 then '' else '-' + ltrim(rtrim(replace(@StreetNumberExtension,'-',''))) end
						+ case when @StreetCore = 'ZZZ'  then 'N/A' else ' ' + ltrim(rtrim(@StreetCore))
					--	+ case when @UnitType is null then '' else ' ' + ltrim(rtrim(@UnitType)) end
						+ case when @UnitNumber is null then '' else ' #' + ltrim(rtrim(@UnitNumber)) end
					end))


	RETURN @result
END
