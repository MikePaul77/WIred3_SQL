/****** Object:  Procedure [dbo].[AdjustForFullLoad]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE AdjustForFullLoad @JobLogID int
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @JobParam varchar(50)
	declare @JobID int
	declare @FLModeSteps int

	select @JobParam = QueueJobParams
			, @JobID = JobID
		from JobLog 
		where ID = @JobLogID

	select @FLModeSteps = count(*) 
		from JobControl..JobSteps 
		where JobID = @JobID and coalesce(FullLoadMode,0) > 0

	-- 0, "No Change"
	-- 1, "Disable"
	-- 2, "Enable" 
	if @FLModeSteps > 0
	begin

		update JobControl..JobSteps 
			set Disabled = case when @JobParam like '%:FullLoad' and coalesce(FullLoadMode,0) = 2 then 0
								when @JobParam like '%:FullLoad' and coalesce(FullLoadMode,0) = 1 then 1 
								when @JobParam not like '%:FullLoad' and coalesce(FullLoadMode,0) = 2 then 1
								when @JobParam not like '%:FullLoad' and coalesce(FullLoadMode,0) = 1 then 0 
					else 1 end
		where JobID = @JobID and coalesce(FullLoadMode,0) > 0

		UPDATE JobControl..Jobs set UpdatedStamp = getdate() where JobID = @JobID 

	end

END
