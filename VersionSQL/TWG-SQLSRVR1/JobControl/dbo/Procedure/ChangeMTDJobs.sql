/****** Object:  Procedure [dbo].[ChangeMTDJobs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE ChangeMTDJobs @Action varchar(50), @JobID int, @Email Varchar(200)
AS
BEGIN
	SET NOCOUNT ON;

	Declare @DestID int
	Declare @DestDisabled bit

	Declare @JobStepID int

	select @JobStepID = StepID
		from JobControl..JobSteps
		where JobID = @JobID
			and StepTypeID = 1091

	if @Action = 'Enable'
		update JobControl..Jobs set disabled = 0, DisabledStamp = getdate() where JobID = @JobID
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

	

END
