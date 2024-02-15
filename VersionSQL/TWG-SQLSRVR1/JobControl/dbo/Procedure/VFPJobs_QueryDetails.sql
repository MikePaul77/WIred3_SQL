/****** Object:  Procedure [dbo].[VFPJobs_QueryDetails]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobs_QueryDetails @QID int 
AS
BEGIN
	SET NOCOUNT ON;
	declare @cnt int

	Declare @QueryTemplateID int
	declare @QueryTemplateName varchar(500), @VFP_QueryID varchar(50), @QueryTemplateFromPart varchar(max)

	select @QueryTemplateID = q.TemplateID
			, @QueryTemplateName = qt.TemplateName
			, @QueryTemplateFromPart = qt.FromPart
			, @VFP_QueryID = coalesce(q.VFP_QueryID,'')
		from QueryEditor..Queries q
			join QueryTemplates qt on qt.Id = q.TemplateID 
			where q.ID = @QID

	print 'QueryTemplateID: ' + ltrim(str(@QueryTemplateID))
	print 'QueryTemplateName: ' + @QueryTemplateName
	print 'QueryTemplateFromPart: ' + @QueryTemplateFromPart
	print ''
	Print 'VFPBaseQueryID: ' + @VFP_QueryID

	if @VFP_QueryID > ''
	begin
			set @cnt = 1
			 print 'VFP Conditions'
			 declare @cond varchar(max)       
			 DECLARE curAConds CURSOR FOR
				select distinct cond 
					from JobControl..VFPJobs_Query_Conds where QUERY_ID = @VFP_QueryID

			 OPEN curAConds

			 FETCH NEXT FROM curAConds into @cond
			 WHILE (@@FETCH_STATUS <> -1)
			 BEGIN
					print '   ' + ltrim(str(@cnt)) + ': ' + @cond
					set @cnt = @cnt + 1
				  FETCH NEXT FROM curAConds into @cond
			 END
			 CLOSE curAConds
			 DEALLOCATE curAConds

	end

	print ''
	print 'W3 Conditions'
	Print '    Fields'
	declare @Fields varchar(max)
	select @Fields = ltrim(rtrim(case when LocationMailingList is not null then 'LocationMailingList = ' + case when LocationMailingList = 1 then '1' else '0' end else '' end
		 + ' ' + case when LocationOwnerRes is not null then 'LocationOwnerRes = ' + ltrim(str(LocationOwnerRes)) else '' end
		 + ' ' + case when LocationAddressDeliverabilityLevel is not null then 'LocationAddressDeliverabilityLevel = ' + ltrim(str(LocationAddressDeliverabilityLevel)) else '' end
		 + ' ' + case when LocationNameType is not null then 'LocationNameType = ' + ltrim(str(LocationNameType))  else '' end
		 + ' ' + case when TransTypeSales is not null then 'TransTypeSales = ' + case when TransTypeSales = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransTypeMortgages is not null then 'TransTypeMortgages = ' + case when TransTypeMortgages = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransIncludeMultiParcelTrans is not null then 'TransIncludeMultiParcelTrans = ' + case when TransIncludeMultiParcelTrans = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransExcludeMultiParcelTrans is not null then 'TransExcludeMultiParcelTrans = ' + case when TransExcludeMultiParcelTrans = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransSalesType is not null then 'TransSalesType = ' + TransSalesType  else '' end
		 + ' ' + case when TransSalesTypeOtherIncValidSales is not null then 'TransSalesTypeOtherIncValidSales = ' + case when TransSalesTypeOtherIncValidSales = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransSalesTypeOtherExcValidSales is not null then 'TransSalesTypeOtherExcValidSales = ' + case when TransSalesTypeOtherExcValidSales = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransSalesTypeOtherIncNominalSales is not null then 'TransSalesTypeOtherIncNominalSales = ' + case when TransSalesTypeOtherIncNominalSales = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransSalesTypeOtherExcNominalSales is not null then 'TransSalesTypeOtherExcNominalSales = ' + case when TransSalesTypeOtherExcNominalSales = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransSalesTypeOtherIncForclDeeds is not null then 'TransSalesTypeOtherIncForclDeeds = ' + case when TransSalesTypeOtherIncForclDeeds = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransSalesTypeOtherExcForclDeeds is not null then 'TransSalesTypeOtherExcForclDeeds = '  + case when TransSalesTypeOtherExcForclDeeds = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransSalesTypeOtherIncNonValidSales is not null then 'TransSalesTypeOtherIncNonValidSales = ' + case when TransSalesTypeOtherIncNonValidSales = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransSalesTypeOtherExcNonValidSales is not null then 'TransSalesTypeOtherExcNonValidSales = '  + case when TransSalesTypeOtherExcNonValidSales = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransPurchMoneyMtgsOnly is not null then 'TransPurchMoneyMtgsOnly = ' + case when TransPurchMoneyMtgsOnly = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransRefi2ndMtgsOnly is not null then 'TransRefi2ndMtgsOnly = ' + case when TransRefi2ndMtgsOnly = 1 then '1' else '0' end  else '' end
		 + ' ' + case when TransRefiHistory is not null then 'TransRefiHistory = ' + TransRefiHistory  else '' end
		 + ' ' + case when TransIntrestType is not null then 'TransIntrestType = ' + TransIntrestType  else '' end
		 + ' ' + case when BuildingAmenitiesIncludeExclude is not null then 'BuildingAmenitiesIncludeExclude = ' + BuildingAmenitiesIncludeExclude  else '' end
		 + ' ' + case when MtgAssignTransMatchingLevel is not null then 'MtgAssignTransMatchingLevel = ' + MtgAssignTransMatchingLevel  else '' end
		 + ' ' + case when MtgDischargeTransMatchingLevel is not null then 'MtgDischargeTransMatchingLevel = ' + MtgDischargeTransMatchingLevel  else '' end
		 + ' ' + case when ExcludeVirtualProperties is not null then 'ExcludeVirtualProperties = ' + case when ExcludeVirtualProperties = 1 then '1' else '0' end  else '' end))
	from QueryEditor..Queries
	 where ID = @QID
	 if len(@Fields) > 0
		print '        ' + @Fields
	 else
		print '        None'


	declare @StateID int, @ZipCode varchar(10), @CountyID int, @TownID int, @Exclude bit
	Print '    Locations'
	set @cnt = 1
	DECLARE curAConds CURSOR FOR
		select StateID, ZipCode, CountyID, TownID, coalesce(Exclude,0)
			from QueryEditor..QueryLocations where QueryID = @QID
		
	OPEN curAConds

	FETCH NEXT FROM curAConds into @StateID, @ZipCode, @CountyID, @TownID, @Exclude
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		print '       ' + ltrim(str(@cnt)) + ': ' 
					+ case when @Exclude = 1 then 'Exclude ' else 'Include ' end 
					+ case when @StateID is not null then 'StateID: ' + ltrim(str(@StateID))
						   when @ZipCode is not null then 'ZipCode: ' + ltrim(str(@ZipCode))
						   when @CountyID is not null then 'CountyID: ' + ltrim(str(@CountyID))
						   when @TownID is not null then 'TownIDe: ' + ltrim(str(@TownID))
						else '???' end
		set @cnt = @cnt + 1
		FETCH NEXT FROM curAConds into @StateID, @ZipCode, @CountyID, @TownID, @Exclude
	END
	CLOSE curAConds
	DEALLOCATE curAConds
	if @cnt = 1
		Print '        None'

	declare @ValueSource varchar(200), @ValueID int 
	Print '    MultIDs'
	set @cnt = 1
	DECLARE curAConds CURSOR FOR
		select ValueSource, ValueID, coalesce(Exclude,0)
			from QueryEditor..QueryMultIDs where QueryID = @QID
		
	OPEN curAConds

	FETCH NEXT FROM curAConds into @ValueSource, @ValueID, @Exclude
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		print '       ' + ltrim(str(@cnt)) + ': '
					+ case when @Exclude = 1 then 'Exclude ' else 'Include ' end 
					+ @ValueSource + ' = ' + ltrim(str(@ValueID))

		set @cnt = @cnt + 1
		FETCH NEXT FROM curAConds into @ValueSource, @ValueID, @Exclude
	END
	CLOSE curAConds
	DEALLOCATE curAConds
	if @cnt = 1
		Print '        None'

	declare @RangeSource varchar(200), @MinVal varchar(50), @MaxVal varchar(50)
	Print '    Ranges'
	set @cnt = 1
	DECLARE curAConds CURSOR FOR
		select RangeSource, MinValue, MaxValue
			from QueryEditor..QueryRanges where QueryID = @QID
		
	OPEN curAConds

	FETCH NEXT FROM curAConds into @RangeSource, @MinVal, @MaxVal
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		print '       ' + ltrim(str(@cnt)) + ': '
					+ @RangeSource + ' between ' + @MinVal + ' and ' + @MaxVal

		set @cnt = @cnt + 1
		FETCH NEXT FROM curAConds into @RangeSource, @MinVal, @MaxVal
	END
	CLOSE curAConds
	DEALLOCATE curAConds
	if @cnt = 1
		Print '        None'


END
