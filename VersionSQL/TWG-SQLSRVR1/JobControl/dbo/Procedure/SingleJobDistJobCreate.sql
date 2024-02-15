/****** Object:  Procedure [dbo].[SingleJobDistJobCreate]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.SingleJobDistJobCreate
	@JobStepID int, 
	@Email varchar(200), 
	@FirstName varchar(100) null, 
	@LastName varchar(100) null, 
	@CompanyGroup varchar(100) null
AS
BEGIN
	SET NOCOUNT ON;

	-- Make Email manditory
	-- Check for allready existing Email  -- Abort if the e-mail already exists
	Set @Email=ltrim(rtrim(@Email));
	if exists(Select email from OrderControl..Customers where email=@Email)
		RETURN -- Email already exists in Customers - Abort!

	declare @Stamp datetime = getdate()
	declare @CustID int = -1

	insert OrderControl..Customers (FirstName, LastName, GroupName, EMail, CreatedStamp, UpdatedStamp)
		values (ltrim(rtrim(coalesce(@FirstName,''))), ltrim(rtrim(coalesce(@LastName,'')))
				, ltrim(rtrim(coalesce(@CompanyGroup,''))), ltrim(rtrim(@Email)), @Stamp, @Stamp)

	select top 1 @CustID = CustID from OrderControl..Customers where @Email = @Email and CreatedStamp = @Stamp order by CustID desc

	if @CustID > -1
	begin
		declare @ListID int

		insert JobControl..DistLists (ListName, ListCat) values ('DistList for ' + ltrim(rtrim(@Email)), 'CustJob')

		select top 1 @ListID = ID from JobControl..DistLists order by ID desc
		
		insert JobControl..DistListEntries (ListID,SourceID,EntryType)
			values (@ListID, @CustID, 'Cust')

		insert JobControl..DistListJobSteps (JobStepID, ListID) values(@JobStepID, @ListID)

	end

END
