/****** Object:  Procedure [dbo].[ExtendedFilterCounts2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.ExtendedFilterCounts2
AS
BEGIN
	SET NOCOUNT ON;

	exec JobControl..ExtendedFilterCountsUpdate 

	select ID, coalesce(Jobs,0) Jobs
		from JobControl..ExtendedFilters
				where coalesce(disabled,0) = 0
					and ID > 0
				order by ID

END
