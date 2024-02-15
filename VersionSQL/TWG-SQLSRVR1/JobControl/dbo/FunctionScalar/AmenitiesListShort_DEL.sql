/****** Object:  ScalarFunction [dbo].[AmenitiesListShort_DEL]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION [dbo].[AmenitiesListShort]
(@Porch bit
	, @PorchOpen bit
	, @PorchCovered bit
	, @PorchEnclosed bit
	, @Deck bit 
	, @TerraceOrPatio bit 
	, @Balcony bit 
	, @Breezeway bit 
	, @PoolInground bit 
	, @Greenhouse bit
	, @TennisCourt bit
	, @Outbuildings bit 
	, @CarriageHouse bit 
	, @DockOrPier bit
	, @Waterfront bit
	, @Attic bit
	, @Pantry bit
	, @DenOrLibrary bit 
	, @RecreationRoom  bit
	, @AirConditioned bit
	, @Sauna bit
	, @Jacuzzi bit
	, @SepticSystem bit 
	, @WellWater bit
	, @IngroundOilTank bit 
	, @SecuritySystem bit
	, @WoodStove bit 
	, @Elevator bit
	, @LoadingDock bit 
	, @IrregularLot bit 
	, @Studio bit
	, @Pool bit
	, @CentralVacuum bit )

RETURNS varchar(200)
AS
BEGIN
	DECLARE @result varchar(200)

	set @result = case when @CentralVacuum = 1 then '8' else '' end
				+ case when @Pool = 1 then '7' else '' end 
				+ case when @Studio = 1 then '6' else '' end 
				+ case when @IrregularLot = 1 then '5' else '' end 
				+ case when @LoadingDock = 1 then '4' else '' end 
				+ case when @Elevator = 1 then '3' else '' end 
				+ case when @WoodStove = 1 then '2' else '' end 
				+ case when @SecuritySystem = 1 then '1' else '' end 
				+ case when @IngroundOilTank = 1 then 'Z' else '' end 
				+ case when @WellWater = 1 then 'Y' else '' end 
				+ case when @SepticSystem = 1 then 'X' else '' end 
				+ case when @Jacuzzi = 1 then 'W' else '' end 
				+ case when @Sauna = 1 then 'V' else '' end 
				+ case when @AirConditioned = 1 then 'U' else '' end 
				+ case when @RecreationRoom = 1 then 'T' else '' end 
				+ case when @DenOrLibrary = 1 then 'S' else '' end 
				+ case when @Pantry = 1 then 'R' else '' end 
				+ case when @Attic = 1 then 'A' else '' end 
				+ case when @Waterfront = 1 then 'P' else '' end 
				+ case when @DockOrPier = 1 then 'O' else '' end 
				+ case when @CarriageHouse = 1 then 'M' else '' end 
				+ case when @Outbuildings = 1 then 'L' else '' end 
				+ case when @TennisCourt = 1 then 'K' else '' end 
				+ case when @Greenhouse = 1 then 'J' else '' end 
				+ case when @PoolInground = 1 then 'I' else '' end 
				+ case when @Breezeway = 1 then 'H' else '' end 
				+ case when @Balcony = 1 then 'G' else '' end 
				+ case when @TerraceOrPatio = 1 then 'F' else '' end 
				+ case when @Deck = 1 then 'E' else '' end 
				+ case when @PorchEnclosed = 1 then 'D' else '' end
				+ case when @PorchCovered = 1 then 'C' else '' end 
				+ case when @PorchOpen = 1 then 'B' else '' end
				+ case when @Porch = 1 then 'A' else '' end 

	set @result = ''
	RETURN @result
END
