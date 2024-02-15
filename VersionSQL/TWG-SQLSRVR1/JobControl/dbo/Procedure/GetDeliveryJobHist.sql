/****** Object:  Procedure [dbo].[GetDeliveryJobHist]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetDeliveryJobHist @JobID int
AS
BEGIN
	SET NOCOUNT ON;

	select djs.CreatedStamp Stamp, djs.CreatedByUser ByUser, 'Added' Act, djs.DeliveryDestID, djs.CreatedNote Note, convert(varchar(10),'Job Step') HistType
		from JobControl..DeliveryJobSteps djs
			join JobControl..JobSteps js on js.StepID = djs.JobStepID
			join JobControl..DeliveryDests dd on dd.ID = djs.DeliveryDestID
		where js.JobID = @JobID
			and dd.CreatedStamp is not null
	union select djs.DisabledStamp Stamp, djs.DisabledByUser ByUser, 'Removed' Act, djs.DeliveryDestID, djs.DisabledNote Note, convert(varchar(10),'Job Step') HistType
		from JobControl..DeliveryJobSteps djs
			join JobControl..JobSteps js on js.StepID = djs.JobStepID
			join JobControl..DeliveryDests dd on dd.ID = djs.DeliveryDestID
		where js.JobID = @JobID
			and djs.DisabledStamp is not null
	union select dj.CreatedStamp Stamp, dj.CreatedByUser ByUser, 'Added' Act, dj.DeliveryDestID, dj.CreatedNote Note, convert(varchar(10),'Job') HistType
		from JobControl..DeliveryJobs dj
			join JobControl..DeliveryDests dd on dd.ID = dj.DeliveryDestID
		where dj.JobID = @JobID
			and dd.CreatedStamp is not null
	union select dj.DisabledStamp Stamp, dj.DisabledByUser ByUser, 'Removed' Act, dj.DeliveryDestID, dj.DisabledNote Note, convert(varchar(10),'Job') HistType
		from JobControl..DeliveryJobs dj
			join JobControl..DeliveryDests dd on dd.ID = dj.DeliveryDestID
		where dj.JobID = @JobID
			and dj.DisabledStamp is not null
	order by 1 desc


END
