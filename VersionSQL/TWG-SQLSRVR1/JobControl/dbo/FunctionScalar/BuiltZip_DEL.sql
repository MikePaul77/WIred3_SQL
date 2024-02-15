/****** Object:  ScalarFunction [dbo].[BuiltZip_DEL]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION BuiltZip
(@Zip varchar(10), @Plus4 varchar(10))
RETURNS varchar(20)
AS
BEGIN
	DECLARE @result varchar(20)

	set @result = case when @Zip is null then '' else ltrim(rtrim(@Zip)) end
					 + case when ltrim(rtrim(coalesce(@Plus4,''))) > '' then '-' + ltrim(rtrim(@Plus4)) else '' end

	RETURN @result
END
