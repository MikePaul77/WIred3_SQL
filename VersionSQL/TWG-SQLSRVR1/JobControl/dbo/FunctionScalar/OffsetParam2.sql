/****** Object:  ScalarFunction [dbo].[OffsetParam2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.OffsetParam2 
(
	@ParamName varchar(25), @ParamValue varchar(25), @Offset int
)
RETURNS varchar(25)
AS
BEGIN
	
	DECLARE @Result varchar(25)

	set @Result = @ParamValue

	if @Offset <> 0
	begin

		if @ParamName = 'IssueWeek'
		begin
			if @Offset < 0
			begin
				select @Result = ltrim(str(Issueweek))
					from (
						select x.Issueweek, ROW_NUMBER() OVER (ORDER BY x.Issueweek desc) Seq
							from (
								select distinct Issueweek
								from Support..IssueWeeks
									where Issueweek < @ParamValue
								) x
						) z
					where z.Seq = ABS(@Offset)
			end
			else -- + offset
			begin
				select @Result = ltrim(str(Issueweek))
					from (
						select x.Issueweek, ROW_NUMBER() OVER (ORDER BY x.Issueweek asc) Seq
							from (
								select distinct Issueweek
								from Support..IssueWeeks
									where Issueweek > @ParamValue
								) x
						) z
					where z.Seq = ABS(@Offset)

			end


		end

		if @ParamName = 'IssueMonth'
		begin
			if @Offset < 0
			begin 
				select @Result = ltrim(str(IssueMonth))
					from (
						select x.IssueMonth, ROW_NUMBER() OVER (ORDER BY x.SortableIssueMonth desc) Seq
							from (
								select distinct IssueMonth, SortableIssueMonth
								from Support..IssueMonth
									where SortableIssueMonth < convert(int,right(@ParamValue,4) + left(@ParamValue,2))
								) x
						) z
					where z.Seq = ABS(@Offset)
			end
			else
			begin
				select @Result = ltrim(str(IssueMonth))
					from (
						select x.IssueMonth, ROW_NUMBER() OVER (ORDER BY x.SortableIssueMonth asc) Seq
							from (
								select distinct IssueMonth, SortableIssueMonth
								from Support..IssueMonth
									where SortableIssueMonth > convert(int,right(@ParamValue,4) + left(@ParamValue,2))
								) x
						) z
					where z.Seq = ABS(@Offset)
			end
		end

		if @ParamName in ('CalPeriod','CalYear')
		begin
			if @Offset < 0
			begin 
				select @Result = ltrim(str(IssueMonth))
					from (
						select x.IssueMonth, ROW_NUMBER() OVER (ORDER BY x.SortableIssueMonth desc) Seq
							from (
								select distinct IssueMonth, SortableIssueMonth
								from Support..IssueMonth
									where SortableIssueMonth < convert(int,right(@ParamValue,4) + left(@ParamValue,2))
								) x
						) z
					where z.Seq = ABS(@Offset)
			end
			else
			begin
				select @Result = ltrim(str(IssueMonth))
					from (
						select x.IssueMonth, ROW_NUMBER() OVER (ORDER BY x.SortableIssueMonth asc) Seq
							from (
								select distinct IssueMonth, SortableIssueMonth
								from Support..IssueMonth
									where SortableIssueMonth > convert(int,right(@ParamValue,4) + left(@ParamValue,2))
								) x
						) z
					where z.Seq = ABS(@Offset)
			end
		end


	end

	RETURN @Result

END
