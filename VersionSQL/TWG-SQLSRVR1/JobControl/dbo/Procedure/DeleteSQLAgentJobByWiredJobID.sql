/****** Object:  Procedure [dbo].[DeleteSQLAgentJobByWiredJobID]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 03-23-2019
-- Description:	Deletes a SQL Agent Job based on the Wired Job ID
-- =============================================
CREATE PROCEDURE DeleteSQLAgentJobByWiredJobID
	-- Add the parameters for the stored procedure here
	@JobID int
AS
BEGIN
	SET NOCOUNT ON;

	Declare @SQLJobID varchar(50);

	Select @SQLJobID=sj.job_id 
		from msdb.dbo.sysjobs sj 
			join JobControl..jobs j on sj.job_id=j.SQLJobID 
		where j.JobID=@JobID;

	if @SQLJobID is not null
		Exec msdb.dbo.sp_delete_job @Job_id=@SQLJobID;
END
