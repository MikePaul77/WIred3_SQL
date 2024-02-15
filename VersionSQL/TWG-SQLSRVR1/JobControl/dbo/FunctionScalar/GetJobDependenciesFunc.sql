/****** Object:  ScalarFunction [dbo].[GetJobDependenciesFunc]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.GetJobDependenciesFunc 
(
	@JobID int, @ParamCY varchar(50), @ParamCP varchar(50), @ParamIW varchar(50), @ParamIM varchar(50), @Action varchar(50)
)
RETURNS varchar(max)
AS
BEGIN
	DECLARE @result varchar(max)
	set @result = ''

	-- @Action can be
	-- 'Warn' - Shows parmeters of jobs this job is dependent on that do not match, returns '' is parameters match
	-- 'IsDependent' - returns # of jobs this job is dependent on
	-- 'HasDependent' - returns # of Jobs that are dependent on this job
	
	if @Action = 'Warn'
	begin
		select @result = case when tj.RecurringTypeID = 2 then		-- Issue Weekly
								case when fjpIW.ParamValue <> @ParamIW
									then 'Dependent Job parameters do not match: '
											+ char(10) + fj.JobName  + ' (' + ltrim(str(fj.JobID)) + ')' + ' IW:' + fjpIW.ParamValue end
							when tj.RecurringTypeID in (3,5,6) then		-- Issue Monthly, Calendar Quarterly, Calendar Annual
								case when fjpIM.ParamValue <> @ParamIM
									then 'Dependent Job parameters do not match: '
											+ char(10) + fj.JobName  + ' (' + ltrim(str(fj.JobID)) + ')' + ' IM:' + fjpIM.ParamValue end					when tj.RecurringTypeID = 4 then	-- Calendar Monthly
								case when (fjpCP.ParamValue <> @ParamCP or fjpCY.ParamValue <> @ParamCY)
									then 'Dependent Job parameters do not match: '
											+ char(10) + fj.JobName  + ' (' + ltrim(str(fj.JobID)) + ')' + ' CP:' + fjpCP.ParamValue + ' CY:' + fjpCY.ParamValue end
							else '' end 

			from JobControl..Jobs tj 
				left outer join JobControl..JobSteps tjs on tj.JobID = tjs.JobID and tjs.StepTypeID = 1103
				left outer join (select distinct ToJobStepID, FromJobStepID from JobControl..JobAddedFiles) jaf on jaf.ToJobStepID = tjs.StepID 
				left outer join JobControl..JobSteps fjs on fjs.StepID = jaf.FromJobStepID
				left outer join JobControl..Jobs fj on fj.JobID = fjs.JobID
				left outer join JobControl..JobParameters fjpCY on fjpCY.JobID = fjs.JobID and fjpCY.ParamName = 'CalYear'
				left outer join JobControl..JobParameters fjpCP on fjpCP.JobID = fjs.JobID and fjpCP.ParamName = 'CalPeriod'
				left outer join JobControl..JobParameters fjpIW on fjpIW.JobID = fjs.JobID and fjpIW.ParamName = 'IssueWeek'
				left outer join JobControl..JobParameters fjpIM on fjpIM.JobID = fjs.JobID and fjpIM.ParamName = 'IssueMonth'

			where tj.JobID = @JobID
		end

	if @Action = 'IsDependent'
	begin

		select @result = ltrim(str(count(distinct fj.jobID)))
				from JobControl..Jobs tj 
					left outer join JobControl..JobSteps tjs on tj.JobID = tjs.JobID and tjs.StepTypeID = 1103
					left outer join (select distinct ToJobStepID, FromJobStepID from JobControl..JobAddedFiles) jaf on jaf.ToJobStepID = tjs.StepID 
					left outer join JobControl..JobSteps fjs on fjs.StepID = jaf.FromJobStepID
					left outer join JobControl..Jobs fj on fj.JobID = fjs.JobID
				where tj.JobID = @JobID
	end

	if @Action = 'HasDependent'
	begin

		select @result = ltrim(str(count(distinct tj.jobID)))
				from JobControl..Jobs tj 
					left outer join JobControl..JobSteps tjs on tj.JobID = tjs.JobID and tjs.StepTypeID = 1103
					left outer join (select distinct ToJobStepID, FromJobStepID from JobControl..JobAddedFiles) jaf on jaf.ToJobStepID = tjs.StepID 
					left outer join JobControl..JobSteps fjs on fjs.StepID = jaf.FromJobStepID
					left outer join JobControl..Jobs fj on fj.JobID = fjs.JobID

				where fj.JobID = @JobID
	end

	RETURN @result

END
