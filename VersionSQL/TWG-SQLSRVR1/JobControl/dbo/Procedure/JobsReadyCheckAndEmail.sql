/****** Object:  Procedure [dbo].[JobsReadyCheckAndEmail]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JobsReadyCheckAndEmail
AS
BEGIN

	drop table if exists #ReadyJobs

	create table #ReadyJobs (
		JobPriority int
		, JobID int
		, JobName varchar(150)
		, JobStates varchar(200)
		, RecurringTypeID int
		, RecurType varchar(50)
		, InProduction bit
		, LastParam varchar(50)
		, RecurringTargetID int
	)

	INSERT INTO #ReadyJobs
	Exec JobCOntrol..RunnableJobs null, 'Details'

	declare @JobLine varchar(500)

     DECLARE curA CURSOR FOR
		select ' * ' + ltrim(str(rj.JobID)) + ' - ' + rj.JobName + '    ' + rj.RecurType 
				+ char(10) + '     LastParm: ' + rj.LastParam + '     LastRun: ' + case when j.LastJobRunStartTime is null then 'None' else convert(varchar(50),j.LastJobRunStartTime) end
			from #ReadyJobs rj
				Join JobControl..Jobs j on j.JobID = rj.JobID

     OPEN curA

	declare @JobsList varchar(max) = ''

     FETCH NEXT FROM curA into @JobLine
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

		set @JobsList = @JobsList + char(10) + @JobLine


          FETCH NEXT FROM curA into @JobLine
     END
     CLOSE curA
     DEALLOCATE curA

	print @JobsList

	drop table if exists #ReadyJobs


	EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'Fulfillment@thewarrengroup.com'
   ,@recipients = 'mpaul@thewarrengroup.com'
   ,@subject = 'Jobs Ready to be run'
   ,@body = @JobsList

END
