/****** Object:  Procedure [dbo].[GetNHBids]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetNHBids @IssueWeek varchar(10)
AS
BEGIN
	SET NOCOUNT ON;

	select FullBid
		from FileProcessing..NHBids_CleanDataRecords
		where __IssueWeek = @IssueWeek
		order by BidType, BidDueDate

END
