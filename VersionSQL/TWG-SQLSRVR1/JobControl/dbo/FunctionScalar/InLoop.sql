/****** Object:  ScalarFunction [dbo].[InLoop]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 03-06-2020
-- Description:	Determines if the Job StepID passed is within a loop in a job.
--				If the job StepID is within a loop, 1 is returned.
-- =============================================
CREATE FUNCTION dbo.InLoop
(
	@JobStepID int
)
RETURNS int
AS
BEGIN

Declare @MaxBeginStep int,
	@MaxEndStep int,
	@CurrentStepOrder int,
	@CurrentStepTypeID int,
	@JobID int,
	@WithinLoop int = 0;

select @CurrentStepOrder=StepOrder, @JobID=JobID, @CurrentStepTypeID=StepTypeID
	from JobSteps where StepID=@JobStepID;

if @CurrentStepTypeID in (1107, 1108)
	set @WithinLoop=1
else
	Begin
		Select Top 1 @MaxEndStep=StepOrder
			From JobControl..JobSteps
			Where JobID=@JobID
				And StepOrder>@CurrentStepOrder
				And StepTypeID=1108
			Order by StepOrder;

		if @MaxEndStep is not null
			Begin
				Select Top 1 @MaxBeginStep=StepOrder
					From JobControl..JobSteps
					Where JobID=@JobID
						And StepOrder>@CurrentStepOrder
						And StepTypeID=1107
					Order by StepOrder;
				If isnull(@MaxBeginStep,0)=0 or isnull(@MaxBeginStep,0)>@MaxEndStep
					set @WithinLoop=1
			End
	End

	Return @WithinLoop;

END
