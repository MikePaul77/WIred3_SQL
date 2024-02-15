/****** Object:  Procedure [dbo].[ChangeDeLEmail2Delv2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE ChangeDeLEmail2Delv2 @JobID int
AS
BEGIN
	SET NOCOUNT ON;
	declare @DelStepID int 
	declare @EMailStepID int

	select @DelStepID = StepID from JobControl..JobSteps where JobID = @JobID and StepTypeID = 1091

	select @EMailStepID = StepID from JobControl..JobSteps where JobID = @JobID and StepTypeID = 1115


	if @DelStepID > 0 

	begin

		update JobControl..JobSteps 
			set StepTypeID = 1125
					, CtlFiles2BothEmailFTP = 0
					, NoFilesEmailTemplateID = 7
					, Files2BothEmailFTP = 0
					, SentToFTPEmailTemplateID = 4
					, EmailTemplateID = 6
				where StepID = @DelStepID

		if @EMailStepID > 0
		begin

			update JobControl..DeliveryJobSteps set JobStepID = @DelStepID  where JobStepID = @EMailStepID

			delete JobControl..JobSteps where StepID = @EMailStepID

		end

	end

END
