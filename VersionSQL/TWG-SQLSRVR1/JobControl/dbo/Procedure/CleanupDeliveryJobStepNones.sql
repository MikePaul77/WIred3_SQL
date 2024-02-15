/****** Object:  Procedure [dbo].[CleanupDeliveryJobStepNones]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE CleanupDeliveryJobStepNones @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @Nones int
	declare @Others int

	select @Nones = sum(case when DeliveryDestID = 0 then 1 else 0 end)
			, @Others = sum(case when DeliveryDestID > 0 then 1 else 0 end)
		from jobcontrol..DeliveryJobSteps 
		where JobstepID = @JobStepID and DisabledStamp is null


	if @Nones > 0 and @Others > 0
	begin

		delete jobcontrol..DeliveryJobSteps where JobstepID = @JobStepID and DeliveryDestID = 0

	end


END
