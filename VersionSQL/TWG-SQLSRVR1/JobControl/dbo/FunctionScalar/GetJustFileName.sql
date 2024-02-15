/****** Object:  ScalarFunction [dbo].[GetJustFileName]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION GetJustFileName 
(
	@FullName varchar(2000)
)
RETURNS varchar(500)
AS
BEGIN
	DECLARE @result varchar(500)

	set @result = @FullName

	declare @mark int
	set @mark = CHARINDEX('\',Reverse(@FullName))
	if @mark > 0
	begin
		set @result = Reverse(left(Reverse(@FullName),@mark-1))
	end

	RETURN @result

END
