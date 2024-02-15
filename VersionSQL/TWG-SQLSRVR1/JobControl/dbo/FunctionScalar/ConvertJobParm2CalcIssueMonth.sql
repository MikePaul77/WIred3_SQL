/****** Object:  ScalarFunction [dbo].[ConvertJobParm2CalcIssueMonth]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION ConvertJobParm2CalcIssueMonth
(
	@MParam varchar(50), @YParam varchar(50)
)
RETURNS int
AS
BEGIN
	DECLARE @result int

	if isnumeric(@MParam) = 1 and isnumeric(@YParam ) = 1
		set @result = (convert(int,@YParam ) * 100) + convert(int,@MParam)


	RETURN @result

END
