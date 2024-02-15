/****** Object:  Procedure [dbo].[ClearJobParam]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE ClearJobParam @JobID int
AS
BEGIN
	SET NOCOUNT ON;

	delete JobControl..JobParameters 
		where StepID is null
			and ParamName = 'IssueWeek'
			and JobID = @JobID

END
