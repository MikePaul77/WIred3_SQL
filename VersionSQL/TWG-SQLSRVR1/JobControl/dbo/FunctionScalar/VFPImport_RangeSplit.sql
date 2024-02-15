/****** Object:  ScalarFunction [dbo].[VFPImport_RangeSplit]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION VFPImport_RangeSplit
(
	@CondValue varchar(500), @Side varchar(10)
)
RETURNS varchar(50)
AS
BEGIN

	DECLARE @result varchar(50)
	declare @Left varchar(50)
	declare @Right varchar(50)

	set @result = ''
	set @Left = ''
	set @Right = ''

	if CHARINDEX(',', @CondValue) > 0
	begin
		set @Left = substring(@CondValue,1,CHARINDEX(',',@CondValue)-1)
		set @Right = substring(@CondValue,CHARINDEX(',',@CondValue)+1, 500)
		if @Side = 'Left'
			set @result = @Left
		else
			set @result = @Right
	end

	RETURN ltrim(rtrim(@result))

END
