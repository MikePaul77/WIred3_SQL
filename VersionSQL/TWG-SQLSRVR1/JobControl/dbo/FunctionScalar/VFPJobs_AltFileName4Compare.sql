/****** Object:  ScalarFunction [dbo].[VFPJobs_AltFileName4Compare]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION VFPJobs_AltFileName4Compare
(
	@FullFileName varchar(2000), @Src varchar(50)
)
RETURNS varchar(2000)
AS
BEGIN
	DECLARE @result varchar(2000)

	set @result = rtrim(ltrim(@FullFileName))

	if @Src = 'SQL'
		set @result = replace(@FullFileName,'R:\Wired3\ReportsOut\','\\TB12\r$\Wired3\ReportsOut\')

	if @Src = 'VFP'
		set @result = replace(@FullFileName,'R:\Wired3\ReportsOut\','\\TWGWired\WIRED\redp\output\')

	declare @Mark int
	set @Mark = CHARINDEX('\',REVERSE(@result))
	if @mark > 0
		set @result = SUBSTRING(@result, 0, len(@result) - @mark + 2) + @SRC + '_' + SUBSTRING(@result, len(@result) - @mark + 2, 2000)


	RETURN @result

END
