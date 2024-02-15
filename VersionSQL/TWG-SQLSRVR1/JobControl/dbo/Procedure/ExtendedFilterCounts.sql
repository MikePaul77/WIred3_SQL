/****** Object:  Procedure [dbo].[ExtendedFilterCounts]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE ExtendedFilterCounts
AS
BEGIN
	SET NOCOUNT ON;

	drop table if exists #EFCounts

	drop table if exists #JobList

	create table #EFCounts(ID int, Jobs int)

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

					insert #EFCounts (ID, Jobs)
						select @EFID, count(*)
							from #JobList
				end
			else
				begin

					insert #EFCounts (ID, Jobs)
						select @EFID, count(*)
							from JobControl..ExtendedFiltersJobs efj
								join JobControl..Jobs j on efj.JobID = j.JobID and coalesce(j.Deleted,0) = 0
							where ExtendedFilterID = @EFID
				
				end


          FETCH NEXT FROM curA into @EFID, @SQLCode
     END
     CLOSE curA
     DEALLOCATE curA

	 select * from #EFCounts order by ID

END
