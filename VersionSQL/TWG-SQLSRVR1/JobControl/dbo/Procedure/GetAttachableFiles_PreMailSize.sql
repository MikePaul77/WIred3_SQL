/****** Object:  Procedure [dbo].[GetAttachableFiles_PreMailSize]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetAttachableFiles_PreMailSize @UseID int, @Mode varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	if (@Mode = 'Jobs' or @Mode='JobSteps' or @Mode='StepDocs')
		-- Used by JobControl to build the TreeView selector
		BEGIN
			select x.*
				into #FullDocs
					from (
						select j.JobID, j.JobName
								, js.StepID, js.StepOrder
								, 'Report' StepName
								--, case when ZipFileDirectly = 1 then left(StepFileNameAlgorithm,charindex('.',StepFileNameAlgorithm)) + 'zip' 
								--		else StepFileNameAlgorithm end StepName
								, coalesce(dm.Iteration_TownID,0) Iteration_TownID, coalesce(dm.Iteration_CountyID,0) Iteration_CountyID, coalesce(dm.Iteration_StateID,0) Iteration_StateID
								, dm.FileName
								, dm.DocumentID	 
								, DocSeq = ROW_NUMBER() OVER (PARTITION BY StepID, dm.Iteration_TownID, dm.Iteration_CountyID, dm.Iteration_StateID ORDER BY CreateDate Desc)
								, case when coalesce(dm.Iteration_TownID,0) > 0 then 'Town: ' + t.FullName + ' ' + ts.Code
										when coalesce(dm.Iteration_CountyID,0) > 0 then 'County: ' + c.FullName + ' ' + cs.Code
										when coalesce(dm.Iteration_StateID,0) > 0 then 'State: ' + s.Code
										else '' end Iteration
							from JobControl..JobSteps js
								join JobControl..Jobs j on j.JobID = js.JobID and coalesce(j.disabled,0) = 0
								join DocumentLibrary..DocumentMaster dm on dm.JobStepID = js.StepID
								left outer join Lookups..Towns t on t.id = dm.Iteration_TownID
								left outer join Lookups..States ts on ts.id = t.StateID
								left outer join Lookups..Counties c on c.id = dm.Iteration_CountyID
								left outer join Lookups..States cs on cs.id = c.StateID
								left outer join Lookups..States s on s.id = dm.Iteration_StateID
							where js.SharableReport = 1
								and dm.OK2ReleaseDate is not null
					) x
				where DocSeq = 1

			if @Mode = 'Jobs'
				Begin
					-- Gets the JobID and JobName from jobs that have attachable files
					select distinct JobID, JobName
						from #FullDocs
						order by JobName, JobID
				End

			if @Mode = 'JobSteps'
				Begin
					-- Gets job steps that have attachable files from a specific job
					-- @UseID is the JobID of a job with attachable files
					select distinct StepID, StepOrder, StepName
						from #FullDocs
						where JobID = @UseID
						order by StepOrder
				End

			if @Mode = 'StepDocs'
				Begin
					-- Gets attachable files from a JobStep.  
					-- For FileName, it returns the newest file based on createdate
					-- @UseID is the JobStep of a Job that creates attachable files
					select Iteration_TownID, Iteration_CountyID, Iteration_StateID
							, FileName, DocumentID, Iteration
						from #FullDocs
						where StepID = @UseID
						order by fileName, Iteration
				End
		END

	if @Mode = 'AddedFiles'
		-- Used when a job is running to attach a file to the job
		BEGIN
			select x.*
				into #FullDocsAF
					from (
						select j.JobID, j.JobName, jl.JobParameters
								, js.StepID, js.StepOrder, js.StepName
								, coalesce(dm.Iteration_TownID,0) Iteration_TownID, coalesce(dm.Iteration_CountyID,0) Iteration_CountyID, coalesce(dm.Iteration_StateID,0) Iteration_StateID
								, dm.FileName
								, dm.DocumentID	 
								, DocSeq = ROW_NUMBER() OVER (PARTITION BY StepID, dm.Iteration_TownID, dm.Iteration_CountyID, dm.Iteration_StateID ORDER BY CreateDate Desc)
								, case when coalesce(dm.Iteration_TownID,0) > 0 then 'Town: ' + t.FullName + ' ' + ts.Code
										when coalesce(dm.Iteration_CountyID,0) > 0 then 'County: ' + c.FullName + ' ' + cs.Code
										when coalesce(dm.Iteration_StateID,0) > 0 then 'State: ' + s.Code
										else '' end Iteration
							from JobControl..JobSteps js
								join JobControl..Jobs j on j.JobID = js.JobID and coalesce(j.disabled,0) = 0
								join DocumentLibrary..DocumentMaster dm on dm.JobStepID = js.StepID
								left outer join Lookups..Towns t on t.id = dm.Iteration_TownID
								left outer join Lookups..States ts on ts.id = t.StateID
								left outer join Lookups..Counties c on c.id = dm.Iteration_CountyID
								left outer join Lookups..States cs on cs.id = c.StateID
								left outer join Lookups..States s on s.id = dm.Iteration_StateID
								left outer join JobControl..JobLog jl on jl.ID=dm.JobLogID
							where js.SharableReport = 1
								and dm.OK2ReleaseDate is not null
								and jl.JobParameters=(Select j2.LastJobParameters
															From JobSteps js2
																Join Jobs j2 on j2.jobid=js2.jobid
															where js2.stepid=@UseID)
					) x
				where DocSeq = 1

			select fd.DocumentID
				from #FullDocsAF fd
					join JobControl..JobAddedFiles af on af.FromJobStepID = fd.StepID
						and coalesce(af.Iteration_TownID,0) = coalesce(fd.Iteration_TownID,0)
						and coalesce(af.Iteration_CountyID,0) = coalesce(fd.Iteration_CountyID,0)
						and coalesce(af.Iteration_StateID,0) = coalesce(fd.Iteration_StateID,0)
					join JobControl..JobSteps js on js.StepID=af.ToJobStepID
					join JobControl..Jobs j on js.JobID=j.JobID
				where af.ToJobStepID = @UseID
					and j.LastJobParameters=fd.JobParameters
				Order by fd.DocumentID desc
		END



	if @Mode = 'FinalJobStepFiles'
		BEGIN
			Declare @InLoop int;
			Select @InLoop=dbo.InLoop(@UseID)

			if @InLoop=1
				Begin
					Declare @CurrentStepOrder int, 
							@PrevBeginStep int, 
							@ZipStepStartTime datetime, 
							@BeginLoopStartTime datetime, 
							@JobID int;

					Select @JobID=JobID, @ZipStepStartTime=StartedStamp, @CurrentStepOrder=StepOrder 
						from JobSteps where StepID=@UseID;

					-- Get the Step Order for the Begin Loop
					Select Top 1 @PrevBeginStep=StepOrder
						From JobControl..JobSteps
						Where JobID=@JobID
							And StepOrder<@CurrentStepOrder
							And StepTypeID=1107
						Order by StepOrder Desc;

					-- Get the Start Time for the Begin Loop
					Select @BeginLoopStartTime=StartedStamp 
						from JobControl..JobSteps 
						where JobID=@JobID 
							and StepOrder=@PrevBeginStep;

					select x.DocumentID, x.DocumentDate, x.WorkFileName, x.JobID, x.JobName, x.ZipOutName, x.FileSize
							, x.SendToTWGExtranet
							, x.ReportRecordCount
						from (
							select js.JobID, j.JobName, js.StepFileNameAlgorithm ZipOutName
									, coalesce(js.SendToTWGExtranet, 0) SendToTWGExtranet
									, coalesce(vdm.DocumentID, dm.DocumentID) DocumentID
									, coalesce(vdm.ReportRecordCount, dm.ReportRecordCount) ReportRecordCount
									, coalesce(vdm.CreateDate, dm.CreateDate) DocumentDate
									, coalesce(vdm.FileName, dm.FileName) WorkFileName
									, coalesce(vdm.FileSize, dm.FileSize) FileSize
									, DocSeq = ROW_NUMBER() OVER (PARTITION BY Djs.StepID
																, coalesce(vdm.Iteration_TownID,dm.Iteration_TownID)
																, coalesce(vdm.Iteration_CountyID,dm.Iteration_CountyID)
																, coalesce(vdm.Iteration_StateID,dm.Iteration_StateID) 
																ORDER BY coalesce(vdm.CreateDate,dm.CreateDate) Desc)
								from JobSteps js
									join Jobs j on j.JobID = js.JobID
									join JobSteps Djs on js.JobID = Djs.JobID and CHARINDEX(',' + ltrim(str(Djs.StepID) + ','),',' + replace(js.DependsOnStepIDs,' ','') + ',') > 0
									left outer join DocumentLibrary..DocumentMaster dm on dm.JobStepID = Djs.StepID
									left outer join DocumentLibrary..DocumentMaster vdm on vdm.DocumentID = dm.VirtualDocumentID
									left outer join JobControl..JobLog jl on jl.ID = dm.JobLogID 
									left outer join JobControl..JobStepLog jsl on jsl.JobStepID = Djs.StepID and jsl.LogInfotype = 1 and jsl.LogInfoSource = 'StepRecordCount'
								where js.StepID = @UseID
									and (j.LastJobParameters = jl.JobParameters
											or (dm.FileCreateDate is null and jl.JobParameters is null))
									and ((dm.FileCreateDate>=Dateadd(hh,-48,getdate())
											and ((isnull(j.TestMode,0)=1
												and dm.DoNotDistributeDate is not null)
											or (dm.OK2ReleaseDate is not null
												and dm.DoNotDistributeDate is null)))
										or dm.FileCreateDate is null)

							) x
						where x.DocSeq = 1
							and DocumentDate>@BeginLoopStartTime
							and DocumentDate<@ZipStepStartTime
				END
			else
				-- Used in the job distribution step to attach the correct files to Email/FTP
				select x.DocumentID, x.WorkFileName, x.JobID, x.JobName, x.ZipOutName, x.FileSize
						, x.SendToTWGExtranet
						, x.ReportRecordCount
					from (
						select js.JobID, j.JobName, js.StepFileNameAlgorithm ZipOutName
								, coalesce(js.SendToTWGExtranet, 0) SendToTWGExtranet
								, coalesce(vdm.DocumentID, dm.DocumentID) DocumentID
								, coalesce(vdm.FileName, dm.FileName) WorkFileName
								, coalesce(vdm.ReportRecordCount, dm.ReportRecordCount) ReportRecordCount
								, coalesce(vdm.FileSize, dm.FileSize) FileSize
								, DocSeq = ROW_NUMBER() OVER (PARTITION BY Djs.StepID
															, coalesce(vdm.Iteration_TownID,dm.Iteration_TownID,vdm.DocumentID, dm.DocumentID)	-- documentID's were added here and below for Iteration of Zips in a loop
															, coalesce(vdm.Iteration_CountyID,dm.Iteration_CountyID,vdm.DocumentID, dm.DocumentID)	-- MP 8/??/2020
															, coalesce(vdm.Iteration_StateID,dm.Iteration_StateID,vdm.DocumentID, dm.DocumentID)
															ORDER BY coalesce(vdm.CreateDate,dm.CreateDate) Desc)
								, DocSeq2 = ROW_NUMBER() OVER (PARTITION BY coalesce(vdm.FileName, dm.FileName)
															ORDER BY coalesce(vdm.CreateDate,dm.CreateDate) Desc)
							from JobSteps js
								join Jobs j on j.JobID = js.JobID
								join JobSteps Djs on js.JobID = Djs.JobID and CHARINDEX(',' + ltrim(str(Djs.StepID) + ','),',' + replace(js.DependsOnStepIDs,' ','') + ',') > 0
								left outer join DocumentLibrary..DocumentMaster dm on dm.JobStepID = Djs.StepID
								left outer join DocumentLibrary..DocumentMaster vdm on vdm.DocumentID = dm.VirtualDocumentID
								left outer join JobControl..JobLog jl on jl.ID = dm.JobLogID 
								left outer join JobControl..JobStepLog jsl on jsl.JobStepID = Djs.StepID and jsl.LogInfotype = 1 and jsl.LogInfoSource = 'StepRecordCount'
							where js.StepID = @UseID
								and (dm.JobLogID = (select max(ID) from JobControl..JobLog where JobID = js.jobID)  -- MP 9/2/2020 added becuase of the documentID's changes above we getting multiple
											or vdm.DocumentID > 0)																		-- version of the files from previous job Runs
								and (j.LastJobParameters = jl.JobParameters
										or (dm.FileCreateDate is null and jl.JobParameters is null))
								and ((dm.FileCreateDate>=Dateadd(hh,-96,getdate())
										and ((isnull(j.TestMode,0)=1
											and dm.DoNotDistributeDate is not null)
										or (dm.OK2ReleaseDate is not null
											and dm.DoNotDistributeDate is null)))
									or dm.FileCreateDate is null)

						) x
					where x.DocSeq2 = 1
		END
END


--Previous version.  Commented out 1-28-2020 - Mark W.
--BEGIN
--	SET NOCOUNT ON;

--		select x.*
--			into #FullDocs
--				from (
--					select j.JobID, j.JobName
--							, js.StepID, js.StepOrder, js.StepName
--							, coalesce(dm.Iteration_TownID,0) Iteration_TownID, coalesce(dm.Iteration_CountyID,0) Iteration_CountyID, coalesce(dm.Iteration_StateID,0) Iteration_StateID
--							, dm.FileName
--							, dm.DocumentID	 
--							, DocSeq = ROW_NUMBER() OVER (PARTITION BY StepID, dm.Iteration_TownID, dm.Iteration_CountyID, dm.Iteration_StateID ORDER BY CreateDate Desc)
--							, case when coalesce(dm.Iteration_TownID,0) > 0 then 'Town: ' + t.FullName + ' ' + ts.Code
--									when coalesce(dm.Iteration_CountyID,0) > 0 then 'County: ' + c.FullName + ' ' + cs.Code
--									when coalesce(dm.Iteration_StateID,0) > 0 then 'State: ' + s.Code
--									else '' end Iteration
--						from JobControl..JobSteps js
--							join JobControl..Jobs j on j.JobID = js.JobID and coalesce(j.disabled,0) = 0
--							join DocumentLibrary..DocumentMaster dm on dm.JobStepID = js.StepID
--							left outer join Lookups..Towns t on t.id = dm.Iteration_TownID
--							left outer join Lookups..States ts on ts.id = t.StateID
--							left outer join Lookups..Counties c on c.id = dm.Iteration_CountyID
--							left outer join Lookups..States cs on cs.id = c.StateID
--							left outer join Lookups..States s on s.id = dm.Iteration_StateID
--						where js.SharableReport = 1
--							and dm.OK2ReleaseDate is not null
--				) x
--			where DocSeq = 1

--	if @Mode = 'Jobs'
--	Begin
--		select distinct JobID, JobName
--			from #FullDocs
--		order by JobName, JobID

--	End

--	if @Mode = 'JobSteps'
--	Begin
--		select distinct StepID, StepOrder, StepName
--			from #FullDocs
--			where JobID = @UseID
--		order by StepOrder

--	End

--	if @Mode = 'StepDocs'
--	Begin
--		select Iteration_TownID, Iteration_CountyID, Iteration_StateID
--				, FileName
--				, DocumentID	 
--				, Iteration
--			from #FullDocs
--			where StepID = @UseID
--		order by fileName, Iteration

--	End

--	if @Mode = 'AddedFiles'
--	begin
--		select fd.DocumentID
--			from #FullDocs fd
--				join JobControl..JobAddedFiles af on af.FromJobStepID = fd.StepID
--													and coalesce(af.Iteration_TownID,0) = coalesce(fd.Iteration_TownID,0)
--													and coalesce(af.Iteration_CountyID,0) = coalesce(fd.Iteration_CountyID,0)
--													and coalesce(af.Iteration_StateID,0) = coalesce(fd.Iteration_StateID,0)

--			where af.ToJobStepID = @UseID
--	end

--	if @Mode = 'FinalJobStepFiles'
--	begin
--		-- Commented out the lines below on 5/29/2019 - Mark W.
--		-- That data now comes from JobControl..GetDistListEntries
--		select x.DocumentID, x.WorkFileName, x.JobID, x.JobName, x.ZipOutName
----				, x.FullName, x.EMail
----				, x.FTPLOGIN
----		        , x.FTPPASSWRD
----		        , x.FTPPATH
----		        , x.ELECADDR
----              , x.ExtraNetPath
----              , x.SendDeliveryConfirmationEmail
--                , x.SendToTWGExtranet
--			from (
--				select js.JobID, j.JobName, js.StepFileNameAlgorithm ZipOutName
----						, coalesce(ci.FirstName,'') + ' ' + coalesce(ci.LastName,'') FullName
----						, ci.EMail
----		                , ci.FTPLOGIN
----		                , ci.FTPPASSWRD
----		                , ci.FTPPATH
----		                , ci.ELECADDR
----                      , Support.FuncLib.CleanStringForFileName(case when ci.Company = '' then ci.LastName + '_' + ci.FirstName else ci.Company end) + '_' + ltrim(str(ci.ID)) ExtraNetPath
----                      , coalesce(js.SendDeliveryConfirmationEmail, 0) SendDeliveryConfirmationEmail
--                        , coalesce(js.SendToTWGExtranet, 0) SendToTWGExtranet
--						, coalesce(vdm.DocumentID, dm.DocumentID) DocumentID
--						, coalesce(vdm.FileName, dm.FileName) WorkFileName
--						, DocSeq = ROW_NUMBER() OVER (PARTITION BY Djs.StepID, coalesce(vdm.Iteration_TownID,dm.Iteration_TownID), coalesce(vdm.Iteration_CountyID,dm.Iteration_CountyID), coalesce(vdm.Iteration_StateID,dm.Iteration_StateID) ORDER BY coalesce(vdm.CreateDate,dm.CreateDate) Desc)
--					from JobSteps js
--					    join Jobs j on j.JobID = js.JobID
----						left outer join CustomerInfo ci on ci.ID = j.CustID
--						join JobSteps Djs on js.JobID = Djs.JobID and CHARINDEX(',' + ltrim(str(Djs.StepID) + ','),',' + replace(js.DependsOnStepIDs,' ','') + ',') > 0
--						left outer join DocumentLibrary..DocumentMaster dm on dm.JobStepID = Djs.StepID
--						left outer join DocumentLibrary..DocumentMaster vdm on vdm.DocumentID = dm.VirtualDocumentID
--						left outer join JobControl..JobLog jl on jl.ID = dm.JobLogID 
--                        left outer join JobControl..JobStepLog jsl on jsl.JobStepID = Djs.StepID and jsl.LogInfotype = 1 and jsl.LogInfoSource = 'StepRecordCount'
--					where js.StepID = @UseID
--						--and j.LastJobParameters = jl.JobParameters
--						--and dm.OK2ReleaseDate is not null
--						--and dm.DoNotDistributeDate is null
--						--and dm.FileCreateDate>=Dateadd(hh,-48,getdate())
--						and j.LastJobParameters = jl.JobParameters
--						and dm.FileCreateDate>=Dateadd(hh,-48,getdate())
--						and ((isnull(j.TestMode,0)=1
--								and dm.DoNotDistributeDate is not null)
--							OR (dm.OK2ReleaseDate is not null
--								and dm.DoNotDistributeDate is null))

--				) x
--			where x.DocSeq = 1
				
--	end


--END
