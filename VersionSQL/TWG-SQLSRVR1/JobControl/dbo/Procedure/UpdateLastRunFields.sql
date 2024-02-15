/****** Object:  Procedure [dbo].[UpdateLastRunFields]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 07-02-2020
-- Description:	Calculates the run time and start time for a SQL Agent Job and then updates JobControl..Jobs
-- =============================================
CREATE PROCEDURE UpdateLastRunFields
	@SQLJobID varchar(40)
AS
BEGIN
	SET NOCOUNT ON;

	-- Get Elapsed Time --
	Declare @eHours int=0, @eMinutes int=0, @eSeconds int=0, @elapsed varchar(8)
	Select @eSeconds=sum(last_run_duration) from msdb.dbo.sysjobsteps where job_id=@SQLJobID;
	if @eSeconds>=3600
	Begin
		set @eHours = @eSeconds/3600;
		set @eSeconds = @eSeconds - (@eHours * 3600);
	END
	if @eSeconds>=60
	Begin
		set @eMinutes = @eSeconds/60;
		set @eSeconds = @eSeconds - (@eMinutes * 60)
	End
	Set @elapsed = Right('00' + convert(varchar, @eHours),2) + ':' +
		Right('00' + convert(varchar, @eMinutes),2) + ':' +
		Right('00' + convert(varchar, @eSeconds),2);

	-- Get Start Time --
	Declare @DT datetime
	Select top 1 @DT=last_run_datetime from
	(select iif(last_run_date>0, msdb.dbo.agent_datetime(last_run_date,last_run_time), null) as [last_run_datetime]
	from msdb.dbo.sysjobsteps 
	where job_id=@SQLJobID
		and last_run_date>0) x
	order by last_run_datetime

	Update JobControl..Jobs set LastJobRunElapsedTime=@Elapsed, LastJobRunStartTime=@DT 
		where SQLJobID=@SQLJobID; 

END
