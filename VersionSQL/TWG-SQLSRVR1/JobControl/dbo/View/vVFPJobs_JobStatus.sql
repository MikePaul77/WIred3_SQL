/****** Object:  View [dbo].[vVFPJobs_JobStatus]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE VIEW dbo.vVFPJobs_JobStatus
AS

		select tts.JobID, jw.VFPJobID, jw.JobName, jw.CategoryCode, jw.JobTemplateCode JobType
				, coalesce(s.Developer,'??') Developer
				, case when s.AllStepsRun = 1 then 'Y' else null end AllStepsRun
				, case when s.DataIsGood = 1 then 'Y' else null end DataIsGood
				, case when s.ReportWritten = 1 then 'Y' else null end ReportWritten
				, case when s.RecordCountMatch = 1 then 'Y' else null end RecordCountMatch
				, case when s.FileNamesMatch = 1 then 'Y' else null end FileNamesMatch
				, s.SpeedInMinutes
				, case when s.OnHold = 1 then 'Y' else null end OnHold
				, s.Grouping
				, s.Comment
				, s.LastUpdated LastStatusUpdate
				, s.LastUpdatedBy LastStatusUpdateBy
				, tt.id XfromID, tt.ShortTransformationName XFromName, tj.Jobs XFormJObs
				, tts.MatchingXformSteps, jxs.XformSteps, jw.JobSteps, jr.ReportIDs
				, case when tts.JobID is null then vj.JOBID else null end VFPNewJobID
				, vj.DTCOMPLETE  W1LastRun
				, case when vj.DTMODIFIED > '1/9/2019 10:30 AM' then vj.DTMODIFIED else null end VFPJobModified
			from JobControl..TransformationTemplates tt
				join (
					select j.JobID, js.TransformationID, count(*) MatchingXformSteps
						from JobCOntrol..Jobs j
							join JobControl..JobSteps js on js.JobID = j.JobID
						where coalesce(j.IsTemplate,0) = 0 and js.TransformationID > 0	
						group by j.JobID, js.TransformationID
					) tts on tts.TransformationID = tt.id	
				join (
					select js.TransformationID, count(distinct j.JobID) Jobs
						from JobControl..Jobs j
							join JobControl..JobSteps js on js.JobID = j.JobID
						where coalesce(j.IsTemplate,0) = 0 and js.TransformationID > 0	
						group by js.TransformationID
					) tj on tj.TransformationID = tt.id
				join (
					select j.JobID, count(*) XformSteps 
						from JobCOntrol..Jobs j
							join JobControl..JobSteps js on js.JobID = j.JobID
						where coalesce(j.IsTemplate,0) = 0 and js.TransformationID > 0	
						group by j.JobID
					) jxs on jxs.JobID = tts.JobID
				join (
					select j.JobID, j.VFPJobID, count(*) JobSteps, j.JobName,  jc.Code CategoryCode
							, jt.JobTemplateCode, jt.JobID JobTemplateID
						from JobCOntrol..Jobs j
							join JobControl..JobSteps js on js.JobID = j.JobID
							left outer join JobControl..JobCategories jc on jc.ID = j.CategoryID
							left outer join (
												select j.JobID, j.JobName,  j.Type JobTemplateCode
													from JobCOntrol..Jobs j
												where coalesce(j.IsTemplate,0) = 1
											) jt on jt.JobID = j.JobTemplateID
						where coalesce(j.IsTemplate,0) = 0
						group by j.JobID, j.VFPJobID, j.JobName,  jc.Code, jt.JobTemplateCode, jt.JobID
					) jw on jw.JobID = tts.JobID
				left outer join (

					select a.JobID
							, case when a.ReportListID is not null then ltrim(str(a.ReportListID)) else '' end
							+ case when b.ReportListID is not null then ', ' + ltrim(str(b.ReportListID)) else '' end
							+ case when c.ReportListID is not null then ', ' + ltrim(str(c.ReportListID)) else '' end
							+ case when d.ReportListID is not null then ', ' + ltrim(str(d.ReportListID)) else '' end ReportIDs
						from (
							select JobID, ReportListID, ROW_NUMBER() OVER (PARTITION BY JobID ORDER BY ReportListID) Seq
								from (
									select distinct JobID, ReportListID
										from JobControl..JobSteps js
										where ReportListID > 0
									) x
							) a
							left outer join (
							select JobID, ReportListID, ROW_NUMBER() OVER (PARTITION BY JobID ORDER BY ReportListID) Seq
								from (
									select distinct JobID, ReportListID
										from JobControl..JobSteps js
										where ReportListID > 0
									) x
							) b on b.JobID = a.JobID and b.Seq = 2
							left outer join (
							select JobID, ReportListID, ROW_NUMBER() OVER (PARTITION BY JobID ORDER BY ReportListID) Seq
								from (
									select distinct JobID, ReportListID
										from JobControl..JobSteps js
										where ReportListID > 0
									) x
							) c on c.JobID = a.JobID and c.Seq = 3
							left outer join (
							select JobID, ReportListID, ROW_NUMBER() OVER (PARTITION BY JobID ORDER BY ReportListID) Seq
								from (
									select distinct JobID, ReportListID
										from JobControl..JobSteps js
										where ReportListID > 0
									) x
							) d on d.JobID = a.JobID and d.Seq = 4
						where a.Seq = 1

				) jr on jr.JobID = jw.JobID
				full outer join (
					select JobID, DTCOMPLETE, DTMODIFIED
						from DataLoad..Jobs_Jobs j
						where j.CATEGORY in (
								select distinct C.Code
									from JobControl..Jobs j
										join JobControl..JobCategories c on c.ID = j.CategoryID )
					) vj on vj.JOBID = jw.VFPJobID

				left outer join JobControl..VFPJobs_Status s on s.JobId = jw.JobID
		where (tts.JobID is not null or vj.DTMODIFIED > '1/9/2019 10:30 AM')
