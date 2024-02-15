/****** Object:  ScalarFunction [dbo].[CountAppearances]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION CountAppearances 
(
	@Src varchar(max), @Find varchar(100)
)
RETURNS int
AS
BEGIN
	DECLARE @Result int

	set @Result = (len(@Src) - len(replace(@src, @Find,''))) / len(@Find)

	-- Return the result of the function
	RETURN @Result

END
