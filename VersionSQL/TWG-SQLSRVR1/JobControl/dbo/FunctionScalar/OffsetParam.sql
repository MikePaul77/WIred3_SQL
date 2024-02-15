/****** Object:  ScalarFunction [dbo].[OffsetParam]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION OffsetParam 
(
	@ParamName varchar(25), @ParamValue varchar(25), @Offset int
)
RETURNS varchar(25)
AS
BEGIN
	
	DECLARE @Result varchar(25)

	set @Result = @ParamValue

	if @Offset > 0
	begin

		if @ParamName = 'IssueWeek'
		begin
			select @Result = ltrim(str(Issueweek))
				from (
					select x.Issueweek, ROW_NUMBER() OVER (ORDER BY x.Issueweek desc) Seq
						from (
							select distinct Issueweek
							from Support..IssueWeeks
								where Issueweek <= @ParamValue
							) x
					) z
				where z.Seq = 1 + @Offset
--				order by Issueweek desc 
		end

		if @ParamName = 'IssueMonth'
		begin
			select @Result = ltrim(str(IssueMonth))
				from (
					select x.IssueMonth, ROW_NUMBER() OVER (ORDER BY x.SortableIssueMonth desc) Seq
						from (
							select distinct IssueMonth, SortableIssueMonth
							from Support..IssueMonth
								where SortableIssueMonth <= @ParamValue
							) x
					) z
				where z.Seq = 1 + @Offset
		end

		if @ParamName in ('CalPeriod','CalYear')
		begin
			select @Result = ltrim(str(IssueMonth))
				from (
					select x.IssueMonth, ROW_NUMBER() OVER (ORDER BY x.SortableIssueMonth desc) Seq
						from (
							select distinct IssueMonth, SortableIssueMonth
							from Support..IssueMonth
								where SortableIssueMonth <= @ParamValue
							) x
					) z
				where z.Seq = 1 + @Offset
		end


	end

	RETURN @Result

END
