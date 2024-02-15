/****** Object:  Procedure [dbo].[GetEMailTemplatesForJobStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE GetEMailTemplatesForJobStep @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	select 'WithFiles' EmailMode
		, case when et.ID > 0 then et.ID else det.ID end ID
		, case when et.ID > 0 then et.Subject else det.Subject end Subject
		, case when et.ID > 0 then et.Body else det.Body end Body
	from JobControl..JobSteps js
		join JobControl..EmailTemplates det on det.DefaultWithFiles = 1
		left outer join JobControl..EmailTemplates et on js.EmailTemplateID = et.ID
	where js.StepID = @JobStepID
	union
	select 'NoFiles' EmailMode
			, case when et.ID > 0 then et.ID else det.ID end ID
			, case when et.ID > 0 then et.Subject else det.Subject end Subject
			, case when et.ID > 0 then et.Body else det.Body end Body
		from JobControl..JobSteps js
			join JobControl..EmailTemplates det on det.DefaultNoFiles = 1
			left outer join JobControl..EmailTemplates et on js.NoFilesEmailTemplateID = et.ID
		where js.StepID = @JobStepID
	union
	select 'SentToFTP' EmailMode
			, case when et.ID > 0 then et.ID else det.ID end ID
			, case when et.ID > 0 then et.Subject else det.Subject end Subject
			, case when et.ID > 0 then et.Body else det.Body end Body
		from JobControl..JobSteps js
			join JobControl..EmailTemplates det on det.DefaultFTPSent = 1
			left outer join JobControl..EmailTemplates et on js.SentToFTPEmailTemplateID = et.ID
		where js.StepID = @JobStepID


END
