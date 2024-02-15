/****** Object:  Procedure [dbo].[ReloadDistributionLog2]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ReloadDistributionLog2 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	truncate table JobControl..DistributionLog2

insert into JobControl..DistributionLog2 (JobID, Email, ListID, DocumentID, Errors, ErrorData, DeliveryTime, DistributionDestID)

select *
	from
		(select
		JobID, Email, ListID, value DocumentID, errors, ErrorData, DeliveryTime, DistributionDestID
		from JobControl..DistributionLog
		CROSS APPLY STRING_SPLIT(rtrim(ltrim(Documents)), ',')
		where value > '' and TRY_CONVERT(int, value) is not null) x
END
