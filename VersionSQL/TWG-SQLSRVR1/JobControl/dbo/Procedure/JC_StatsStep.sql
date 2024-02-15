/****** Object:  Procedure [dbo].[JC_StatsStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_StatsStep @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);
	declare @LogInfo varchar(500) = '';
	declare @goodparams bit = 1;
	
	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

	delete JobControl..JobParameters where StepID = @JobStepID
	delete JobControl..JobInfo where StepID = @JobStepID

	declare @StatsTableName varchar(500)
	declare @SourceTableName varchar(500)

	declare @SQLCmd Varchar(max), @SQLCore Varchar(max);
	declare @JobID int, @JobTemplateID int, @CategoryID int;

	select @JobID = js.JobID
			, @JobTemplateID = JobTemplateID
			, @CategoryID = CategoryID
		from JobControl..JobSteps js
			join JobControl..Jobs j on j.JobID = js.JobID
		where StepID = @JobStepID

	select @SourceTableName = ParamValue
		from JobControl..JobParameters
		where StepID = JobControl.dbo.GetDependsJobStepID(@JobStepID)

	Print '@SourceTableName: ' + @SourceTableName

	set @StatsTableName = 'JobControlWork..StatsStepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID));

	set @SQLCmd = 'IF OBJECT_ID(''' + @StatsTableName + ''', ''U'') IS not NULL drop TABLE ' + @StatsTableName + ' '
	exec(@SQLCmd)

	if @JobTemplateID = 42	-- (NBPTest) NetBook Processing Job | Category: 3	INTRXN	Transaction Processing
	begin
		set @SQLCmd = 'select count(*) Records
							, max(case when isdate(Filing_Date) = 1 then convert(date,Filing_Date) else null end) MaxFilingDate
							, Min(case when isdate(Filing_Date) = 1 then convert(date,Filing_Date) else null end) MinFilingDate
							, Town, State
						into @@StatsTable@@
						from @@SourceTable@@
						group by Town, State
						order by State, Town '
	end

	if @SQLCmd > ''
		begin
			Begin Try
				set @SQLCmd = replace(@SQLCmd,'@@StatsTable@@',@StatsTableName)
				set @SQLCmd = replace(@SQLCmd,'@@SourceTable@@',@SourceTableName)
				exec(@SQLCmd)

				exec JobControl.dbo.SetJobStepParam @JobStepID, 'Stats Table', @StatsTableName, @LogSourceName
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
			end Try
			Begin Catch
				set @LogInfo = 'JC_QueryStep Error:' + '(' + ltrim(str(ERROR_NUMBER())) + ') ' + ERROR_MESSAGE();
				exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @LogInfo, @LogSourceName;
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'
			End Catch

		end
	else
		begin
			insert JobInfo (JobID, StepID, InfoName, InfoValue) 
				select @JobID, @JobStepID, 'No Stats', 0
			exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
		end


END
