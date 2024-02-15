/****** Object:  Procedure [dbo].[UpdateJobNames]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE UpdateJobNames @CustID int
AS
BEGIN
	SET NOCOUNT ON;


	 update Jobs set JobName = JobControl.dbo.GenAutoJobName(JobID)
					, UpdatedStamp = getdate()
      where CustID = @CustID
		and coalesce(disabled,0) = 0
		and coalesce(deleted,0) = 0


END
