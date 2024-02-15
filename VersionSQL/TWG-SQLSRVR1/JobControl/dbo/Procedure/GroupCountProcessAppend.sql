/****** Object:  Procedure [dbo].[GroupCountProcessAppend]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GroupCountProcessAppend @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @KeyFieldOutName varchar(100)
	declare @KeyFields varchar(max)
	declare @Sep varchar(10)


	declare @Firstpass bit = 1

	declare @Cmd varchar(max)

	declare @XFormTableName varchar(500)
	declare @CountTableName varchar(500)
	declare @RawCountTableName varchar(500)
	declare @DepStepTypeID int
	declare @XformID int
	declare @UsageGroupTypeID int

	DECLARE AppendGroupCountcurA CURSOR FOR
	select tjs.stepTypeID
			, tjs.TransformationID
			, 'JobControlWork..' + jst2.StepName + 'StepResultsA_J' + ltrim(str(tjs.JobID)) + '_S' + ltrim(str(tjs.StepID))
			, 'JobControlWork..' + jst.StepName + 'StepCount_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
			, 'JobControlWork..' + jst.StepName + 'StepRawCount_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
			 
		from JobControl..JobSteps js
			left outer join JobControl..JobSteps tjs on js.JobID = tjs.jobid and coalesce(tjs.disabled,0) = 0
													and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(tjs.StepID)) + ',%'				
			join JobControl..JobStepTypes jst on jst.StepTypeID = js.StepTypeID
			join JobControl..JobStepTypes jst2 on jst2.StepTypeID = tjs.StepTypeID
		where js.StepID = @JobStepID

	OPEN AppendGroupCountcurA

	FETCH NEXT FROM AppendGroupCountcurA into @DepStepTypeID, @XformID, @XFormTableName, @CountTableName, @RawCountTableName 
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN

		if @DepStepTypeID = 29  -- Appended XForm steps only
		begin

			if @Firstpass = 1
			begin
				set @cmd = 'IF OBJECT_ID(''' + @CountTableName + ''', ''U'') IS not NULL drop TABLE ' + @CountTableName + ' '
				exec(@cmd)
			end

			set @KeyFields = ''	
			set @Sep = ''

			DECLARE GroupCountcurA CURSOR FOR
			select 'XF_' + ttc.OutName, coalesce(tt.UsageGroupType,0) 
				from JobControl..TransformationTemplateColumns ttc
					join JobControl..TransformationTemplates tt on tt.Id = ttc.TransformTemplateID
				where ttc.TransformTemplateID = @XformID
					and ttc.GroupCountCol = 1 and coalesce(ttc.Disabled,0) = 0  
				order by ttc.RecID

			OPEN GroupCountcurA

			FETCH NEXT FROM GroupCountcurA into @KeyFieldOutName, @UsageGroupTypeID
			WHILE (@@FETCH_STATUS <> -1)
			BEGIN
				set @KeyFields = @KeyFields + @Sep + @KeyFieldOutName
				set @Sep = ', '

				FETCH NEXT FROM GroupCountcurA into @KeyFieldOutName, @UsageGroupTypeID
			END
			CLOSE GroupCountcurA
			DEALLOCATE GroupCountcurA

--print '=================================================================='

--print '@DepStepTypeID -> ' + ltrim(str(@DepStepTypeID)) 
--print '@XformID -> ' + ltrim(str(@XformID)) 
--print '@XFormTableName -> ' + @XFormTableName
--print '@CountTableName -> ' + @CountTableName
--print '@RawCountTableName -> ' + @RawCountTableName

--print '@UsageGroupTypeID -> ' + ltrim(str(@UsageGroupTypeID)) 

			-- Not sure what to do here this has to do with the Append step and BK Interlaced
			if @XformID not in (682,679,681)
			begin
				if @KeyFields > ''
					begin
						--set @cmd = 'select ' + @KeyFields + ', Count(*) __RecCount into ' + @CountTableName + ' from ' + @XFormTableName + ' Group by ' + @KeyFields
						set @cmd = 'IF OBJECT_ID(''' + @CountTableName + ''', ''U'') IS NULL 
											select ' + @KeyFields + ', Count(*) __RecCount into ' + @CountTableName + ' from ' + @XFormTableName + ' Group by ' + @KeyFields +
									' else 
											insert ' + @CountTableName + ' select ' + @KeyFields + ', Count(*) __RecCount from ' + @XFormTableName + ' Group by ' + @KeyFields

					end
				else
					begin
						--set @cmd = 'select Count(*) __RecCount into ' + @CountTableName + ' from ' + @XFormTableName
						set @cmd = 'IF OBJECT_ID(''' + @CountTableName + ''', ''U'') IS NULL 
											select Count(*) __RecCount into ' + @CountTableName + ' from ' + @XFormTableName +
									' else 
											insert ' + @CountTableName + ' select Count(*) __RecCount from ' + @XFormTableName
					end

				print @cmd
				exec(@cmd)
			end

			set @cmd = 'IF OBJECT_ID(''' + @RawCountTableName + ''', ''U'') IS NULL 
								select * into ' + @RawCountTableName + ' from ' + @XFormTableName + 
						' else 
								insert ' + @RawCountTableName + ' select * from ' + @XFormTableName
			print @cmd

			-- if the above fails it is becuse the layout fields have changed so then we just force the drop of the table
			begin try
		
					exec(@cmd)
			end try
			begin catch
	
				set @cmd = 'drop table ''' + @RawCountTableName + ''' 
								select * into ' + @RawCountTableName + ' from ' + @XFormTableName 
				print @cmd

			end catch

			set @Firstpass = 0

		end

		FETCH NEXT FROM AppendGroupCountcurA into @DepStepTypeID, @XformID, @XFormTableName, @CountTableName, @RawCountTableName 
	END
	CLOSE AppendGroupCountcurA
	DEALLOCATE AppendGroupCountcurA


end
