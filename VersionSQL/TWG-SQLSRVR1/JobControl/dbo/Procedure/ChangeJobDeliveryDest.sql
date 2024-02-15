/****** Object:  Procedure [dbo].[ChangeJobDeliveryDest]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.ChangeJobDeliveryDest @Action varchar(50), @JobID int, @Email Varchar(200)
AS
BEGIN
	SET NOCOUNT ON;

	Declare @DestID int
	Declare @DestDisabled bit

	Declare @JobStepID int

	set @Email = replace(@Email,'''','''''');

	select @JobStepID = StepID
		from JobControl..JobSteps
		where JobID = @JobID
			and StepTypeID in (1091,1125)
			and StepID not in (38509) -- Probate JobSummary 2nd Delivery step shoul not be changed

	if @Action = 'Enable'
		update JobControl..Jobs set disabled = 0, DisabledStamp = getdate(), InProduction = 1 where JobID = @JobID
	if @Action = 'Disable'
		update JobControl..Jobs set disabled = 1, DisabledStamp = getdate() where JobID = @JobID
	if @Action = 'Add'
		Begin
			
			select @DestID = DD.ID
				from JobControl..DeliveryDests DD
				where DD.DestAddress = @Email
					and DD.DisabledStamp is null

			if @DestID is null
			Begin
				insert JobControl..DeliveryDests (DestType, DestAddress, CreatedStamp, CreatedByUser)
					values ('Email', @Email, getdate(), SYSTEM_USER)

				select @DestID = Max(ID)
					from JobControl..DeliveryDests where CreatedByUser = SYSTEM_USER

			end
				
			declare @ExistsCount int

			select @ExistsCount = count(*)
				from JobControl..DeliveryJobSteps
				where JobStepID = @JobStepID
					and DeliveryDestID = @DestID
					and DisabledStamp is null

			if @ExistsCount = 0
				insert JobControl..DeliveryJobSteps (DeliveryDestID, JobStepID, CreatedStamp, CreatedByUser)
					values (@DestID, @JobStepID, getdate(), SYSTEM_USER)

		end
	if @Action = 'Remove'
		Begin

			select @DestID = DD.ID
				from JobControl..DeliveryDests DD
				where DD.DestAddress = @Email
					and DD.DisabledStamp is null

			update JobControl..DeliveryJobSteps 
				set DisabledStamp = getdate(), DisabledByUser = SYSTEM_USER
				where JobStepID = @JobStepID
					and DeliveryDestID = @DestID
					and DisabledStamp is null
		end

	insert JobControl..JobEmailChangeLog (DestID, EmailAddr, ChangeStamp, UserName, JobID, StepID, Action)
			values (@DestID, @Email, getdate(), SYSTEM_USER, @JobID, @JobStepID, @Action)


END
