/****** Object:  Procedure [dbo].[PreZipCheck]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 03-18-2019
-- Description:	Make sure all of a job's documents exist and have been approved before starting the Zip process
-- =============================================
CREATE PROCEDURE dbo.PreZipCheck
	@ZipJobStepID int
AS
BEGIN

	SET NOCOUNT ON;

	Declare @LastJobLogID int, 
		@DependsOnStepIDs varchar(100), 
		@SQL varchar(max)

	-- Validate all of the reports exist and have been approved before zip step runs

	Select @DependsOnStepIDs=js.DependsOnStepIDs, @LastJobLogID=j.LastJobLogID
		from JobSteps js 
			join jobs j on j.JobID=js.JobID 
		where js.StepID=@ZipJobStepID

	Create table #ZipTemp(JobLogID int, JobStepID int, DocumentID int);

	-- Make sure the right number of documents exist based on the current Job.LastJobLogID
	set @SQL='Insert into #ZipTemp
				Select x.JobLogID, x.JobStepID, ' +
				'(Select Top 1 dm.DocumentID ' +
					'from DocumentLibrary..DocumentMaster dm ' +
					'where dm.JobStepID=x.JobStepID ' +
--						'and dm.OK2ReleaseDate is not null ' +
						'and dm.JobLogID=' + convert(varchar,@LastJobLogID) + ' ' +
						'order by dm.OK2ReleaseDate desc) as DocumentID ' +
				'FROM ' +
				'(Select distinct JobID, JobStepID, JobLogID ' +
				'From DocumentLibrary..DocumentMaster ' +
				'Where JobStepID in (' + @DependsOnStepIDs + ') ' +
				'	and JobLogID=' + convert(varchar,@LastJobLogID)+ ') x '
	Exec(@SQL);

	if exists(Select JobStepID from #ZipTemp where DocumentID is null)
		Select 0 as OK2Zip
	else
		Select 1 as OK2Zip;

	Drop table #ZipTemp
END
