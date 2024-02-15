/****** Object:  Procedure [dbo].[JC_ReportStep NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[JC_ReportStep] @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);
	declare @LogInfo varchar(500) = '';
	declare @goodparams bit = 1;

	--## Not used file creation is EXE now
	--	Ex.	R:\Wired3\Devel\Runable\ReportBuild\ReportBuild.exe 5239

	--exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

	--declare @SQLCmd Varchar(max);
	--declare @SQLDropCmd Varchar(max);
	--declare @JobID int;

	--select @JobID = js.JobID, @SQLCmd = q.SQLCmd
	--	from JobControl..JobSteps js 
	--		join QueryEditor..Queries q on js.QueryCriteriaID = q.ID
	--	where js.StepID = @JobStepID;

	--declare @StepTable varchar(50);
	--set @StepTable = 'JobControlWork..QueryStepResults_' + ltrim(str(@JobID)) + '_' + ltrim(str(@JobStepID));

	--set @LogInfo = 'SP Result Location:' + @StepTable;
	--exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;

	--set @SQLCmd = replace(@SQLCmd,'--#INTO TABLE#', 'INTO ' + @StepTable);

	--set @SQLDropCmd = 'IF OBJECT_ID(''' + @StepTable + ''', ''U'') IS not NULL drop TABLE ' + @StepTable + ' ';
	
	--print @SQLDropCmd;
	--exec(@SQLDropCmd);

	--print @SQLCmd;
	--exec(@SQLCmd);

	--exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

END
