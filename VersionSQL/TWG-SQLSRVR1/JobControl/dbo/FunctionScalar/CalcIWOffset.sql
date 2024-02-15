/****** Object:  ScalarFunction [dbo].[CalcIWOffset]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION CalcIWOffset
(
	@IssueWeek int, @OffSet int
)
RETURNS int
AS
BEGIN
	DECLARE @Result int

	set @Result = @IssueWeek

	select @Result = min(Issueweek)
		from (
			select Issueweek, seq = ROW_NUMBER() OVER (ORDER BY Issueweek desc)
				from Support..IssueWeeks
				where StateID = 25
					and Issueweek <= @IssueWeek
			) x 
		where x.seq <= coalesce(@OffSet,0) + 1


	RETURN @Result

END
