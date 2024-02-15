/****** Object:  ScalarFunction [dbo].[pad_DEL]    Committed by VersionSQL https://www.versionsql.com ******/

create FUNCTION [dbo].[pad]
(
	@pad_str varchar(100), @full_len int
)
RETURNS varchar(100)
AS
BEGIN
	DECLARE @pad_out varchar(100)

	set @pad_out = replicate('0',@full_len - len(@pad_str)) + @pad_str

	RETURN @pad_out

END
