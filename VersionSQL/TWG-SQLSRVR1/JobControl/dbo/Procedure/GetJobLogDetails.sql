/****** Object:  Procedure [dbo].[GetJobLogDetails]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetJobLogDetails @JobID int
AS
BEGIN
	SET NOCOUNT ON;

	select 10 OrderCtl, -1 OrderCtl2
				, LogStamp
				, LogInformation
				, case when LogInfoType = 3 then 'Error' else '' end LogLevel
				, coalesce(LogInfoSource,'') LogInfoSource
				, coalesce(LogInfoType, 1) LogInfoType
				, 'Error' LogType
				, JobID
			from JobControl..JobStepLog
			where JobID = @JobID
				and LogInfoSource not like 'Audit %'
				and LogInfoSource not like 'CountCheck: %'
				and LogInfoSource not like 'LocationCheck: %'
				and LogInfoType = 3 

	union
	select case when LogInfoSource like 'LocationCheck: %' and LogInfoType = 3 then 20
				when LogInfoSource like 'LocationCheck: %' and LogInfoType = 2 then 21
				when LogInfoSource like 'LocationCheck: %' and LogInfoType = 1 then 23
				when LogInfoSource like 'CountCheck: %' and LogInfoType = 3 then 20 
				when LogInfoSource like 'CountCheck: %' and LogInfoType = 2 then 21
				when LogInfoSource like 'CountCheck: %' and LogInfoType = 1 then 25 
				when LogInfoSource like 'Audit %' and LogInfoType = 3 then 20 
				when LogInfoSource like 'Audit %' and LogInfoType = 2 then 21
				when LogInfoSource like 'Audit %' and LogInfoType = 1 then 25 
					else 26 end	OrderCtl
				, case when LogInfoType = 3 then 10 when LogInfoType = 2 then 20 else 30 end OrderCtl2
				, LogStamp
				, LogInformation
				, case when LogInfoType = 3 then 'Stop'
						when LogInfoType = 2 then 'Warning'  else '' end LogLevel
				, coalesce(LogInfoSource,'') LogInfoSource
				, coalesce(LogInfoType, 1) LogInfoType
				, 'Audit' LogType
				, JobID
			from JobControl..JobStepLog
			where JobID = @JobID
				and (LogInfoSource like 'Audit %'
					or LogInfoSource like 'CountCheck: %'
					or LogInfoSource like 'LocationCheck: %')
	union
		select OrderCtl, OrderCtl2, Max(LogStamp) LogStamp
				, LogInformation, LogLevel, LogInfoSource, LogInfoType, LogType, JobID
			from (
			select case when LogInfoType = 3 then 21 else 24 end OrderCtl
						, case when jl.LogInfoType = 3 then 10 when jl.LogInfoType = 2 then 20 else 30 end OrderCtl2
						, jl.LogStamp
						, coalesce(replace(js.QueryPreview,char(10),char(10) + '<br>'),'') LogInformation
						, '' LogLevel
						, 'Query Criteria' LogInfoSource
						, coalesce(jl.LogInfoType, 1) LogInfoType
						, 'Audit' LogType
						, jl.JobID
					from JobControl..JobStepLog jl
						join JobControl..JobSteps js on js.JobID = jl.JobID 
													and js.StepTypeID in (1124,21)
					where jl.JobID = @JobID
						and jl.LogInfoSource like 'LocationCheck: %'
			) x
			group by OrderCtl, OrderCtl2, LogInformation, LogLevel, LogInfoSource, LogInfoType, LogType, JobID

	union 
	select 30 OrderCtl, -1 OrderCtl2
				, LogStamp
				, LogInformation
				, case when LogInfoType = 3 then 'Error' else '' end LogLevel
				, coalesce(LogInfoSource,'') LogInfoSource
				, coalesce(LogInfoType, 1) LogInfoType
				, 'JobInfo' LogType
				, JobID
			from JobControl..JobStepLog
			where JobID = @JobID
				and LogInfoSource not like 'Audit %'
				and LogInfoSource not like 'CountCheck: %'
				and LogInfoSource not like 'LocationCheck: %'

	order by 1, 2, 3

END
