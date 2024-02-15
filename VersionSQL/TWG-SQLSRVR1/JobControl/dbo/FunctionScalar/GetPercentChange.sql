/****** Object:  ScalarFunction [dbo].[GetPercentChange]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 04/30/2019
-- Description:	Get the percent change of two values
-- =============================================
CREATE FUNCTION dbo.GetPercentChange 
(
	-- Add the parameters for the function here
	@val1 varchar(100),
	@val2 varchar(100)
)
RETURNS varchar(100)
AS
BEGIN
	DECLARE @RetVal varchar(100),
		@v1 decimal(10,2),
		@v2 decimal(10,2),
		@result decimal(10,2);

	Set @val1 = replace(@val1, '$', '');
	Set @val1 = ltrim(rtrim(replace(@val1, ',', '')));
	Set @val2 = replace(@val2, '$', '');
	Set @val2 = ltrim(rtrim(replace(@val2, ',', '')));

	if @val1='' or @val2=''
		Set @RetVal='N/A'
	else
		Begin
			Set @v1 = convert(decimal(10,2), @val1);
			Set @v2 = convert(decimal(10,2), @val2);
			Set @result = iif(@v1=0,0.00,((@v2 - @v1)/@v1)*100);
			Set @RetVal = iif(@v1=0,'N/A',convert(varchar, @result)+'%');
		End

	RETURN @RetVal;

END
