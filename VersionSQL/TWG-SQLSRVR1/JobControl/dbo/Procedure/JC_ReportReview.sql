/****** Object:  Procedure [dbo].[JC_ReportReview]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 03-18-2019
-- Description:	Make sure all of a job's documents exist and have been approved before starting the Zip process
-- =============================================
CREATE PROCEDURE dbo.JC_ReportReview
	@ReportReviewStepID int
AS
BEGIN

	SET NOCOUNT ON;
	print 'Executing JobControl.dbo.JobControlStepUpdate ' + convert(varchar, @ReportReviewStepID) + ', Start'; 
	exec JobControl.dbo.JobControlStepUpdate @ReportReviewStepID, 'Start'

	Declare @LastJobLogID int, 
		@JobID int,
		@DependsOnStepIDs varchar(100), 
		@SQL varchar(max)

	-- Validate all of the reports exist and have been approved

	Select @DependsOnStepIDs=js.DependsOnStepIDs, @LastJobLogID=j.LastJobLogID, @JobID=j.JobID
		from JobSteps js 
			join jobs j on j.JobID=js.JobID 
		where js.StepID=@ReportReviewStepID

	Create table #RRTemp(JobLogID int, JobStepID int, DocumentID int);

	-- Make sure the right number of documents exist based on the current Job.LastJobLogID
	set @SQL='Insert into #RRTemp
				Select x.JobLogID, x.JobStepID, ' +
				'(Select Top 1 dm.DocumentID ' +
					'from DocumentLibrary..DocumentMaster dm ' +
					'where dm.JobStepID=x.JobStepID ' +
						'and dm.OK2ReleaseDate is not null ' +
						'and dm.JobLogID=' + convert(varchar,@LastJobLogID) + ' ' +
						'order by dm.OK2ReleaseDate desc ) as DocumentID ' +
				'FROM ' +
				'(Select distinct JobID, JobStepID, JobLogID ' +
				'From DocumentLibrary..DocumentMaster ' +
				'Where JobStepID in (' + @DependsOnStepIDs + ') ' +
				'	and JobLogID=' + convert(varchar,@LastJobLogID)+ ') x ';
	Print 'Executing: ' + @SQL;
	Exec(@SQL);

	if exists(Select JobStepID from #RRTemp where DocumentID is null)
		Begin
			--Insert into JobStepLog(JobId, JobStepID, LogInformation, LogInfoType, LogInfoSource, LogStamp)
			--	values(@JobID, @ReportReviewStepID, 
			--		'Not all report(s) for this review have been OK''d for Release.',1,
			--		'JobControl.dbo.JC_QueryStep', getdate());

			
			 
			exec JobControl.dbo.JobStepLogInsert @ReportReviewStepID, 1,'Not all report(s) for this review have been OK''d for Release.', 'JobControl.dbo.JC_QueryStep'

			exec JobControl.dbo.JobControlStepUpdate @ReportReviewStepID, 'Fail'
		End
	else
		Begin
			--Insert into JobStepLog(JobId, JobStepID, LogInformation, LogInfoType, LogInfoSource, LogStamp)
			--	values(@JobID, @ReportReviewStepID, 
			--		'All report(s) for this review have been OK''d for Release.',1,
			--		'JobControl.dbo.JC_QueryStep', getdate());

			exec JobControl.dbo.JobStepLogInsert @ReportReviewStepID, 1,'All report(s) for this review have been OK''d for Release.', 'JobControl.dbo.JC_QueryStep'

			exec JobControl.dbo.JobControlStepUpdate @ReportReviewStepID, 'Complete'
		End
	Drop table #RRTemp
END
