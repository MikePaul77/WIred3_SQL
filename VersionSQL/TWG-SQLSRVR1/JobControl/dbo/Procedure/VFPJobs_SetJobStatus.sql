/****** Object:  Procedure [dbo].[VFPJobs_SetJobStatus]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobs_SetJobStatus 
	@JobID int
	, @Developer varchar(10)
	, @AllStepsRun bit
	, @DataIsGood bit
	, @ReportWritten bit
	, @RecordCountMatch bit
	, @FileNamesMatch bit
	, @SpeedInMinutes int
	, @OnHold bit
	, @Grouping varchar(50)
	, @Comment varchar(max)

AS
BEGIN
	SET NOCOUNT ON;

		insert JobControl..VFPJobs_Status (JobID, Developer)
		select j.JobID, '??' 
			from JobControl..Jobs j
				left outer join JobControl..VFPJobs_Status s on s.JobID = j.JobID
			where s.JobID is null

		update JobControl..VFPJobs_Status
			set Developer = coalesce(@Developer,Developer)
			, AllStepsRun = coalesce(@AllStepsRun,AllStepsRun)
			, DataIsGood = coalesce(@DataIsGood,DataIsGood)
			, ReportWritten = coalesce(@ReportWritten,ReportWritten)
			, RecordCountMatch = coalesce(@RecordCountMatch,RecordCountMatch)
			, FileNamesMatch = coalesce(@FileNamesMatch,FileNamesMatch)
			, SpeedInMinutes = coalesce(@SpeedInMinutes,SpeedInMinutes)
			, OnHold = coalesce(@OnHold,OnHold)
			, [Grouping] = coalesce(replace(@Grouping,'''',''''''),[Grouping])
			, Comment = coalesce(replace(@Comment,'''',''''''),Comment)
			where JobID = @JobID


END
