/****** Object:  ScalarFunction [dbo].[GetJobEmailSubject]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.GetJobEmailSubject
(
	@JobID int, @BaseSubject varchar(255)
)
RETURNS varchar(255)
AS
BEGIN
	DECLARE @Result varchar(255)

	declare @active bit = 1

	if @active = 1
	begin
		select @result = case when MultiCustJob = 1 then @BaseSubject		-- Hide Job Name
							when CustID = 0 then @BaseSubject   -- Don't have a cust
							when CustID = -1 then j.JobName -- Internal lose the matketing
							when CustID > 0 then @BaseSubject + ' - ' + j.JobName else '' end
						+ ' ID' + ltrim(str(j.JobID))
			from JobControl..Jobs j
			where j.JobID = @JobID
	end
	else
	begin
		set @Result = @BaseSubject
	end


	RETURN @Result

END
