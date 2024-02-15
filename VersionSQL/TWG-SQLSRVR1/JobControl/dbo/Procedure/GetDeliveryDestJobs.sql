/****** Object:  Procedure [dbo].[GetDeliveryDestJobs]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetDeliveryDestJobs @JobID int, @DeliveryDestID int, @ShowOtherJobs bit
AS
BEGIN
	SET NOCOUNT ON;

	select j.JobID, j.JobName, coalesce(j.disabled,0) JobDisabled, j.TestMode JobTestMode
			,js.StepTypeID, js.StepOrder, js.StepID, coalesce(js.Disabled,0) JobStepDisabled, js.StepName
			, dd.ID DeliveryDestID, dd.DestType, dd.DestAddress
			, dd.FTPUserName, dd.FTPPassword, dd.FTPPath
			, dd.SourceType, dd.SourceID
			, dd.DisabledStamp
			, dd.DestName
			, dd.CreatedNote Note
			, ltrim(coalesce(C.FirstName,'') + ' ' + coalesce(c.LastName,'')) FullName
			, coalesce(co.CompanyName, c.GroupName) CompGrpName
			, case when @JobID = j.JobID then 1 else 2 end OrdCtl
			, coalesce(djs.EmailCC, 0) EmailCC
		from JobControl..Jobs j
			join JobControl..JobSteps js on j.JobID = js.JobID and js.StepTypeID in (1091,1115,1125)
			left outer join JobControl..DeliveryJobSteps djs on js.stepID = djs.JobStepID and djs.DisabledStamp is null
			left outer join JobControl..DeliveryDests dd on djs.DeliveryDestID = dd.ID
			left outer join OrderControl..Customers c on dd.sourceid = c.custID and dd.sourceType = 'Cust'
			left outer join OrderControl..Companies co on c.CompanyID = co.CompanyID

		where j.JobID = @JobID
			or djs.DeliveryDestID = @DeliveryDestID
			or (djs.DeliveryDestID in (select DeliveryDestID
											from JobControl..DeliveryJobSteps djs
												join JobControl..JobSteps js on js.stepID = djs.JobStepID
											where js.JobID = @JobID and djs.DisabledStamp is null)
				and @ShowOtherJobs = 1)
	union 
	select j.JobID, j.JobName, coalesce(j.disabled,0) JobDisabled, j.TestMode JobTestMode
			, null StepTypeID, 0 StepOrder, 0 StepID, null JobStepDisabled, null StepName
			, dd.ID DeliveryDestID, dd.DestType, dd.DestAddress
			, dd.FTPUserName, dd.FTPPassword, dd.FTPPath
			, dd.SourceType, dd.SourceID
			, dd.DisabledStamp
			, dd.DestName
			, dd.CreatedNote Note
			, ltrim(coalesce(C.FirstName,'') + ' ' + coalesce(c.LastName,'')) FullName
			, coalesce(co.CompanyName, c.GroupName) CompGrpName
			, case when @JobID = j.JobID then 1 else 2 end OrdCtl
			, coalesce(dj.EmailCC, 0) EmailCC
		from JobControl..Jobs j
			left outer join JobControl..DeliveryJobs dj on j.JobID = dj.JobID and dj.DisabledStamp is null
			left outer join JobControl..DeliveryDests dd on dj.DeliveryDestID = dd.ID
			left outer join OrderControl..Customers c on dd.sourceid = c.custID and dd.sourceType = 'Cust'
			left outer join OrderControl..Companies co on c.CompanyID = co.CompanyID

		where j.JobID = @JobID
			or dj.DeliveryDestID = @DeliveryDestID
			or (dj.DeliveryDestID in (select DeliveryDestID
											from JobControl..DeliveryJobSteps djs
												join JobControl..JobSteps js on js.stepID = djs.JobStepID
											where js.JobID = @JobID and djs.DisabledStamp is null)
				and @ShowOtherJobs = 1)
	order by case when @JobID = j.JobID then 1 else 2 end ,J.JobName, j.JobID, js.StepOrder, dd.DestAddress


END
