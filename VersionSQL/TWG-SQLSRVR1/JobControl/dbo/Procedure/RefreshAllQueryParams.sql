/****** Object:  Procedure [dbo].[RefreshAllQueryParams]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE RefreshAllQueryParams @JobID int
AS
BEGIN
	SET NOCOUNT ON;

	--### Only for Version 3+ Queries

	declare @DefaultQueryParamVersion int
	select @DefaultQueryParamVersion = Value from JobControl..Settings where Property = 'DefaultQueryParamVersion'

	declare @QueryID int

     DECLARE curQID CURSOR FOR
		select q.ID
			from JobControl..JobSteps js
				join QueryEditor..Queries q on q.ID = js.QueryCriteriaID
				where js.JobID = @JobID
					and coalesce(js.Disabled,0) = 0
					and coalesce(q.QueryParamVersion,@DefaultQueryParamVersion) >= 3

     OPEN curQID

     FETCH NEXT FROM curQID into @QueryID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
			
			print @QueryID

			delete QueryEditor..QueryRanges where QueryID = @QueryID and RangeSource = 'StateModIssueWeek'

			insert QueryEditor..QueryRanges (QueryID, RangeSource, MinValue, MaxValue)
			select @QueryID, 'StateModIssueWeek', jpW.ParamValue, jpW.ParamValue
				from JobControl..JobParameters jpW
					where jpW.JobID = @JobID 
						and jpW.ParamName in ('IssueWeek') 


          FETCH NEXT FROM curQID into @QueryID
     END
     CLOSE curQID
     DEALLOCATE curQID


END
