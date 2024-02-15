/****** Object:  Procedure [dbo].[GetMTDJobs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetMTDJobs
AS
BEGIN
	SET NOCOUNT ON;

	select distinct j.JobName, j.JobID, coalesce(j.disabled,0) disabled
		, s.Code State
		, substring((select ', ' + t.FullName
				from QueryEditor..QueryLocations ql
					join Lookups..Towns t on t.id = ql.TownID
				where ql.QueryID = js.QueryCriteriaID and ql.TownID > 0
				order by t.FullName
				for XML path('') 
			),2,2000) Towns
		, substring((select '; ' + dd.DestAddress
				from JobControl..DeliveryJobSteps djs
					join JobControl..DeliveryDests dd on dd.id = djs.DeliveryDestID and dd.DisabledStamp is null
				where djs.JobStepID = js2.StepID and djs.DisabledStamp is null
				order by dd.DestAddress
				for XML path('') 
			),2,2000) emails
		from JobControl..Jobs j 
			join JobControl..JobSteps js on js.jobID = j.JobID and js.QueryCriteriaID > 0
			join JobControl..JobSteps js2 on js2.jobID = j.JobID and js2.StepTypeID in (1091,1125)
			left outer join QueryEditor..QueryLocations ql on ql.QueryID = js.QueryCriteriaID and ql.TownID > 0
			left outer join Lookups..Towns t on t.id = ql.TownID
			left outer join Lookups..States s on s.Id = t.StateID
		where j.CategoryID = 45
			and coalesce(j.deleted,0) = 0
		order by s.code, 5


END
