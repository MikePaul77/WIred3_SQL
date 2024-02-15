/****** Object:  ScalarFunction [dbo].[ProperCase_DEL]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION ProperCase
(
	@Value varchar(500)
)
RETURNS varchar(500)
AS
BEGIN
	DECLARE @result varchar(500)
	declare @Reset bit;
	declare @i int;
    declare @c char(1);

	select @Reset = 1, @i=1, @result = '';
	
	while (@i <= len(@Value))
    select @c= substring(@Value,@i,1),
               @result = @result + case when @Reset=1 then UPPER(@c) else LOWER(@c) end,
               @Reset = case when @c like '[a-zA-Z]' then 0 else 1 end,
               @i = @i +1

	RETURN @result

END
