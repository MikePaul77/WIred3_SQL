/****** Object:  ScalarFunction [dbo].[DeliveryDestPreviewJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.DeliveryDestPreviewJob
(
	@JobID int
)
RETURNS varchar(max)
AS
BEGIN
	DECLARE @Result varchar(max)

--	select @Result = coalesce(@Result + char(10),'') + dd.destType + ': ' + dd.Destaddress
	select @Result = coalesce(@Result + char(10),'')
						+ JobControl.dbo.DeliveryDestSingleEntry(dd.destType, dj.EmailCC, dd.DestName, dd.DestAddress, dd.FTPPath, dd.FTPUserName)
	from JobControl..DeliveryJobs dj 
			left outer join JobControl..DeliveryDests dd on dj.DeliveryDestID = dd.ID and dd.destType = 'Email'
		where dj.JobID = @JobID 
			and dj.DisabledStamp is null
		order by dj.CreatedStamp

	RETURN @Result

END
