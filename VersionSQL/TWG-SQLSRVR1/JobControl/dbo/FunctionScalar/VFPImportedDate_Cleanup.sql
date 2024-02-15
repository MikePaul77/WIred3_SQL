/****** Object:  ScalarFunction [dbo].[VFPImportedDate_Cleanup]    Committed by VersionSQL https://www.versionsql.com ******/

create FUNCTION dbo.VFPImportedDate_Cleanup(@RawDate varchar(50))
RETURNS varchar(50)
AS
BEGIN
	DECLARE @result varchar(50)
	declare @ConveredRawDate datetime
	set @result = null

	if ISDATE(@RawDate) = 1
	begin
		set @ConveredRawDate = convert(datetime,@RawDate) 
		set @result = convert(varchar(50),@ConveredRawDate,101)  -- mm/dd/yyyy
		if @result = '12/30/1899'
			set @result = null
	end

	RETURN @result

END
