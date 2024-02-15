/****** Object:  Procedure [dbo].[JobReminderNotes]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JobReminderNotes
AS
BEGIN
	SET NOCOUNT ON;

	select *
		from (
			select n.Note, n.JobID, J.JobName, RecID
					, n.RemindOnAfterParam
					, case when convert(int,left(n.RemindOnAfterParam,2)) <= 12 then 999999
						else convert(int,n.RemindOnAfterParam) end ParamAsIW
					, case when convert(int,left(n.RemindOnAfterParam,2)) <= 12 then (convert(int,right(n.RemindOnAfterParam,4)) * 100 ) + convert(int,left(n.RemindOnAfterParam,2))
						else 999999 end ParamAsIMCM
					, IW.Issueweek
					, IM.IssueMonth, IM.SIssueMonth
					, CM.CalMonth, cm.SCalMonth
					, case when j.PromptIssueWeek = 1 then 'IW' when j.PromptIssueMonth = 1 then 'IM'
							when j.PromptCalPeriod = 1 then 'CP' else '' end PromptFor
				from JobControl..Notes n
					join JobControl..Jobs j on j.jobID = n.JobID
					join (select top 1 Issueweek
							from (
								select distinct Issueweek
								from Support..IssueWeeks
								where DataImportComplete is not null
							) x
						order by Issueweek desc
						) IW on 1=1 
					join (select top 1 IssueMonth, SortableIssueMonth SIssueMonth
							from Support..IssueMonth im
								join (
									select distinct Issueweek
									from Support..IssueWeeks
									where DataImportComplete is not null
								) x on x.Issueweek = im.EndWeek
							order by SortableIssueMonth desc
						) IM on 1=1 
					join (select top 1 IssueMonth CalMonth, SortableIssueMonth SCalMonth
							from Support..IssueMonth im
								where DataImportComplete is not null
							order by SortableIssueMonth desc
						) CM on 1=1 
				where n.RemindOnAfterParam > '' and coalesce(StopRemindOnAfter,0) = 0
		) x

	where (Issueweek >= ParamAsIW and x.PromptFor = 'IW')
		or (SIssueMonth >= ParamAsIMCM and x.PromptFor = 'IM') 
		or (SCalMonth >= ParamAsIMCM and x.PromptFor = 'CP') 
			
			
			
END
