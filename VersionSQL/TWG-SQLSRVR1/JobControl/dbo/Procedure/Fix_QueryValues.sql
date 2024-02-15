/****** Object:  Procedure [dbo].[Fix_QueryValues]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE Fix_QueryValues @Mode varchar(50), @QueryID int, @v1 varchar(max), @v2 varchar(max), @Type varchar(50), @Exclude bit
AS
BEGIN
	SET NOCOUNT ON;

	set @v1 = ltrim(rtrim(coalesce(@v1,'')))
	set @v2 = ltrim(rtrim(coalesce(@v2,'')))
	set @Exclude = coalesce(@Exclude,0)

	if @Mode = 'Range'
	begin
		update QueryEditor..QueryRanges
			set MinValue = @v1, MaxValue = @v2, Exclude = @Exclude
		where queryID = @QueryID
			and RangeSource = @Type
		if @@ROWCOUNT = 0
		begin
			insert QueryEditor..QueryRanges (QueryID, RangeSource, MinValue, MaxValue, Exclude)
			values (@QueryID, @Type, @v1, @v2, @Exclude)
		end
	end

	--if @Mode = 'Location'
	--begin
	--end

	if @Mode = 'Multi'
	begin

		delete QueryEditor..QueryMultIDs 
			where queryID = @QueryID
				and ValueSource = @Type

		insert QueryEditor..QueryMultIDs (QueryID, ValueSource, ValueID, Exclude)
		select distinct @QueryID, @Type, x.value, @Exclude
			from Support.FuncLib.SplitString(@v1,',') x

	end

END
