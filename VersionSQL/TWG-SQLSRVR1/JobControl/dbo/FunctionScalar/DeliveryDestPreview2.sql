/****** Object:  ScalarFunction [dbo].[DeliveryDestPreview2]    Committed by VersionSQL https://www.versionsql.com ******/

create FUNCTION dbo.DeliveryDestPreview2
(
	@JobStepID int, @WithPassword bit
)
RETURNS varchar(max)
AS
BEGIN
	DECLARE @Result varchar(max)

--	select @Result = coalesce(@Result + char(10),'') + dd.destType + ': ' + dd.Destaddress
	select @Result = coalesce(@Result + char(10),'')
						+ JobControl.dbo.DeliveryDestSingleEntry(dd.destType, djs.EmailCC, dd.DestName, dd.DestAddress, dd.FTPPath, dd.FTPUserName)
						+ case when dd.FTPPassword > '' and @WithPassword = 1 then ' Pwd: ' + dd.FTPPassword else '' end
		from JobControl..DeliveryJobSteps djs 
			left outer join JobControl..DeliveryDests dd on djs.DeliveryDestID = dd.ID
		where djs.JobStepID = @JobStepID 
			and djs.DisabledStamp is null
		order by djs.CreatedStamp

	RETURN @Result

END
