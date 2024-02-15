/****** Object:  Procedure [dbo].[AddTo_VFPJobs_JobSteps_NewFileLayoutID]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 11-14-2018
-- Description:	Log records that have a new non-VFP layout
-- =============================================
CREATE PROCEDURE AddTo_VFPJobs_JobSteps_NewFileLayoutID
	@StepID int,
	@FileLayoutID int
AS
BEGIN
	SET NOCOUNT ON;

	Declare @VFPJobID int,
			@StepOrder int,
			@VFPIn bit,
			@SFLN nvarchar(100);

	select @VFPJobID=j.VFPJobID, @StepOrder=js.StepOrder --, @FileLayoutID=js.FileLayoutID
		from JobSteps js
			join jobs j on j.jobid=js.jobid
		where js.StepID=@StepID 

	SELECT @VFPIn=VFPIn, @SFLN=ShortFileLayoutName from FileLayouts where ID=@FileLayoutID;
	if isnull(@VFPIn,0)=0
		-- This layout is not in VFP, so the data needs to be logged
		Begin
			Declare @SFLN2 nvarchar(100);
			Select @SFLN2=ShortFileLayoutName 
				from VFPJobs_JobSteps_NewFileLayoutID 
				where VFPJobID=@VFPJobID 
					and StepOrder=@StepOrder
			if @SFLN2 is null
				-- Data hasn't been logged yet. Insert a new record.	
				Insert into VFPJobs_JobSteps_NewFileLayoutID(VFPJobID, StepOrder, ShortFileLayoutName)
					Values(@VFPJobID, @StepOrder, @SFLN)
			else
				if @SFLN2<>@SFLN
					-- Layout has changed.  Update the record.
					Update VFPJobs_JobSteps_NewFileLayoutID
						Set ShortFileLayoutName=@SFLN, CreateDate=Getdate()
						Where VFPJobID=@VFPJobID 
							and StepOrder=@StepOrder
		End
	else
		-- This is a layout that is in VFP.  Delete the record if the layout was previously
		-- set to a non-VFP layout.
		Delete from VFPJobs_JobSteps_NewFileLayoutID
			Where VFPJobID=@VFPJobID 
				AND StepOrder=@StepOrder


END
