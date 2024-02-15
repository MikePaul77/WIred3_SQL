/****** Object:  ScalarFunction [dbo].[VFPImport_TBLNCleanUp]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.VFPImport_TBLNCleanUp
(
	@OrigName varchar(2000)
)
RETURNS varchar(2000)
AS
BEGIN
	DECLARE @Result varchar(2000)

	Declare @OutName varchar(2000)

	set @OutName = ltrim(rtrim(@OrigName))

	select @OutName = case when s2.Code is not null then substring(x.OutName,1,len(x.OutName)-2) + '<ST>'
							when s1.Code is not null then '<ST>' + substring(x.OutName,3,500)
							else x.OutName end 
			from ( select @OutName OutName ) x				
				left outer join Lookups..States s1 on x.OutName like ltrim(rtrim(s1.Code)) + '%' and s1.code in ('MA','CT','ME','VT','NH','RI','NY')
				left outer join Lookups..States s2 on x.OutName like '%' + ltrim(rtrim(s2.Code)) and s2.code in ('MA','CT','ME','VT','NH','RI','NY')

	 declare @Pat varchar(500), @Code varchar(50), @Length int, @Ord int

	 declare @UseDate datetime = '1/1/2016'

	 while @UseDate <= getdate()
	 begin
		set @Pat = left(datename(month,@UseDate),3) + ltrim(str(year(@UseDate)))
		set @Code = '<TMY>'

		if @OutName like '%' + @Pat + '%'
			set @OutName = substring(@OutName,1,patindex('%' + @Pat + '%', @OutName)-1) + @Code + substring(@OutName, patindex('%' + @Pat + '%',@OutName) + Len(@Pat) , 500)

		set @UseDate = dateadd(mm,1,@UseDate)
	 end

     DECLARE curA CURSOR FOR
          	select '[0-9][0-9][0-9][0-9]20[0-9][0-9]' Pat, '<MMDDYYYY>' Code, 8 Length, 1 ord					
				union select '2018[0-9][0-9]' Pat, '<IW6>' Code, 6 Length, 2 ord										
				union select '[0-9][0-9]2018' Pat, '<IM2><IMY4>' Code, 6 Length, 3 ord
				union select '2018[0-9][0-9]' Pat, '<IW6>' Code, 6 Length, 4 ord					
				union select '18[0-9][0-9]' Pat, '<IW4>' Code, 4 Length, 5 ord
				union select '[0-9][0-9]18' Pat, '<IM2><IMY2>' Code, 4 Length, 6 ord
				union select 'Q[1-4]18' Pat, '<CP><CY2>' Code, 4 Length, 7 ord
				union select '2018' Pat, '<CY>' Code, 4 Length, 8 ord
				union select '2017' Pat, '<CY>' Code, 4 Length, 9 ord
				union select '2016' Pat, '<CY>' Code, 4 Length, 10 ord
				order by 4 

     OPEN curA

     FETCH NEXT FROM curA into @Pat, @Code, @Length, @Ord
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

		if @OutName like '%' + @Pat + '%'
			set @OutName = substring(@OutName,1,patindex('%' + @Pat + '%', @OutName)-1) + @Code + substring(@OutName, patindex('%' + @Pat + '%',@OutName) + @Length , 500)


          FETCH NEXT FROM curA into @Pat, @Code, @Length, @Ord
     END
     CLOSE curA
     DEALLOCATE curA

	 set @OutName = replace(@OutName,'MA-lbl','<ST>-lbl')

	RETURN @OutName 

END
