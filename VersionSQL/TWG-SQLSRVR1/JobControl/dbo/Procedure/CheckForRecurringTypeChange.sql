/****** Object:  Procedure [dbo].[CheckForRecurringTypeChange]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE CheckForRecurringTypeChange @JobID int, @RecurringTypeID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @CurrRecurringTypeID int

	select @CurrRecurringTypeID = RecurringTypeID
		from JobControl..Jobs
		where JobID = @JobID

	if @RecurringTypeID <> @RecurringTypeID
	begin

		update JobControl..Jobs set NextParamTarget = null
			where JobID = @JobID
		
	end

END
