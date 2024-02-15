/****** Object:  ScalarFunction [dbo].[VFPImport_FileExtSwap]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.VFPImport_FileExtSwap
(
	@OrigFileName varchar(2000), @NewExt varchar(50)
)
RETURNS varchar(2000)
AS
BEGIN
	DECLARE @Result varchar(2000)

	set @Result = @OrigFileName

	declare @Mark int = charindex('.',@Result)

	if @Mark > 0
	begin
		set @Result = left(@Result,@Mark) + @NewExt
	end

	RETURN @Result

END
