/****** Object:  Procedure [dbo].[SetJobsParam2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.SetJobsParam2  @IDS varchar(max), @ParamName1 varchar(100),@ParamName2 varchar(100), @ParamValue1 varchar(500),@ParamValue2 varchar(500), @LogSourceName varchar(100)
	-- Add the parameters for the stored procedure here
AS
BEGIN
	SET NOCOUNT ON;
--			insert JobParameters (JobID, ParamName)
--			select j.JobID, @ParamName1
--			from jobcontrol..Jobs j
--			left outer join jobcontrol..JobParameters jp on jp.JobID = j.JobID
--			where ',' +@IDS+',' like '%,'+convert(varchar, j.JobID)+',%'
--			and jp.JobID is null

--		update jp set ParamValue = @ParamValue1, ParamName = @ParamName1
--		from jobcontrol..JobParameters jp
--			where ',' +@IDS+',' like '%,'+convert(varchar, jp.JobID)+',%'
--				--and ParamName = @ParamName1

--if @ParamValue2 > ''
--			begin
--				insert JobParameters (JobID, ParamName)
--				select j.JobID, @ParamName2
--				from jobcontrol..Jobs j
--				left outer join jobcontrol..JobParameters jp on jp.JobID = j.JobID
--				where ',' +@IDS+',' like '%,'+convert(varchar, j.JobID)+',%'
--				and jp.JobID is null

--		update jp set ParamValue = @ParamValue2, ParamName = @ParamName2
--		from jobcontrol..JobParameters jp
--		where ',' +@IDS+',' like '%,'+convert(varchar, jp.JobID)+',%'
--				--and ParamName = @ParamName2
--end

	delete JobControl..JobParameters
	where ',' +@IDS+',' like '%,'+convert(varchar, JobID)+',%'


	if @ParamName1 > ''
		insert Jobcontrol..JobParameters (JobID, ParamName, ParamValue)
				select JobID, @ParamName1, @ParamValue1
				from jobcontrol..Jobs 
				where ',' +@IDS+',' like '%,'+convert(varchar, JobID)+',%'

	if @ParamName2 > ''
		insert Jobcontrol..JobParameters (JobID, ParamName, ParamValue)
				select JobID, @ParamName2, @ParamValue2
				from jobcontrol..Jobs 
				where ',' +@IDS+',' like '%,'+convert(varchar, JobID)+',%'


	--declare @LogInfo varchar(500) = 'Param Set: ' + @ParamName + ' = ' + @ParamValue;
		
	--exec JobControl.dbo.JobStepLogInsert @JobID, 1, @LogInfo, @LogSourceName;

END
