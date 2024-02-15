/****** Object:  Procedure [dbo].[GroupCountProcessReport]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GroupCountProcessReport @JobStepID int, @ReportNameWPath varchar(500)
AS
BEGIN
	SET NOCOUNT ON;

	declare @KeyFieldOutName varchar(100)
	declare @KeyFields varchar(max)
	declare @Sep varchar(10)

	set @KeyFields = ''
	set @Sep = ''

	declare @Cmd varchar(max)

		declare @ReportName varchar(500)
		declare @CountTableName varchar(500)
		declare @RepCountTableName varchar(500)
		declare @RepStepID int
		declare @XFormStepID int
		declare @InLoop int

		set @ReportName = Jobcontrol.dbo.GetJustFileName(@ReportNameWPath)

		--select @XFormStepID = DjsR.StepID
		--		, @RepStepID = js.StepID
		--		, @CountTableName = 'JobControlWork..' + Djst.StepName + 'StepCount_J' + ltrim(str(DjsR.JobID)) + '_S' + ltrim(str(DjsR.StepID))
		--		, @RepCountTableName = 'JobControlWork..' + Djst2.StepName + 'StepRepCount_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
		--		, @InLoop = JobControl.dbo.InLoop(@JobStepID)

		--	from JobControl..JobSteps js
		--		join JobControl..Jobs j on j.JobID = js.JobID
		--		join JobControl..JobSteps DjsR on js.JobID = DjsR.JobID and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(DjsR.StepID)) + ',%'
		--		join JobControl..JobStepTypes Djst on Djst.StepTypeID = DjsR.StepTypeID
		--		join JobControl..JobStepTypes Djst2 on Djst2.StepTypeID = js.StepTypeID
		--where js.StepID = @JobStepID

		select @XFormStepID = case when DjsR.StepTypeID = 1 then DjsR2.StepID else DjsR.StepID end
				, @RepStepID = js.StepID
				, @CountTableName = 'JobControlWork..' + Djst.StepName + 'StepCount_J' + ltrim(str(DjsR.JobID)) + '_S' + ltrim(str(DjsR.StepID))
				, @RepCountTableName = 'JobControlWork..' + Djst2.StepName + 'StepRepCount_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
				, @InLoop = JobControl.dbo.InLoop(@JobStepID)

			from JobControl..JobSteps js
				join JobControl..Jobs j on j.JobID = js.JobID
				join JobControl..JobSteps DjsR on js.JobID = DjsR.JobID and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(DjsR.StepID)) + ',%'
			    left outer join JobControl..JobSteps DjsR2 on js.JobID = DjsR2.JobID and ',' + DjsR.DependsOnStepIDs + ',' like '%,' + ltrim(str(DjsR2.StepID)) + ',%'
				join JobControl..JobStepTypes Djst on Djst.StepTypeID = DjsR.StepTypeID
				join JobControl..JobStepTypes Djst2 on Djst2.StepTypeID = js.StepTypeID
		where js.StepID = @JobStepID

		IF OBJECT_ID(@CountTableName, 'U') IS not NULL
		Begin

			IF OBJECT_ID(@RepCountTableName, 'U') IS not NULL
				begin
					--if @InLoop = 1
					--Begin
					--	set @cmd = 'update ' + @RepCountTableName + ' set __Processed = 1 where __Processed = 0 '
					--	print @cmd
					--	exec(@cmd)
					--end
					set @Cmd = 'insert ' + @RepCountTableName + ' select x.*, '
						+ ltrim(str(@XFormStepID)) + ' __XFormStepID, ' + ltrim(str(@RepStepID)) + ' __RepStepID, ''' + @ReportName + ''' __ReportName '
						+ ', convert(bit,0) __Processed '
						+ ' from ' + @CountTableName + ' x '
					print @cmd
					exec(@cmd)
				end
			else
				begin
					set @Cmd = 'select x.*, '
									+ ltrim(str(@XFormStepID)) + ' __XFormStepID, ' + ltrim(str(@RepStepID)) + ' __RepStepID, convert(varchar(200),''' + @ReportName + ''') __ReportName '
								+ ', convert(bit,0) __Processed '
								+ ' into ' + @RepCountTableName + ' '
								+ ' from ' + @CountTableName + ' x '
					print @cmd
					exec(@cmd)
				end



		End

end
