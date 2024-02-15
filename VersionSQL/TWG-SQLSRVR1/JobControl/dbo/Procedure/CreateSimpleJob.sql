/****** Object:  Procedure [dbo].[CreateSimpleJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.CreateSimpleJob 
AS
BEGIN
	SET NOCOUNT ON;
	declare @NewJobID int = 0;

	exec JobControl..CreateSimpleJobTemplate

	declare @SimpleJobTemplateID int

	select @SimpleJobTemplateID = JobID from Jobs where JobName = 'Simple Job Template'

	exec JobControl..CreateNewJob @SimpleJobTemplateID

	select @NewJobID = Max(JobID) from Jobs where JobTemplateID = @SimpleJobTemplateID

	select @NewJobID NewJobID

END
