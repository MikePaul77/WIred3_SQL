/****** Object:  ScalarFunction [dbo].[QueryLocationCleanUp]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.QueryLocationCleanUp 
(
	@QCmd Varchar(max)
)
RETURNS Varchar(max)
AS
BEGIN
	declare @Cmd varchar(max)
	set @Cmd = @QCmd

	declare @PatStart int
	declare @PatEnd int

	declare @Cnt int = 0

	set @PatStart = PATINDEX('%--#LocationClauseStart%#%',@Cmd)
	set @PatEnd = PATINDEX('%--#LocationClauseEnd%#%',@Cmd)

	if @PatStart > 0 and @PatEnd > 0
		set @Cnt = @Cnt + 1

	--while @PatStart > 0 and @PatEnd > 0
	--begin

	--	set @Cnt = @Cnt + 1

	--	set @Cmd = left(@Cmd, @PatStart - 1) + ' 1=1 ' + substring(@Cmd,@PatEnd,len(@Cmd))

	--	set @PatStart = PATINDEX('%--#LocationClauseStart%#%',@Cmd)
	--	set @PatEnd = PATINDEX('%--#LocationClauseEnd%#%',@Cmd)
	--end

	if @cnt = 0
	begin
		set @Cmd = @Cmd + 'and ( '  + char(10)  + ' --#LocationClauseStart1#' + char(10) + char(10) + '--#LocationClauseEnd1#' + char(10) + ' )' + char(10)
	end

	RETURN @Cmd

END
