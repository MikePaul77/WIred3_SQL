/****** Object:  Procedure [dbo].[DeliveryDestPrev_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE DeliveryDestPrev @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	select dd.destType + ': ' + dd.Destaddress Dest
		from JobControl..DeliveryJobSteps djs 
			left outer join JobControl..DeliveryDests dd on djs.DeliveryDestID = dd.ID
		where djs.JobStepID = @JobStepID
			and djs.DisabledStamp is null
		order by djs.CreatedStamp


END
