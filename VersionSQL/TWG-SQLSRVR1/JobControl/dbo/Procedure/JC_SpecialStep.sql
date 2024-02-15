/****** Object:  Procedure [dbo].[JC_SpecialStep]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_SpecialStep
	@JobStepID int 
AS
BEGIN
	SET NOCOUNT ON;
	
	-- This stored procedure will eventually have something meaningful to do.
	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'
	--SpecialStepResults_J118_S238
	declare @StepTable varchar(50);
	declare @DependsOnStepIDs varchar(100);
	declare @StepType varchar(50);
	declare @JobID int;
	declare @SQLDropCmd Varchar(max);
	declare @SQLCmd Varchar(max);

	select @DependsOnStepIDs = js.DependsOnStepIDs
		, @JobID = js.JobID
		, @StepType = jst.StepName
	from JobControl..JobSteps js
		join JobControl..JobStepTypes jst on js.StepTypeID = jst.StepTypeID
	where js.StepID = @JobStepID;

	set @StepTable = 'JobControlWork..SpecialStepResults_J' + ltrim(str(@JobID)) + '_S' + ltrim(str(@JobStepID));
	set @SQLDropCmd = 'IF OBJECT_ID(''' + @StepTable + ''', ''U'') IS not NULL drop TABLE ' + @StepTable + ' ';
	print @SQLDropCmd;
	exec(@SQLDropCmd);

	set @SQLCmd = 'select * into ' + @StepTable + ' from ( Select getdate() as CurDate, CustID from Jobs where JobID=' + 
		ltrim(str(@JobID)) + '  ) x '
	print @SQLCmd;
	exec(@SQLCmd);

	exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'
END
