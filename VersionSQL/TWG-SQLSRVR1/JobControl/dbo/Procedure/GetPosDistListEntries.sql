/****** Object:  Procedure [dbo].[GetPosDistListEntries]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetPosDistListEntries @SearchText varchar(500), @CustID int, @ListId int, @StepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @SearchSegs int
	select @SearchSegs = max(Seq) from Support.FuncLib.SplitString(ltrim(rtrim(replace(@SearchText,' ','|'))),'|')

	declare @CompanyID int = 0
	if coalesce(@CustID,0) > 0
		select @CompanyID = coalesce(CompanyID, 0) from OrderControl..Customers where CustID = coalesce(@CustID,0)

	select distinct 1 TypeOrder
			, coalesce(case when ltrim(rtrim(dl.CompanyGroup)) = '' then null else ltrim(rtrim(dl.CompanyGroup)) end, 'Company Unknown') CompanyGroup
			, coalesce(dl.CompanyID, 0) CompanyID
			, dl.emailname, dl.EmailAddress
			, dl.FTPLOGIN, dl.FTPPASSWRD, dl.FTPPATH, dl.FTPURL
			, dl.SourceID, dl.EntryType
			, coalesce(dl.EmailEntry,1) EmailEntry
			--, coalesce(dl.FTPEntry,0) FTPEntry
			, convert(bit, 0) FTPEntry
			, case when @SearchText > '' then -1 else dl.ListID end ListID
			, case when @SearchText > '' then '--' else dl.ListName end ListName
		from JobControl..vDistList dl
			left outer join Support.FuncLib.SplitString(ltrim(rtrim(replace(@SearchText,' ','|'))),'|') st1 on (dl.EmailName like '%' + st1.value + '%'
																									or dl.EmailAddress like '%' + st1.value + '%'
																									or dl.CompanyGroup like '%' + st1.value + '%'
																									) and st1.Seq = 1
			left outer join Support.FuncLib.SplitString(ltrim(rtrim(replace(@SearchText,' ','|'))),'|') st2 on (dl.EmailName like '%' + st2.value + '%'
																									or dl.EmailAddress like '%' + st2.value + '%'
																									or dl.CompanyGroup like '%' + st2.value + '%'
																									) and st2.Seq = 2
			left outer join Support.FuncLib.SplitString(ltrim(rtrim(replace(@SearchText,' ','|'))),'|') st3 on (dl.EmailName like '%' + st3.value + '%'
																									or dl.EmailAddress like '%' + st3.value + '%'
																									or dl.CompanyGroup like '%' + st3.value + '%'
																									) and st3.Seq = 3
			left outer join Support.FuncLib.SplitString(ltrim(rtrim(replace(@SearchText,' ','|'))),'|') st4 on (dl.EmailName like '%' + st4.value + '%'
																									or dl.EmailAddress like '%' + st4.value + '%'
																									or dl.CompanyGroup like '%' + st4.value + '%'
																									) and st4.Seq = 4
		where dl.sourceID > 0
			and dl.EmailEntry = 1
			and case when @CustID > 0 then case when (dl.SourceID = @CustID or dl.CompanyID = @CompanyID) then 1 else 0 end 
						else 1 end = 1
			and ((case when st1.Seq > 0 then 1 else 0 end
					+ case when st2.Seq > 0 then 1 else 0 end
					+ case when st3.Seq > 0 then 1 else 0 end
					+ case when st4.Seq > 0 then 1 else 0 end) = @SearchSegs or ltrim(@SearchText) = '')
			and case when @ListID > 0 then case when dl.ListID = @ListID then 1 else 0 end else 1 end = 1
			and case when @StepID > 0 then case when dl.JobStepID = @StepID then 1 else 0 end else 1 end = 1
--			and case when @StepID > 0 then case when dl.DeliveryTypeID = 3 then 1 else 0 end else 1 end = 1

	union
		select distinct 2 TypeOrder
				, coalesce(case when ltrim(rtrim(dl.CompanyGroup)) = '' then null else ltrim(rtrim(dl.CompanyGroup)) end, 'Company Unknown') CompanyGroup
				, coalesce(dl.CompanyID, 0) CompanyID
				, dl.emailname, dl.EmailAddress
				, dl.FTPLOGIN, dl.FTPPASSWRD, dl.FTPPATH, dl.FTPURL
				, dl.SourceID, dl.EntryType
				--, coalesce(dl.EmailEntry,1) EmailEntry
				, convert(bit, 0) EmailEntry
				, coalesce(dl.FTPEntry,0) FTPEntry
				, case when @SearchText > '' then -1 else dl.ListID end ListID
				, case when @SearchText > '' then '--' else dl.ListName end ListName
		from JobControl..vDistList dl
			left outer join Support.FuncLib.SplitString(ltrim(rtrim(replace(@SearchText,' ','|'))),'|') st1 on (dl.EmailName like '%' + st1.value + '%'
																									or dl.EmailAddress like '%' + st1.value + '%'
																									or dl.CompanyGroup like '%' + st1.value + '%'
																									) and st1.Seq = 1
			left outer join Support.FuncLib.SplitString(ltrim(rtrim(replace(@SearchText,' ','|'))),'|') st2 on (dl.EmailName like '%' + st2.value + '%'
																									or dl.EmailAddress like '%' + st2.value + '%'
																									or dl.CompanyGroup like '%' + st2.value + '%'
																									) and st2.Seq = 2
			left outer join Support.FuncLib.SplitString(ltrim(rtrim(replace(@SearchText,' ','|'))),'|') st3 on (dl.EmailName like '%' + st3.value + '%'
																									or dl.EmailAddress like '%' + st3.value + '%'
																									or dl.CompanyGroup like '%' + st3.value + '%'
																									) and st3.Seq = 3
			left outer join Support.FuncLib.SplitString(ltrim(rtrim(replace(@SearchText,' ','|'))),'|') st4 on (dl.EmailName like '%' + st4.value + '%'
																									or dl.EmailAddress like '%' + st4.value + '%'
																									or dl.CompanyGroup like '%' + st4.value + '%'
																									) and st4.Seq = 4
		where dl.sourceID > 0
			and dl.FTPEntry = 1
			and case when @CustID > 0 then case when (dl.SourceID = @CustID or dl.CompanyID = @CompanyID) then 1 else 0 end 
									else 1 end = 1
			and ((case when st1.Seq > 0 then 1 else 0 end
					+ case when st2.Seq > 0 then 1 else 0 end
					+ case when st3.Seq > 0 then 1 else 0 end
					+ case when st4.Seq > 0 then 1 else 0 end) = @SearchSegs or ltrim(@SearchText) = '')
			and case when @ListID > 0 then case when dl.ListID = @ListID then 1 else 0 end else 1 end = 1
			and case when @StepID > 0 then case when dl.JobStepID = @StepID then 1 else 0 end else 1 end = 1
--			and case when @StepID > 0 then case when dl.DeliveryTypeID = 2 then 1 else 0 end else 1 end = 1

	order by ListID, 1, 2, 3, EmailName, EmailAddress

END
