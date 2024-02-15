/****** Object:  Procedure [dbo].[WebLenderList]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE WebLenderList
AS
BEGIN
	SET NOCOUNT ON;

	select code, ShortName
	from Lookups..Lenders
	where ShortName > '' 
	order by ShortName

END
