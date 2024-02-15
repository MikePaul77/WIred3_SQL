/****** Object:  Procedure [dbo].[AddTo_VFPJobs_FileLayoutFields_Corrections_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 11-07-2018
-- Description:	When you make changes to a transform layout, you can call this SP and pass the 
--				ShortFileLayoutName and the data will be preserved.  When the import from VFP runs,
--				the saved data will overwrite the imported data.
-- =============================================
CREATE PROCEDURE [dbo].[AddTo_VFPJobs_FileLayoutFields_Corrections] 
	@FileLayoutID int
AS
BEGIN
	SET NOCOUNT ON;

	Declare @ShortFileLayoutName nvarchar(100);
	Select @ShortFileLayoutName=ShortFileLayoutName 
		from JobControl..FileLayouts 
		where ID=@FileLayoutID;

	Delete from JobControl..VFPJobs_FileLayoutFields_Corrections
		Where ShortFileLayoutName=@ShortFileLayoutName;

	Insert into JobControl..VFPJobs_FileLayoutFields_Corrections(ShortFileLayoutName, OutOrder, 
		SortOrder, SortDir, OutType, OutWidth, SrcName, OutName, [Disabled], CaseChange, DoNotTrim, 
		Padding, PaddingLength, PaddingChar, VFPIn, DecimalPlaces)
	Select @ShortFileLayoutName as ShortFileLayoutName, OutOrder, SortOrder, SortDir, OutType, 
			OutWidth, SrcName, OutName, [Disabled], CaseChange, DoNotTrim, Padding,
			PaddingLength, PaddingChar, VFPIn, DecimalPlaces 
		from JobControl..FileLayoutFields
		Where FileLayoutID = @FileLayoutID
		Order by OutOrder;
END
