/****** Object:  ScalarFunction [dbo].[VFPImport_CodesToIDs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.VFPImport_CodesToIDs
(
	@CodeList varchar(4000), @IDType Varchar(50)
)
RETURNS varchar(4000)
AS
BEGIN
	DECLARE @result varchar(4000)
	set @result = ''

	 declare @ID int

	if @IDType = 'County'
	begin

		 DECLARE curA CURSOR FOR
			select Id 
				from Lookups..Counties c
				where @CodeList like '%"' + c.Code + '"%'
		 OPEN curA

		 FETCH NEXT FROM curA into @ID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				set @result = @result + ',' + ltrim(str(@ID))
			  FETCH NEXT FROM curA into @ID
		 END
		 CLOSE curA
		 DEALLOCATE curA
		 if @result > ''
			set @result = SUBSTRING(@result,2,4000)

	end	

	if @IDType = 'Town'
	begin

		 DECLARE curA CURSOR FOR
			select Id 
				from Lookups..Towns t
				where @CodeList like '%"' + t.Code + '"%'
		 OPEN curA

		 FETCH NEXT FROM curA into @ID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				set @result = @result + ',' + ltrim(str(@ID))
			  FETCH NEXT FROM curA into @ID
		 END
		 CLOSE curA
		 DEALLOCATE curA
		 if @result > ''
			set @result = SUBSTRING(@result,2,4000)

	end	

	if @IDType = 'UsageGroup'
	begin

		 DECLARE curA CURSOR FOR
			select Id 
				from Lookups..UsageGroups u
				where @CodeList like '%"' + u.GroupCode + '"%'
		 OPEN curA

		 FETCH NEXT FROM curA into @ID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				set @result = @result + ',' + ltrim(str(@ID))
			  FETCH NEXT FROM curA into @ID
		 END
		 CLOSE curA
		 DEALLOCATE curA
		 if @result > ''
			set @result = SUBSTRING(@result,2,4000)

	end	


	if @IDType = 'Use'
	begin

		 DECLARE curA CURSOR FOR
			select Id 
				from Lookups..Usage u
				where @CodeList like '%"' + u.Code + '"%'
		 OPEN curA

		 FETCH NEXT FROM curA into @ID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				set @result = @result + ',' + ltrim(str(@ID))
			  FETCH NEXT FROM curA into @ID
		 END
		 CLOSE curA
		 DEALLOCATE curA
		 if @result > ''
			set @result = SUBSTRING(@result,2,4000)

	end	

	if @IDType = 'TranType'
	begin

		 DECLARE curA CURSOR FOR
			select Id 
				from Lookups..TransactionTypes tt
				where @CodeList like '%"' + tt.Code + '"%'
		 OPEN curA

		 FETCH NEXT FROM curA into @ID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				set @result = @result + ',' + ltrim(str(@ID))
			  FETCH NEXT FROM curA into @ID
		 END
		 CLOSE curA
		 DEALLOCATE curA
		 if @result > ''
			set @result = SUBSTRING(@result,2,4000)

	end	

	if @IDType = 'DeedType'
	begin

		 DECLARE curA CURSOR FOR
			select Id 
				from Lookups..DeedTypes dt
				where @CodeList like '%"' + dt.Code + '"%'
		 OPEN curA

		 FETCH NEXT FROM curA into @ID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				set @result = @result + ',' + ltrim(str(@ID))
			  FETCH NEXT FROM curA into @ID
		 END
		 CLOSE curA
		 DEALLOCATE curA
		 if @result > ''
			set @result = SUBSTRING(@result,2,4000)

	end	

	if @IDType = 'Zip'
	begin
		declare @mark int
		declare @char varchar(5)
		set @result = ''
		set @mark = 1
		while @mark <= len(@CodeList)
		begin
			set @char = SUBSTRING(@CodeList,@mark,1)
			if @char like '[0-9]' or @char = ',' or @char = '-'
				set @result = @result + @char
			set @mark = @mark + 1
		end	
		 if SUBSTRING(@result,1,1) = ','
			set @result = SUBSTRING(@result,2,4000)
	end	

	if @IDType = 'Lender'
	begin
		 DECLARE curA CURSOR FOR
			select Id 
				from Lookups..Lenders l
				where @CodeList like '%"' + l.Code + '"%'
		 OPEN curA

		 FETCH NEXT FROM curA into @ID
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
				set @result = @result + ',' + ltrim(str(@ID))
			  FETCH NEXT FROM curA into @ID
		 END
		 CLOSE curA
		 DEALLOCATE curA
		 if @result > ''
			set @result = SUBSTRING(@result,2,4000)
	end	


	RETURN @result

END
