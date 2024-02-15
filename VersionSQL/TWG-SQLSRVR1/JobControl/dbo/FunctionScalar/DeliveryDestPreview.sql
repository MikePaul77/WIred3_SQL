/****** Object:  ScalarFunction [dbo].[DeliveryDestPreview]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.DeliveryDestPreview
(
	@JobStepID int
)
RETURNS varchar(max)
AS
BEGIN
	DECLARE @Result varchar(max)

--	select @Result = coalesce(@Result + char(10),'') + dd.destType + ': ' + dd.Destaddress
	select @Result = coalesce(@Result + char(10),'')
						+ JobControl.dbo.DeliveryDestSingleEntry(dd.destType, djs.EmailCC, dd.DestName, dd.DestAddress, dd.FTPPath, dd.FTPUserName)
		from JobControl..DeliveryJobSteps djs 
			left outer join JobControl..DeliveryDests dd on djs.DeliveryDestID = dd.ID
		where djs.JobStepID = @JobStepID 
			and djs.DisabledStamp is null
		order by djs.CreatedStamp

	RETURN @Result

END
