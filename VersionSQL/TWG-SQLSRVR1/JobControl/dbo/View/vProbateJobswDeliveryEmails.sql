/****** Object:  View [dbo].[vProbateJobswDeliveryEmails]    Committed by VersionSQL https://www.versionsql.com ******/

create view dbo.vProbateJobswDeliveryEmails
AS

	select j.JobID, j.JobName
		, (SELECT STRING_AGG (dd.DestAddress, '; ')
				from JobControl..DeliveryJobSteps djs
					join JobControl..DeliveryDests dd on dd.id = djs.DeliveryDestID
				where djs.JobStepID = js.StepID and djs.DisabledStamp is null ) emails
	from JobControl..Jobs j
		join JobControl..JobSteps js on js.JobID = j.jobID and js.StepTypeID = 1125
	where j.CategoryID = 47
		and coalesce(j.disabled,0) = 0 and coalesce(j.Deleted,0) = 0 and coalesce(j.IsTemplate,0) = 0
