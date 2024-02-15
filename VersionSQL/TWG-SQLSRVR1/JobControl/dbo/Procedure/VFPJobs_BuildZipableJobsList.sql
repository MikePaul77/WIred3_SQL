/****** Object:  Procedure [dbo].[VFPJobs_BuildZipableJobsList]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE VFPJobs_BuildZipableJobsList
AS
BEGIN
	SET NOCOUNT ON;

	-- Run DOS CMD		dir \\TWGWired\WIRED\redp\output\*.zip /s /b >r:\zips.txt
	-- truncate table JobControl..VFPJobs_ZippedFiles
	-- import r:\zips.txt into JobControl..VFPJobs_ZippedFiles

		drop table JobControl..VFPJobs_ZippedFilesB

		select distinct j.JobID, j.JobName, jvs.OUTTABLE, zf.ZipFilePath
				, replace(zf.ZipFilePath,'\\TWGWired\WIRED\redp\output\','\') ZipMatch
				, replace(jvs.OUTTABLE,'\redp\output\','\') TgtMatch
				, replace(substring(replace(zf.ZipFilePath,'\\TWGWired\WIRED\redp\output\','\'),len(replace(zf.ZipFilePath,'\\TWGWired\WIRED\redp\output\','\')) - (CHARINDEX('\',REVERSE(replace(zf.ZipFilePath,'\\TWGWired\WIRED\redp\output\','\'))) - 2),500),'.zip','') ZipName
				, substring(replace(jvs.OUTTABLE,'\redp\output\','\'),len(replace(jvs.OUTTABLE,'\redp\output\','\')) - (CHARINDEX('\',REVERSE(replace(jvs.OUTTABLE,'\redp\output\','\'))) - 2),500) TgtName
			into JobControl..VFPJobs_ZippedFilesB
			from DataLoad..Jobs_jobsteps jvs
				join JobControl..Jobs j on j.VFPJobID = jvs.JOBID and j.VFPIn = 1
				join JobControl..VFPJobs_ZippedFiles zf on left(replace(zf.ZipFilePath,'\\TWGWired\WIRED\redp\output\','\'),len(replace(zf.ZipFilePath,'\\TWGWired\WIRED\redp\output\','\')) - CHARINDEX('\',REVERSE(replace(zf.ZipFilePath,'\\TWGWired\WIRED\redp\output\','\')))) = left(replace(jvs.OUTTABLE,'\redp\output\','\'),len(replace(jvs.OUTTABLE,'\redp\output\','\')) - CHARINDEX('\',REVERSE(replace(jvs.OUTTABLE,'\redp\output\','\'))))
			where jvs.FILEALGORITHM > '' and jvs.OUTTABLE > ''
		--		and zf.ZipFilePath like '%Cubell%'

		insert JobControl..VFPJobs_ZippedJobs (JobID)
			select distinct n.JOBID
				FROM JobControl..VFPJobs_ZippedFilesB n
					left outer join JobControl..VFPJobs_ZippedJobs p on p.JobID = n.JObID 
				where p.JobID is null
					and (DataLoad.dbo.PctMatch(n.TgtName, n.ZipName) >= 80
						or n.ZipFilePath like '%Cubell%')
					

END
