/****** Object:  Procedure [dbo].[BatchRunJobs_Unused]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 03-03-2019
-- Description:	Batch Run W3 Jobs

	-- Exec JobControl..BatchRunJobs 'XPROD','MTDP','12','2018','',''
	-- Exec JobControl..BatchRunJobs Category, JobType, CalPeriod, CalYear, IssueMonth, IssueWeek

-- =============================================
CREATE PROCEDURE [dbo].[BatchRunJobs]
	@RunCategory varchar(10),	--'XPROD',
	@RunJobType varchar(10),	--'MTDP'
	@CalPeriod varchar(10),		--'12'
	@CalYear varchar(10),			--'2018'
	@IssueMonth varchar(10),		--MMYYYY 
	@IssueWeek varchar(10)			--YYYYww
AS
BEGIN
	SET NOCOUNT ON;

	Declare @JobID int,
		@PromptIssueMonth int,
		@PromptIssueWeek int,
		@PromptCalYear int,
		@PromptCalPeriod int

Print 'FILTERS ON FOR MA COMP JOBS!' ---- REMOVE AFTER TESTING --

	--Delete any previous records from JobParameters
	Delete from JobControl..JobParameters 
		where JobID in (select J.JobId from JobControl..Jobs J
							left Join JobControl..VFPJobs_ListOfJobs2Import v on j.VFPJobID=v.JobID
							where v.Category=@RunCategory and v.JobType=@RunJobType
								and isnull(j.disabled,0)=0 
								and j.JobName like '%MA %'		-- REMOVE AFTER TESTING --
								and j.jobname like '%Comp%'		-- REMOVE AFTER TESTING --
								and j.JobName not like '% CT %');	-- REMOVE AFTER TESTING --

	DECLARE BatchRun_cursor CURSOR FOR 
		SELECT J.JobId, j.PromptIssueMonth, j.PromptIssueWeek, j.PromptCalYear, j.PromptCalPeriod
			FROM JobControl..Jobs J
				left Join JobControl..VFPJobs_ListOfJobs2Import v on j.VFPJobID=v.JobID
			WHERE v.Category=@RunCategory and v.JobType=@RunJobType
				and isnull(j.disabled,0)=0
				and j.JobName like '%MA %'		-- REMOVE AFTER TESTING --
				and j.jobname like '%Comp%'		-- REMOVE AFTER TESTING --
				and j.JobName not like '% CT %'	-- REMOVE AFTER TESTING --
			ORDER by j.JobID;

	OPEN BatchRun_cursor;
	FETCH NEXT FROM BatchRun_cursor INTO @JobID, @PromptIssueMonth, @PromptIssueWeek, @PromptCalYear, @PromptCalPeriod
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		--Update the JobParameters
		if @PromptIssueMonth=1
			Insert into JobControl..JobParameters(JobID,ParamName,ParamValue) values(@JobID,'IssueMonth',@IssueMonth);
		if @PromptIssueWeek=1
			Insert into JobControl..JobParameters(JobID,ParamName,ParamValue) values(@JobID,'IssueWeek',@IssueWeek);
		if @PromptCalPeriod=1
			Insert into JobControl..JobParameters(JobID,ParamName,ParamValue) values(@JobID,'CalPeriod',@CalPeriod);
		if @PromptCalYear=1
			Insert into JobControl..JobParameters(JobID,ParamName,ParamValue) values(@JobID,'CalYear',@CalYear);

		--Create the SQL Agent Job if necessary
		Exec JobControl..BuildSQLAgentJob @JobID;

		--Add the job to JobLog
		Exec JobControl..ScheduleJobForThrottling @JobID, 5, '';
		FETCH NEXT FROM BatchRun_cursor INTO @JobID, @PromptIssueMonth, @PromptIssueWeek, @PromptCalYear, @PromptCalPeriod
	END
	CLOSE BatchRun_cursor  
	DEALLOCATE BatchRun_cursor 


END
