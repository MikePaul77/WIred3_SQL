/****** Object:  ScalarFunction [dbo].[AppendText_DEL]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION [dbo].[AppendText]
(@str1 varchar(500), @str2 varchar(500), @str3 varchar(500), @commapos int = 0)
RETURNS varchar(500)
AS
BEGIN
	DECLARE @result varchar(500)

	set @result = case when @str1 is null then '' else ltrim(rtrim(@str1)) end

	if @commapos = 1 and @result > '' and ltrim(rtrim(coalesce(@str2,''))) > ''
		set @result = @result + ','

	set @result = @result + case when @str2 is null then '' else ' ' + ltrim(rtrim(@str2)) end

	if @commapos = 2 and @result > '' and ltrim(rtrim(coalesce(@str3,''))) > ''
		set @result = @result + ','

	set @result = @result + case when @str3 is null then '' else ' ' + ltrim(rtrim(@str3)) end

	set @result = ltrim(rtrim(@result))

	RETURN @result
END
