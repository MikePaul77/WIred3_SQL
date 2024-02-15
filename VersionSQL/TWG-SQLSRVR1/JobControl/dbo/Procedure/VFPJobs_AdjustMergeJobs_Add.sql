/****** Object:  Procedure [dbo].[VFPJobs_AdjustMergeJobs_Add]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobs_AdjustMergeJobs_Add @MaxJobID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @MergVFPJobID int, @MergJobID int, @PartVFPJobID int, @PartJobID int

	declare @LastMergJobID int = 0

	declare @MergeStepID int
	declare @MergeStepsList varchar(2000) = ''

	declare @StepID int, @StepTypeID int

     DECLARE curA CURSOR FOR
			select distinct j.JOBID MergVFPJobID, nj.JobID MergJobID, pj.JOBID PartVFPJobID, pnj.JobID PartJobID
				from DataLoad..Jobs_jobsteps js
					join DataLoad..Jobs_jobs j on j.JOBID = js.JOBID
					join JobControl..Jobs nj on nj.VFPJobID = j.JOBID
					join DataLoad..Jobs_jobsteps djs1 on djs1.OUTTABLE = js.OUTTABLE and djs1.JOBID <> js.JOBID
					join DataLoad..Jobs_jobs dj1 on dj1.JOBID = djs1.JOBID
					left outer join ( select js.JOBID, js.OUTTABLE, replace(replace(js.OUTTABLE,j.CURSTATE,'[A-Z][A-Z]'),'custo[A-Z][A-Z]r','me') MatchOutTable
								from DataLoad..Jobs_jobsteps js 
									join DataLoad..Jobs_jobs j on j.JOBID = js.JOBID
									join (
										select JobID, Max(stepID) LastStepID
												, Max(case when STEPTYPE = 'Appender' then StepID else null end) LastAppendStepID
												, Max(case when STEPTYPE = 'Reporter' then StepID else null end) LastReportStepID
											from DataLoad..Jobs_jobsteps
											group by JobID
											having Max(case when STEPTYPE = 'Reporter' then StepID else null end) is null
										) Dj on Dj.JOBID = j.JOBID
									where js.steptype = 'XFORM'
							) pj on js.OUTTABLE like pj.MatchOutTable or pj.JOBID = dj1.JOBID
					left outer join JobControl..Jobs pnj on pnj.VFPJobID = pj.JOBID
			

				where js.STEPTYPE = 'APPENDER' and js.stepID = 1
					and js.JOBID > @MaxJobID
				order by nj.JobID, pnj.JobID

     OPEN curA

     FETCH NEXT FROM curA into @MergVFPJobID, @MergJobID, @PartVFPJobID, @PartJobID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

			print ltrim(str(@MergJobID)) + ' - ' + ltrim(str(@PartJobID))

			if @LastMergJobID <> @MergJobID and @LastMergJobID > 0
			Begin
			
				update js set DependsOnStepIDs = case when ltrim(rs.DependsOnStepIDs) = ltrim(str(js.StepID)) and js.StepTypeID = 1 then substring(@MergeStepsList,2,2000) else null end
							, StepName = case when ltrim(rs.DependsOnStepIDs) = ltrim(str(js.StepID)) and js.StepTypeID = 1 then 'AutoCombMergeAllXForms' else StepName end
							, JobID = case when ltrim(rs.DependsOnStepIDs) <> ltrim(str(js.StepID)) and js.StepTypeID = 1 then js.JobID * -1 else js.JobID end
							, StepOrder = case when StepOrder < 1000 then js.JobID + js.StepOrder + 2000 else js.StepOrder end
					from JobControl..JobSteps js
						join ( Select DependsOnStepIDs from JobControl..JobSteps where JobID = @LastMergJobID and StepTypeID = 22 ) rs on 1=1
					where js.JobID = @LastMergJobID

				update js set StepOrder = x.NewOrder
					from JobControl..JobSteps js
						join ( select js.StepID, js.StepOrder, ROW_NUMBER() OVER(ORDER BY js.StepOrder) NewOrder
									from JobControl..JobSteps js
								where JobID = @LastMergJobID ) x on js.StepID = x.StepID

				set @MergeStepsList = ''

			End
			
			 DECLARE curB CURSOR FOR
				  select StepID, StepTypeID from JobControl..JobSteps where JobID = @PartJobID order by JobID, StepOrder

			 OPEN curB

			 FETCH NEXT FROM curB into @StepID, @StepTypeID
			 WHILE (@@FETCH_STATUS <> -1)
			 BEGIN
					
					if @StepTypeID = 29
						set @MergeStepsList = @MergeStepsList + ',' + ltrim(str(@StepID))

					Print @MergeStepsList


				  FETCH NEXT FROM curB into @StepID, @StepTypeID
			 END
			 CLOSE curB
			 DEALLOCATE curB

			update JobControl..JobSteps set JobID = @MergJobID, StepOrder = JobID + StepOrder + 1000 where JobID = @PartJobID
			delete JobControl..Jobs where JobID = @PartJobID

			set @LastMergJobID = @MergJobID

          FETCH NEXT FROM curA into @MergVFPJobID, @MergJobID, @PartVFPJobID, @PartJobID
     END
     CLOSE curA
     DEALLOCATE curA

	if @LastMergJobID > 0
	Begin
				
		update js set DependsOnStepIDs = case when ltrim(rs.DependsOnStepIDs) = ltrim(str(js.StepID)) and js.StepTypeID = 1 then substring(@MergeStepsList,2,2000) else null end
					, StepName = case when ltrim(rs.DependsOnStepIDs) = ltrim(str(js.StepID)) and js.StepTypeID = 1 then 'AutoCombMergeAllXForms' else StepName end
					, JobID = case when ltrim(rs.DependsOnStepIDs) <> ltrim(str(js.StepID)) and js.StepTypeID = 1 then js.JobID * -1 else js.JobID end
					, StepOrder = case when StepOrder < 1000 then js.JobID + js.StepOrder + 2000 else js.StepOrder end
			from JobControl..JobSteps js
				join ( Select DependsOnStepIDs from JobControl..JobSteps where JobID = @LastMergJobID and StepTypeID = 22 ) rs on 1=1
			where js.JobID = @LastMergJobID

			update js set StepOrder = x.NewOrder
				from JobControl..JobSteps js
					join ( select js.StepID, js.StepOrder, ROW_NUMBER() OVER(ORDER BY js.StepOrder) NewOrder
								from JobControl..JobSteps js
							where JobID = @LastMergJobID ) x on js.StepID = x.StepID


	End

	delete JobControl..JobSteps where JobID < 0 

END
