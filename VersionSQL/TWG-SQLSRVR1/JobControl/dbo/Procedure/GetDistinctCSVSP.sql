/****** Object:  Procedure [dbo].[GetDistinctCSVSP]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE GetDistinctCSVSP 
	@SrcTable varchar(500), @SrcField varchar(100), @builtcsv varchar(max) output
AS
BEGIN
	SET NOCOUNT ON;

	create table #vals (val varchar(500) null)

	declare @cmd varchar(max)

	set @cmd = 'select distinct ' + @SrcField + ' from ' + @SrcTable + ' order by 1 '
	print @cmd

	insert into #vals execute (@cmd)

	set @builtcsv = ''

	select @builtcsv = COALESCE(@builtcsv + ',' ,'') + val
		from #vals
	
	if left(@builtcsv,1) = ','
		set @builtcsv = SUBSTRING(@builtcsv,2,4000)

END
