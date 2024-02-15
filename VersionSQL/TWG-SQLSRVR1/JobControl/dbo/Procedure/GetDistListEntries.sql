/****** Object:  Procedure [dbo].[GetDistListEntries]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetDistListEntries @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	select * 
		from JobControl..vDistList
		where JobStepID = @JobStepID
		order by case when ltrim(rtrim(coalesce(EmailName,''))) = '' then 10 else 1 end, EmailName, EmailAddress

END
