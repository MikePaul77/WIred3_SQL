/****** Object:  ScalarFunction [dbo].[CalcIWOffset2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.CalcIWOffset2
(
	@IssueWeek int, @OffSet int
)
RETURNS int
AS
BEGIN
	DECLARE @Result int

	set @Result = @IssueWeek

	if @Offset < 0
	begin
		select @Result = ltrim(str(Issueweek))
			from (
				select x.Issueweek, ROW_NUMBER() OVER (ORDER BY x.Issueweek desc) Seq
					from (
						select distinct Issueweek
							from Support..IssueWeeks
							where StateID = 25
								and Issueweek < @IssueWeek
						) x
				) z
			where z.Seq = ABS(@Offset)
	end
	if @Offset > 0
	begin
		select @Result = ltrim(str(Issueweek))
			from (
				select x.Issueweek, ROW_NUMBER() OVER (ORDER BY x.Issueweek asc) Seq
					from (
						select distinct Issueweek
							from Support..IssueWeeks
							where StateID = 25
								and Issueweek > @IssueWeek
						) x
				) z
			where z.Seq = ABS(@Offset)
	end

	RETURN @Result

END
