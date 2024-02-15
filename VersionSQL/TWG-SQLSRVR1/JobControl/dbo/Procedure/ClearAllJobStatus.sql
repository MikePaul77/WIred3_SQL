/****** Object:  Procedure [dbo].[ClearAllJobStatus]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE ClearAllJobStatus
AS
BEGIN
	SET NOCOUNT ON;
	
	update Jobs set RunAtStamp = null, StartedStamp = null, CompletedStamp = null, FailedStamp = null;

	update JobSteps set RunAtStamp = null, StartedStamp = null, CompletedStamp = null, FailedStamp = null;

END
