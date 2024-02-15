/****** Object:  ScalarFunction [dbo].[CleanNum_DEL]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION [dbo].[CleanNum]
(@Number int, @Max int, @MaxAltVal int)
RETURNS int
AS
BEGIN
	DECLARE @result int

	set @result = case when @Number is null then 0 else case when @Number > @Max then @MaxAltVal else @Number end end

	RETURN @result
END
