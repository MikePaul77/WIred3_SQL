/****** Object:  ScalarFunction [dbo].[NextXXday]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION [NextXXday]
(
    @CurrentDate datetime, @TargetDay int
)
RETURNS datetime
AS
BEGIN

-- 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Sturday
declare @NextDate datetime

if datepart(dw, @CurrentDate) >= @TargetDay          
	set @NextDate =  convert(date, dateadd(day, @TargetDay, @CurrentDate - datepart(dw, @CurrentDate)
			   + case when datepart(dw, @CurrentDate) < 1 then 0 else 7 end )) 
else
	set @NextDate =  convert(date, dateadd(day, @TargetDay, @CurrentDate - datepart(dw, @CurrentDate)))


return @NextDate

END
