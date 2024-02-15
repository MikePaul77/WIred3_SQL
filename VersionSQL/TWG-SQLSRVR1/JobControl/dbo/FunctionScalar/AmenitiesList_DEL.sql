/****** Object:  ScalarFunction [dbo].[AmenitiesList_DEL]    Committed by VersionSQL https://www.versionsql.com ******/

create FUNCTION AmenitiesList
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

	set @result = SUBSTRING( case when @Porch = 1 then ';Porch' else '' end 
								+ case when @PorchOpen = 1 then ';PorchOpen' else '' end
								+ case when @PorchCovered = 1 then ';PorchCovered' else '' end 
								+ case when @PorchEnclosed = 1 then ';PorchEnclosed' else '' end
								+ case when @Deck = 1 then ';Deck' else '' end 
								+ case when @TerraceOrPatio = 1 then ';TerraceOrPatio' else '' end 
								+ case when @Balcony = 1 then ';Balcony' else '' end 
								+ case when @Breezeway = 1 then ';Breezeway' else '' end 
								+ case when @PoolInground = 1 then ';PoolInground' else '' end 
								+ case when @Greenhouse = 1 then ';Greenhouse' else '' end 
								+ case when @TennisCourt = 1 then ';TennisCourt' else '' end 
								+ case when @Outbuildings = 1 then ';Outbuildings' else '' end 
								+ case when @CarriageHouse = 1 then ';CarriageHouse' else '' end 
								+ case when @DockOrPier = 1 then ';DockOrPier' else '' end 
								+ case when @Waterfront = 1 then ';Waterfront' else '' end 
								+ case when @Attic = 1 then ';Attic' else '' end 
								+ case when @Pantry = 1 then ';Pantry' else '' end 
								+ case when @DenOrLibrary = 1 then ';DenOrLibrary' else '' end 
								+ case when @RecreationRoom = 1 then ';RecreationRoom' else '' end 
								+ case when @AirConditioned = 1 then ';AirConditioned' else '' end 
								+ case when @Sauna = 1 then ';Sauna' else '' end 
								+ case when @Jacuzzi = 1 then ';Jacuzzi' else '' end 
								+ case when @SepticSystem = 1 then ';SepticSystem' else '' end 
								+ case when @WellWater = 1 then ';WellWater' else '' end 
								+ case when @IngroundOilTank = 1 then ';IngroundOilTank' else '' end 
								+ case when @SecuritySystem = 1 then ';SecuritySystem' else '' end 
								+ case when @WoodStove = 1 then ';WoodStove' else '' end 
								+ case when @Elevator = 1 then ';Elevator' else '' end 
								+ case when @LoadingDock = 1 then ';LoadingDock' else '' end 
								+ case when @IrregularLot = 1 then ';IrregularLot' else '' end 
								+ case when @Studio = 1 then ';Studio' else '' end 
								+ case when @Pool = 1 then ';Pool' else '' end 
								+ case when @CentralVacuum = 1 then ';CentralVacuum' else '' end ,2,500)

	RETURN @result
END
