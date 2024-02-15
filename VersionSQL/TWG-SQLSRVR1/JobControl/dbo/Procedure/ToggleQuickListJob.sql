/****** Object:  Procedure [dbo].[ToggleQuickListJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE ToggleQuickListJob @JobID int, @UserName varchar(50)
AS
BEGIN
	SET NOCOUNT ON;

	declare @UserID int

	select @UserID = support.dbo.getUserID(@UserName) 

	if @UserID > 0
	begin

		declare @EFID int

		select @EFID = ID 
			from JobControl..ExtendedFilters
			where coalesce(Disabled,0) = 0
				and QuickList = 1
				and CreatedByUserID = @UserID

		if coalesce(@EFID,0) = 0
		begin
			insert JobControl..ExtendedFilters (FilterName, DisplayOrder, IsPublic, CreatedByUserID, QuickList)
					values('Quick List',-1,0,@UserID,1)

			select @EFID = ID 
				from JobControl..ExtendedFilters
				where coalesce(Disabled,0) = 0
					and QuickList = 1
					and CreatedByUserID = @UserID

		end

		if @EFID > 0
		begin
			
			declare @Found int

			select @Found = count(*) 
				from JobControl..ExtendedFiltersJobs
				where ExtendedFilterID = @EFID
					and JobID = @JobID

			if @Found = 0
				insert JobControl..ExtendedFiltersJobs (ExtendedFilterID, JobID)
					values(@EFID, @JobID)
			else
				delete JobControl..ExtendedFiltersJobs where ExtendedFilterID = @EFID and JobID = @JobID

			update JobControl..ExtendedFilters 
				set Jobs = (select count(*) from JobControl..ExtendedFiltersJobs where ExtendedFilterID = @EFID)
					, CountStamp = getdate()
				where ID = @EFID

		end


	end

END
