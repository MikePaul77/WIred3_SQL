/****** Object:  Procedure [dbo].[GetNextScheduledJob]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 09-30-2018
-- Description:	Gets the next Scheduled Job to run
-- =============================================
CREATE PROCEDURE dbo.GetNextScheduledJob
AS
BEGIN
	SET NOCOUNT ON;
	
	Declare @ID int, 
		@JobID int = 0, 
		@JobName varchar(100);

	Select top 1 @ID=s.ID, @JobID=s.JobID, @JobName=j.JobName
		from JobLog s
			join jobs j on s.JobId=s.JobId
		Where s.StartTime is null and s.CancelTime is null
		Order by s.RunPriority, s.QueueTime;

	if isnull(@JobID, 0)<>0
		Update JobLog
			set StartTime=GetDate()
			Where ID=@ID;

	Select isnull(@JobID, 0) as NextJob, isnull(@JobName, '') as NextJobName;
END
