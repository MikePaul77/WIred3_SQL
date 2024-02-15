/****** Object:  Procedure [dbo].[ExtendedFilterCountsUpdate]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.ExtendedFilterCountsUpdate
AS
BEGIN
	SET NOCOUNT ON;

	drop table if exists #JobList

	create table #JobList (JobID int null)

	Declare @EFID int, @SQLCode varchar(max)
     DECLARE curA CURSOR FOR
          select ID, SQLCode
			from ExtendedFilters
			where coalesce(disabled,0) = 0
				and ID > 0

     OPEN curA

     FETCH NEXT FROM curA into @EFID, @SQLCode
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
		
			if @SQLCode > ''
				begin
					Truncate table #JobList

					Set @SQLCode = 'insert #JobList (JobID) ' + @SQLCode;
					print @SQLCode
					Exec(@SQLCode);

					update ExtendedFilters 
							set Jobs = (select count(*) from #JobList)
								, CountStamp = getdate()
						where ID = @EFID

				end
			else
				begin

					update ExtendedFilters 
							set Jobs = (select count(*)
										from JobControl..ExtendedFiltersJobs efj
											join JobControl..Jobs j on efj.JobID = j.JobID and coalesce(j.Deleted,0) = 0
										where ExtendedFilterID = @EFID)
							, CountStamp = getdate()
						where ID = @EFID
				
				end


          FETCH NEXT FROM curA into @EFID, @SQLCode
     END
     CLOSE curA
     DEALLOCATE curA


END
