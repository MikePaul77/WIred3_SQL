/****** Object:  Procedure [dbo].[ReorderFileLayoutTemplate]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 4-7-2020
-- Description:	Updates FileLayoutFields for a Template and resets the OutOrder
-- =============================================
CREATE PROCEDURE dbo.ReorderFileLayoutTemplate 
	@CurrentID int
AS
BEGIN
	SET NOCOUNT ON;


	--Reorder the OutOrder
	SELECT row_number() OVER (ORDER BY OutOrder) NewOrder, RecID, OutOrder as CurrentOrder
		INTO #TempFLF
		FROM JobControl..FileLayoutFields
		WHERE FileLayoutID=@CurrentID;

	Update FLF
		Set FLF.OutOrder = T.NewOrder
		From JobControl..FileLayoutFields FLF
			join #TempFLF T on T.RecID=FLF.RecID;

	--Reorder the SortOrder
	SELECT row_number() OVER (ORDER BY SortOrder) NewOrder, RecID, SortOrder as CurrentOrder
		INTO #TempFLFs
		FROM JobControl..FileLayoutFields
		WHERE FileLayoutID=@CurrentID
			AND SortOrder>0;

	Update FLF
		Set FLF.SortOrder = T.NewOrder
		From JobControl..FileLayoutFields FLF
			join #TempFLFs T on T.RecID=FLF.RecID;

END
