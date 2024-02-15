/****** Object:  Procedure [dbo].[CleanUpPreviousJobRunRemnants2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.CleanUpPreviousJobRunRemnants2 @JobID int
AS
BEGIN
	SET NOCOUNT ON;
		Declare @TableName varchar(100), @TableCreated datetime

		Declare CleanUp_cursor cursor for
		SELECT [name] as TableName, create_date as TableCreated
		FROM JobControlWork.sys.tables
		where [name] like '%_J'+ ltrim(str(@JobID)) + '_S%'
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


		delete JobControl..JobInfo where JobID = @JobID
		delete JobControl..JobStepLog where JobID = @JobID


END
