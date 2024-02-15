/****** Object:  Procedure [dbo].[GetJobEmails]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetJobEmails @JobID int
AS
BEGIN
	SET NOCOUNT ON;

	select substring((select '; ' + dd.DestAddress
				from JobControl..DeliveryJobSteps djs
					join JobControl..DeliveryDests dd on dd.id = djs.DeliveryDestID and dd.DisabledStamp is null and dd.DestType = 'Email'
				where djs.JobStepID = js2.StepID and djs.DisabledStamp is null
				order by dd.DestAddress
				for XML path('') 
			),2,2000) emails
		from JobControl..Jobs j 
			join JobControl..JobSteps js on js.jobID = j.JobID and js.QueryCriteriaID > 0
			join JobControl..JobSteps js2 on js2.jobID = j.JobID and js2.StepTypeID = 1091
		where J.JobID = @JobID
			and coalesce(j.deleted,0) = 0


END
