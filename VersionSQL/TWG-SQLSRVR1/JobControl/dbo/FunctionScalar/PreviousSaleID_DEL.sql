/****** Object:  ScalarFunction [dbo].[PreviousSaleID_DEL]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION [dbo].[PreviousSaleID]
(
	@SaleID int
)
RETURNS int
AS
BEGIN
	DECLARE @result int

	select top 1 @result = pst.ID
			from TWG_PropertyData..SalesTransactions st
				join TWG_PropertyData..SalesTransactions pst on pst.PropertyId = st.PropertyId
																and st.ID <> pst.ID 
																and pst.FilingDate <= st.FilingDate
																and pst.SalePrice > 1

			where st.ID = @SaleID
			order by pst.FilingDate desc, pst.Book desc, pst.Page desc

	RETURN @result

END
