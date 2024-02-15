/****** Object:  Procedure [dbo].[ALTDataProcess]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.ALTDataProcess @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @AltDataSteps int = 0

	select @AltDataSteps = count(*) from JobControl..JobSteps where AltDataStepID = @JobStepID
	if @AltDataSteps > 0
	begin

		declare @KeyFieldOutName varchar(100)
		declare @KeyFields varchar(max)
		declare @Sep varchar(10)

		set @KeyFields = ''
		set @Sep = ''

		declare @Cmd varchar(max)

		declare @XFormTableName varchar(500)
		declare @AltDataTableName varchar(500)

		select @XFormTableName = 'JobControlWork..' + Djst.StepName + 'StepResultsA_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
				, @AltDataTableName = 'JobControlWork..' + Djst.StepName + 'StepResultsAltData_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
			from JobControl..JobSteps js
				join JobControl..JobStepTypes Djst on Djst.StepTypeID = js.StepTypeID
			where js.StepID = @JobStepID


			IF OBJECT_ID(@AltDataTableName, 'U') IS not NULL
				begin
					set @Cmd = 'insert ' + @AltDataTableName + ' select x.* from ' + @XFormTableName + ' x '
				end
			else
				begin
					set @Cmd = 'select x.* into ' + @AltDataTableName + ' from ' + @XFormTableName + ' x '
				end

			print @cmd
			exec(@cmd)

	end

end
