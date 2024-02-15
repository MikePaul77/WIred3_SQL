/****** Object:  Procedure [dbo].[RunableJobs_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[RunableJobs] 
AS
BEGIN
	SET NOCOUNT ON;

	create Table #UseJobs (JobID int null)

	insert #UseJobs (JobID)
	select JobID from JobControl..Jobs 
			where IsTemplate = 1 
				and Type in ('MTDE', 'MTDP' , 'NPSPRP', 'SEXTW' , 'SEXTM')

	select js.*, ss.*, ms.States, jd.*
		from (
			select distinct j.JobID, coalesce(zs.ID, t.StateID, c.StateID, ql.stateID) JobStateID
				from QueryEditor..QueryLocations ql
					join JobSteps js on js.QueryCriteriaID = ql.QueryID
					join JobControl..Jobs j on j.JobID = js.JobID and  coalesce(j.disabled,0) = 0
					left outer join Lookups..Counties c on ql.CountyID = c.ID
					left outer join Lookups..Towns t on ql.TownID = t.ID
					left outer join Support..Zip_5 z on ql.ZipCode = z.zipcode
					left outer join Lookups..States zs on zs.Code = z.state
				where coalesce(zs.ID, t.StateID, c.StateID, ql.stateID) > 0
					and J.JobTemplateID in (select JobID from #UseJobs)
			) js
		left outer join (
				select JobID, Count(*) States
					from (
						select distinct j.JobID, coalesce(zs.ID, t.StateID, c.StateID, ql.stateID) JobStateID
							from QueryEditor..QueryLocations ql
								join JobSteps js on js.QueryCriteriaID = ql.QueryID
								join JobControl..Jobs j on j.JobID = js.JobID and  coalesce(j.disabled,0) = 0
								left outer join Lookups..Counties c on ql.CountyID = c.ID
								left outer join Lookups..Towns t on ql.TownID = t.ID
								left outer join Support..Zip_5 z on ql.ZipCode = z.zipcode
								left outer join Lookups..States zs on zs.Code = z.state
							where coalesce(zs.ID, t.StateID, c.StateID, ql.stateID) > 0
								and J.JobTemplateID in (select JobID from #UseJobs)
						) x
					group by JobID
				) ms on ms.JobID = js.JobID
		left outer join (select s.Code, CIW.*, s.Mode
							from Lookups..States s
								left outer join ( select StateID, max(Issueweek) ClosedIssueWeek
													 from Support..IssueWeeks
													 where ConfirmedClosed = 1
													 group by StateID
													) CIW on s.Id = CIW.StateID
							where Mode in ('Bulk','Core')
						) ss on ss.StateID = js.JobStateID
		left outer join ( select j.jobID, j.JobName, rt.Description Recurance, rt.id RecuranceID
								, jp.ParamName ParamType
								, case when jp.ParamName = 'CalPeriod' then jp.ParamValue + ' ' + jp2.ParamValue
																				else jp.ParamValue end ParamValue
							from JobControl..Jobs j
								join JobControl..JobRecurringTypes rt on rt.ID = j.RecurringTypeID and rt.ID <> 7
								join JobControl..JobParameters jp on jp.JobID = j.JobID and ParamName in ('IssueWeek', 'IssueMonth','CalPeriod')
								left outer join JobControl..JobParameters jp2 on jp2.JobID = j.JobID and jp2.ParamName in ('CalYear')
							where coalesce(j.disabled,0) = 0
						) jd on jd.JobID = js.JobID
	where jd.RecuranceID = 2
	Order by ss.Code, ss.ClosedIssueWeek

--ID	Recurance	ParamType	ParamValue
--6	Calendar Annual	CalPeriod	12 2013
--6	Calendar Annual	IssueMonth	092018
--6	Calendar Annual	IssueWeek	201802
--4	Calendar Monthly	CalPeriod	07 2018
--5	Calendar Quarterly	CalPeriod	10 2018
--5	Calendar Quarterly	CalPeriod	Q3 2018
--5	Calendar Quarterly	CalPeriod	YR 2017
--3	Issue Monthly	CalPeriod	01 2019
--3	Issue Monthly	CalPeriod	YR 2018
--3	Issue Monthly	IssueMonth	012019
--3	Issue Monthly	IssueWeek	201844
--2	Issue Weekly	IssueWeek	201828




END
