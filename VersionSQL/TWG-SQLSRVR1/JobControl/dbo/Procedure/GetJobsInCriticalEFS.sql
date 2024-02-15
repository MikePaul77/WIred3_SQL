/****** Object:  Procedure [dbo].[GetJobsInCriticalEFS]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE GetJobsInCriticalEFS
AS
BEGIN
	SET NOCOUNT off;

	
	
declare @SQLCode varchar(max), @EFID int, @SQLCMD varchar(max), @UnionLine varchar(50)
set @SQLCMD = '' 
set @unionLine = ''
             DECLARE curCritEFWatch CURSOR FOR

          select SQLCode, ID from JobControl..ExtendedFilters
			where IsCritical = 1 and coalesce(disabled, 0) != 1

OPEN curCritEFWatch
		FETCH NEXT FROM curCritEFWatch into @SQLCode, @EFID

     		WHILE (@@FETCH_STATUS <> -1)
     	BEGIN
			

			set @SQLCMD = @SQLCMD + @UnionLine + ' select ef.ID, ef.FilterName, x.JobID, j.JobName
												from 	 ('+@SQLCode+'
													) x
												join jobcontrol..extendedfilters EF on EF.ID = ' + LTrim(STR(@EFID)) + ' 
												join JobControl..jobs j on x.JOBID = j.JobID
											
												'
			set @unionline = ' union '
			FETCH NEXT FROM curCritEFWatch into @SQLCode, @EFID
     	END
	CLOSE curCritEFWatch     
	DEALLOCATE curCritEFWatch


	set @SQLCMD = @SQLCMD + ' order by 1'
	print @SQLCMD

	exec(@SQLCMD)


END
