/****** Object:  ScalarFunction [dbo].[ReportAuthorizationNeeded]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 03/12/2019
-- Description:	Determine if the report needs to be audited/authorized to release
-- =============================================
CREATE FUNCTION ReportAuthorizationNeeded 
(
	@StepID int
)
RETURNS int
AS
BEGIN
	Declare @RetVal int=0,
		@JobId int,
		@StepOrder int

	Select @StepOrder=StepOrder, @JobID=JobID from JobControl..JobSteps where StepID=@StepID;
	if Exists(Select Top 1 StepID from JobControl..JobSteps where JobID=@JobID and StepOrder>@StepOrder and RunModeID<>1)
		set @RetVal=1;

	RETURN @RetVal

END
