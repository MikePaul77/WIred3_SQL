/****** Object:  Procedure [dbo].[PrintJobIssueDate]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 9/1/2018
-- Description:	Gets the Issue Week for a report job
--				This is for a basic Query/Transform/Report job and assumes only 1 query in the job.
-- =============================================
CREATE PROCEDURE dbo.PrintJobIssueDate
	@JobID int
AS
BEGIN
	SET NOCOUNT ON;
	Declare @StateID int;
	Declare @IssueDate date;

	--Select @StateID=Q.StateID from QueryEditor..QueryLocations Q
	--	where QueryID=(	Select QueryCriteriaID from JobControl..JobSteps 
	--						where JobID=@JobID
	--						and QueryCriteriaID is not null)
	--	and StateID is not null

	Select @StateID = Q.StateID
		from QueryEditor..QueryLocations Q
			join JobControl..JobSteps js on js.JobID=@JobID 
										and q.QueryID = js.QueryCriteriaID
										and QueryCriteriaID is not null
		where q.StateID is not null

	Select Convert(varchar(10), IssueDate,101) as IssueDate
		from Support..IssueWeeks 
		where IssueWeek = (	Select Max(ParamValue)
								from JobControl..JobParameters 
								where JobID = @JobID 
									and ParamName = 'IssueWeek') 
			and State = (	Select Code from Lookups..states where ID=@StateId);
END
