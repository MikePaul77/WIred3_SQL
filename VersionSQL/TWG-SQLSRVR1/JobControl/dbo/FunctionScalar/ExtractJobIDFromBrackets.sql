/****** Object:  ScalarFunction [dbo].[ExtractJobIDFromBrackets]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 12-15-2018
-- Description:	Passes in a job name.  If there is a JobID enclosed in brackets [], the JobID will be returned.
--				Otherwise, zero is returned.
-- =============================================
CREATE FUNCTION dbo.ExtractJobIDFromBrackets
(
	@JobName nvarchar(128)
)
RETURNS int
AS
BEGIN
	DECLARE @ReturnVar int = 0;
	Declare @TempVal varchar(10) = '';

	declare @RevName varchar(200) 
	set @RevName = Reverse(@JobName)

	declare @Mark int
	set @Mark = charindex('[',@RevName)

	if @Mark > 0
	begin

		set @TempVal = substring(@JobName, len(@JobName) - @Mark,20)
		set @TempVal = ltrim(rtrim(replace(replace(@TempVal,'[',''),']','')))

		if len(@TempVal) > 0 and ISNUMERIC(@TempVal) = 1 
			set @ReturnVar=convert(int, @TempVal);

	end

	--if charindex('[',@JobName)>0 and charindex(']',@JobName)>0 and charindex(']',@JobName) > charindex('[',@JobName)
	--	Begin
	--		SELECT @TempVal=SUBSTRING(@JobName, CHARINDEX('[', @JobName) + 1,
	--		      CHARINDEX(']', @JobName) - CHARINDEX('[', @JobName) - 1);
	--		if len(@TempVal)>0 set @ReturnVar=convert(int, @TempVal);
	--	End

	RETURN @ReturnVar;

END
