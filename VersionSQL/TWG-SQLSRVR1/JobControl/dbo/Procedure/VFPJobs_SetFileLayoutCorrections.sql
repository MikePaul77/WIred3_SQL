/****** Object:  Procedure [dbo].[VFPJobs_SetFileLayoutCorrections]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 10-12-2018
-- Description:	Updates imported file layouts with corrections
-- =============================================
CREATE PROCEDURE dbo.VFPJobs_SetFileLayoutCorrections
AS
BEGIN
	SET NOCOUNT ON;
	
	Declare @ShortFileLayoutName nvarchar(100), @ID int

	Declare LayoutCursor CURSOR FOR
	Select Distinct c.ShortFileLayoutName,  f.ID 
		from JobControl..VFPJobs_FileLayoutFields_Corrections c
			join JobControl..FileLayouts F on f.ShortFileLayoutName=c.ShortFileLayoutName;

	Open LayoutCursor
	Fetch Next from LayoutCursor into @ShortFileLayoutName, @ID
	While @@FETCH_STATUS=0
	Begin
		print @ShortFileLayoutName + ' ' + convert(varchar(10), @ID)

		Delete from FileLayoutFields where FileLayoutID=@ID

		Insert into FileLayoutFields(FileLayoutID, OutOrder, SortOrder, SortDir, OutType, OutWidth,
				SrcName, OutName, [Disabled], CaseChange, DoNotTrim, Padding, PaddingLength, PaddingChar,
				VFPIn, DecimalPlaces)
		Select @ID as FileLayoutID, OutOrder, SortOrder, SortDir, OutType, OutWidth,
				SrcName, OutName, [Disabled], CaseChange, DoNotTrim, Padding, PaddingLength, PaddingChar,
				VFPIn, DecimalPlaces
			From JobControl..VFPJobs_FileLayoutFields_Corrections
			where ShortFileLayoutName = @ShortFileLayoutName
			order by OutOrder

		Fetch Next from LayoutCursor into @ShortFileLayoutName, @ID
	END

	Close LayoutCursor;
	Deallocate LayoutCursor;

	-- Code Added 11/16/2018 to update the Job Steps for Transform steps that use a new file layout.
	Create Table #LayoutTemp(VFPJobID int, StepOrder int, ShortFileLayoutName nvarchar(100),
	NewLayoutID int, TransformationTemplateID int, JobID int, OldLayoutID int, StepID int)

	Insert into #LayoutTemp(VFPJobID, StepOrder, ShortFileLayoutName, NewLayoutID, TransformationTemplateID, JobId)
	select x.VFPJobID, x.StepOrder, x.ShortFileLayoutName,F.ID as NewLayoutID, F.TransformationTemplateID, j.JobID
		from VFPJobs_JobSteps_NewFileLayoutID X
			left join FileLayouts F on x.ShortFileLayoutName=F.ShortFileLayoutName
			left join jobs j on x.VFPJobID=j.VFPJobID;

	Update L
		Set L.OldLayoutID=js.FileLayoutID,
			L.StepID=js.StepID
		From #LayoutTemp L
			Join JobSteps js on js.JobId=L.JobID and js.StepOrder=L.StepOrder;

	Delete from #LayoutTemp where NewLayoutID=OldLayoutID;

	Update JS
		Set JS.FileLayoutID = L.NewLayoutID
		From JobSteps JS
			Join #LayoutTemp L on L.StepID=JS.StepID;

	Drop Table #LayoutTemp;
END
