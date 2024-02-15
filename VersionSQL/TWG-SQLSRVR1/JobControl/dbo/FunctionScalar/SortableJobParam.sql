/****** Object:  ScalarFunction [dbo].[SortableJobParam]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION SortableJobParam
(
	@QueueParam varchar(50), @RecurringCode varchar(10), @RecurringID int
)
RETURNS int
AS
BEGIN
	declare @Result int = null

	declare @Work varchar(50) = replace(@QueueParam, @RecurringCode + ':','') 
	declare @Work2 varchar(50) 

	if @RecurringID = 2 -- IW
		set @Work2 = @Work

	if @RecurringID = 4 or @RecurringID = 3 -- CM or IM
		set @Work2 = right(@Work,4) + left(@Work,2)

	if @RecurringID = 5 -- CQ
		set @Work2 = right(@Work,4) + replace(left(@Work,2),'Q','')

	if @RecurringID = 6 -- CA
		set @Work2 = right(@Work,4)

	if isnumeric(@Work2) = 1
		set @Result = convert(int,@Work2)

	RETURN @Result

END
