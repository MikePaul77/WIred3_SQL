/****** Object:  Procedure [dbo].[CleanUpPreviousJobRunRemnantsByBatch]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.CleanUpPreviousJobRunRemnantsByBatch @BatchID int
AS
BEGIN
	SET NOCOUNT ON;
		Declare @TableName varchar(100), @TableCreated datetime

		Declare CleanUp_cursor cursor for
			SELECT t.[name] as TableName, t.create_date as TableCreated
			FROM JobControlWork.sys.tables t
				join JobControl..JobRunBatchJobs bj on t.[name] like '%_J'+ ltrim(str(bj.JobID)) + '_S%' and bj.BatchID = @BatchID
			order by create_date;

		Open CleanUp_cursor;
		Fetch next from CleanUp_cursor into @TableName, @TableCreated;
		While @@FETCH_STATUS=0
		Begin
			print 'Dropping: ' + @TableName + ' created ' + Convert(Varchar(15), @TableCreated, 1);
			EXECUTE ('DROP TABLE IF EXISTS JobControlWork.dbo.' + @TableName + ';');  
			Fetch next from CleanUp_cursor into @TableName, @TableCreated;
		End
		Close CleanUp_cursor;
		Deallocate CleanUp_cursor;


		delete ji
			from JobControl..JobInfo ji
				join JobControl..JobRunBatchJobs bj on ji.JobID = bj.JobID and bj.BatchID = @BatchID
	
		delete jsl
			from JobControl..JobStepLog jsl
				join JobControl..JobRunBatchJobs bj on jsl.JobID = bj.JobID and bj.BatchID = @BatchID

END
