/****** Object:  ScalarFunction [dbo].[VFP_XFORMW3FieldRename]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION VFP_XFORMW3FieldRename 
(
	@W1FieldName varchar(100)
)
RETURNS varchar(100)
AS
BEGIN
	DECLARE @result varchar(100) 


	set @result = case when @W1FieldName = 'ASSDVALBLD' then 'ASSESSEDVALUEBUILDING'
						when @W1FieldName = 'ASSDVALLND' then 'ASSESSEDVALUELAND'
						when @W1FieldName = 'ASSDVALTOT' then 'ASSESSEDVALUETOTAL'
						when @W1FieldName = 'BASMNTAREA' then 'BASEMENTAREA'
						when @W1FieldName = 'BASMNTTD15' then 'BasementType'
						when @W1FieldName = 'BASMNTTYPE' then 'BasementTYPE'
						when @W1FieldName = 'BASMUFAREA' then 'BasementUnfinishedArea'
						when @W1FieldName = 'BATHROOMS' then 'NumBATHROOMS'
						when @W1FieldName = 'BEDROOMS' then 'NumBEDROOMS'
						when @W1FieldName = 'BUILDSTD12' then 'BuildingStyle'
						when @W1FieldName = 'BUILDSTYLE' then 'BUILDingSTYLE'
						when @W1FieldName = 'CARRIER_RT' then 'CARRIERRoute'
						when @W1FieldName = 'CMMNAREA' then 'CommonArea'
						when @W1FieldName = 'CNSSBLGR' then 'CensusBlock'
						when @W1FieldName = 'CNSSTRACT' then 'CensusTract'
						when @W1FieldName = 'CONDITID15' then 'CONDITION'
						when @W1FieldName = 'CONSTCOD10' then 'ConstructionType'
						when @W1FieldName = 'CONSTCODE' then 'ConstructionTypeID'
						when @W1FieldName = 'EXTCOVED15' then 'ExteriorCover'
						when @W1FieldName = 'FFLOORAREA' then 'FirstFLOORAREA'
						when @W1FieldName = 'FUELTYPED5' then 'FuelType'
						when @W1FieldName = 'FY' then 'FiscalYear'
						when @W1FieldName = 'GRBLDGAREA' then 'GrossBuildingArea'
						when @W1FieldName = 'HALFBATHS' then 'NumHALFBATHS'
						when @W1FieldName = 'HEATTYPD10' then 'HeatingType'
						when @W1FieldName = 'INACTVFL' then 'INActiveFlag'
						when @W1FieldName = 'LAT' then 'Latitude'
						when @W1FieldName = 'LIVAREA' then 'LivingArea'
						when @W1FieldName = 'LON' then 'Longitude'
						when @W1FieldName = 'LSTBOOK' then 'LastMtgBook'
						when @W1FieldName = 'LSTDDTYPE' then 'LastSaleDeedType'
						when @W1FieldName = 'LSTDOCREF' then 'LastSaleDocumentNum'
						when @W1FieldName = 'LSTLDR' then 'LastMtgLenderName'
						when @W1FieldName = 'LSTLNAME' then 'LastMtgLenderName'
						when @W1FieldName = 'LSTMTG' then 'LastMtgAmount'
						when @W1FieldName = 'LSTMTGDATE' then 'LastMtgDate'
						when @W1FieldName = 'LSTPAGE' then 'LastMtgPage'
						when @W1FieldName = 'LSTSLDATE' then 'LastSaleDate'
						when @W1FieldName = 'LSTSLPR' then 'LastSalePrice'
						when @W1FieldName = 'LSTSLTYPD2' then 'LastSaleType'
						when @W1FieldName = 'LSTSLTYPE' then 'LastSaleType'
						when @W1FieldName = 'LSTSLVALID' then 'LastIsValidSale'
						when @W1FieldName = 'MOD_LOTSIZ' then 'LotSize'
						when @W1FieldName = 'NUMFIREPL' then 'NumFirePlaces'
						when @W1FieldName = 'NUMPARKSP' then 'NumCarSpaces'
						when @W1FieldName = 'OWNER1FN' then 'Owner1FirstName'
						when @W1FieldName = 'OWNER1LN' then 'Owner1LastName'
						when @W1FieldName = 'OWNER2FN' then 'Owner2FirstName'
						when @W1FieldName = 'OWNER2LN' then 'Owner2LastName'
						when @W1FieldName = 'OWNERSTEXT' then 'OwnerStreetNumExt'
						when @W1FieldName = 'OWNERSTNUM' then 'OwnerStreetNum'
						when @W1FieldName = 'OWNERSTRT' then 'OwnerStreet'
						when @W1FieldName = 'OWNERUNIT' then 'OwnerUnitNumber'
						when @W1FieldName = 'OWNREL' then 'OwnerRelationship'
						when @W1FieldName = 'PARKTYPD15' then 'ParkingType'
						when @W1FieldName = 'PROPID' then 'ID'
						when @W1FieldName = 'RENOYEAR' then 'RENOvationYEAR'
						when @W1FieldName = 'RESOWNER' then 'ResidentOwner'
						when @W1FieldName = 'ROOFMATD15' then 'RoofMaterial'
						when @W1FieldName = 'ROOFTYPD10' then 'RoofType'
						when @W1FieldName = 'STATEUSD12' then 'UsageShort12'
						when @W1FieldName = 'STATEUSE' then 'Usage'
						when @W1FieldName = 'STNUM' then 'streetnumber'
						when @W1FieldName = 'STNUMEXT' then 'StreetNumberExtension'
						when @W1FieldName = 'TAXAMT' then 'TAXAmount'
						when @W1FieldName = 'TOTROOMS' then 'NumTotalROOMS'
						when @W1FieldName = 'UNIT' then 'UNITNumber'
						when @W1FieldName = 'ZIPCODE' then 'ZIP'

					else @W1FieldName end

	RETURN @result

END
