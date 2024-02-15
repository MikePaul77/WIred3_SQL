/****** Object:  ScalarFunction [dbo].[GetOwnCity]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION GetOwnCity 
(
	@ResOwner varchar(1), @TownCode varchar(10), @OwnerCity varchar(100), @Propzip5 varchar(10)
)
RETURNS varchar(100)
AS
BEGIN
	DECLARE @result varchar(100)
	Declare @TownName varchar(100)

	if @ResOwner = 'N' and ltrim(@OwnerCity) <> ''
		set @result = @OwnerCity
	else
		begin
			select @TownName = ltrim(rtrim(fullName)) from Lookups..Towns where Code = @TownCode

			declare @found int
			select @found = count(*) from Support..Zip_5 where zipcode = @Propzip5 and ltrim(rtrim(cityname)) = @TownName
			if @found > 0
				set @result = @TownName
			else
				select top 1 @result = postoff from Support..Zip_5 where zipcode = @Propzip5

		end

	RETURN @result

END
