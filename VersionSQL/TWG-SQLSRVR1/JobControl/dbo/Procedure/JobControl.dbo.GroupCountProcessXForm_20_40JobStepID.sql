/****** Object:  Procedure [dbo].[JobControl]    Committed by VersionSQL https://www.versionsql.com ******/

Create PROCEDURE [dbo].[JobControl.dbo.GroupCountProcessXForm @JobStepID] @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @KeyFieldOutName varchar(100)
	declare @KeyFields varchar(max)
	declare @Sep varchar(10)

	set @KeyFields = ''
	set @Sep = ''

	declare @Cmd varchar(max)

		declare @XFormTableName varchar(500)
		declare @CountTableName varchar(500)

		select @XFormTableName = 'JobControlWork..' + Djst.StepName + 'StepResultsA_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
				, @CountTableName = 'JobControlWork..' + Djst.StepName + 'StepCount_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
			from JobControl..JobSteps js
				join JobControl..JobStepTypes Djst on Djst.StepTypeID = js.StepTypeID
			where js.StepID = @JobStepID

		set @cmd = 'IF OBJECT_ID(''' + @CountTableName + ''', ''U'') IS not NULL drop TABLE ' + @CountTableName + ' '
		exec(@cmd)

		DECLARE GroupCountcurA CURSOR FOR
		select 'XF_' + ttc.OutName
			from JobControl..JobSteps js
				join JobControl..TransformationTemplateColumns ttc on ttc.TransformTemplateID = js.TransformationID
			where StepID = @JobStepID and ttc.GroupCountCol = 1 and coalesce(ttc.Disabled,0) = 0  
			order by ttc.RecID

		OPEN GroupCountcurA

		FETCH NEXT FROM GroupCountcurA into @KeyFieldOutName
		WHILE (@@FETCH_STATUS <> -1)
		BEGIN
			set @KeyFields = @KeyFields + @Sep + @KeyFieldOutName
			set @Sep = ', '

			FETCH NEXT FROM GroupCountcurA into @KeyFieldOutName
		END
		CLOSE GroupCountcurA
		DEALLOCATE GroupCountcurA

		if @KeyFields > ''
			set @cmd = 'select ' + @KeyFields + ', Count(*) __RecCount into ' + @CountTableName + ' from ' + @XFormTableName + ' Group by ' + @KeyFields
		else
			set @cmd = 'select Count(*) __RecCount into ' + @CountTableName + ' from ' + @XFormTableName

		print @cmd
		exec(@cmd)


	end
