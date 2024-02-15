/****** Object:  Procedure [dbo].[JobRunStatus]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JobRunStatus @JobID int
AS
BEGIN

	select * 
		from JobControl..vJobRunStatus
		where JobID = @JobID


END
