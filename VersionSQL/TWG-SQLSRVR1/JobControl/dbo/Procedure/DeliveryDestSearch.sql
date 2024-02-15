﻿/****** Object:  Procedure [dbo].[DeliveryDestSearch]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.DeliveryDestSearch @SearchString varchar(50), @ShowDisabled bit, @DelType varchar(10)
AS
BEGIN
	SET NOCOUNT ON;

	declare @CustNameSearchString varchar(50)
	if @SearchString = '@thewarrengroup.com'
		set @CustNameSearchString = 'ZZZZZZZZZ'
	else
		set @CustNameSearchString = @CustNameSearchString

	--both email and ftp, looks for first and last name, company/group name and destname where it is not disabled
	select * from (
	select dd.destaddress, dd.DestType, C.FirstName, c.LastName
			, ltrim(coalesce(C.FirstName,'') + ' ' + coalesce(c.LastName,'')) FullName
			, coalesce(co.CompanyName, c.GroupName) CompGrpName, dd.ID DeliveryDestID
			, null SourceType, null SourceID
			, dd.DisabledStamp
			, dd.FTPUserName, dd.FTPPassword, dd.FTPPath
			, dd.DestName
			,dd.CreatedNote Note
		from JobControl..DeliveryDests dd
			left outer join OrderControl..Customers c on dd.sourceid = c.custID and dd.sourceType = 'Cust'
			left outer join OrderControl..Companies co on c.CompanyID = co.CompanyID
		where case when dd.DisabledStamp is null then 1 when dd.DisabledStamp is not null and @ShowDisabled = 1 then 1 else 0 end = 1
			and dd.destaddress not like '%;%'
			and dd.destaddress not like '%@thewarrengroup.com'
			and dd.destaddress not like 'noreply@%'
			and (dd.destaddress like '%' + @SearchString + '%'
			or c.LastName like '%' + @SearchString + '%'
			or c.FirstName like '%' + @SearchString + '%'
			or coalesce(co.CompanyName, c.GroupName) like '%' + @SearchString + '%'
			or (@SearchString = '@thewarrengroup.com' and FTPUserName in ('twgcustomerpickup','TWGMain','sqlwiredtest') and DestAddress = 'dataftp.thewarrengroup.com')
			or dd.DestName like '%' + @SearchString + '%'
			or dd.FTPUserName like '%' + @SearchString + '%')
			and case when @DelType = 'all' then 1 when dd.DestType = @DelType then 1 else 0 end = 1

-- Special for people in db that are not sales and not users
union
	select dd.destaddress, dd.DestType, C.FirstName, c.LastName
			, ltrim(coalesce(C.FirstName,'') + ' ' + coalesce(c.LastName,'')) FullName
			, coalesce(co.CompanyName, c.GroupName) CompGrpName, dd.ID DeliveryDestID
			, null SourceType, null SourceID
			, dd.DisabledStamp
			, dd.FTPUserName, dd.FTPPassword, dd.FTPPath
			, dd.DestName
			,dd.CreatedNote Note
		from JobControl..DeliveryDests dd
			left outer join OrderControl..Customers c on dd.sourceid = c.custID and dd.sourceType = 'Cust'
			left outer join OrderControl..Companies co on c.CompanyID = co.CompanyID
		where case when dd.DisabledStamp is null then 1 when dd.DisabledStamp is not null and @ShowDisabled = 1 then 1 else 0 end = 1
			and dd.destaddress not like '%;%'
			and dd.destaddress in ('sadams@thewarrengroup.com')
			and dd.destaddress not like 'noreply@%'
			and (dd.destaddress like '%' + @SearchString + '%'
			or c.LastName like '%' + @SearchString + '%'
			or c.FirstName like '%' + @SearchString + '%'
			or coalesce(co.CompanyName, c.GroupName) like '%' + @SearchString + '%'
			or (@SearchString = '@thewarrengroup.com' and FTPUserName in ('twgcustomerpickup','TWGMain','sqlwiredtest') and DestAddress = 'dataftp.thewarrengroup.com')
			or dd.DestName like '%' + @SearchString + '%'
			or dd.FTPUserName like '%' + @SearchString + '%')
			and case when @DelType = 'all' then 1 when dd.DestType = @DelType then 1 else 0 end = 1

--customers - email, first/last, company/group name and destname where deliverydestid is null
union
	select c.Email, 'Email' DestType, C.FirstName, c.LastName
		, ltrim(coalesce(C.FirstName,'') + ' ' + coalesce(c.LastName,'')) FullName
		, coalesce(co.CompanyName, c.GroupName) CompGrpName, dd.ID DeliveryDestID
		, 'Cust' SourceType, c.CustID SourceID
		, dd.DisabledStamp
		, null FTPUserName, null FTPPassword, null FTPPath
		, dd.DestName
		,dd.CreatedNote Note
		from OrderControl..Customers c 
			left outer join OrderControl..Companies co on c.CompanyID = co.CompanyID
			left outer join JobControl..DeliveryDests dd on dd.sourceid = c.custID and dd.sourceType = 'Cust'
											and case when dd.DisabledStamp is null then 1 when dd.DisabledStamp is not null and @ShowDisabled = 1 then 1 else 0 end = 1
		where dd.ID is null
			and (coalesce(c.Email,'') > '' )
			and c.Email not like '%;%'
			and c.Email not like '%@thewarrengroup.com'
			and c.Email not like 'noreply@%'
			and (c.EMail like '%' + @SearchString + '%'
				or c.LastName like '%' + @CustNameSearchString + '%'
				or c.FirstName like '%' + @CustNameSearchString + '%'
				or coalesce(co.CompanyName, c.GroupName) like '%' + @SearchString + '%'
							or dd.DestName like '%' + @SearchString + '%')

					and case when @DelType = 'all' then 1 when 'Email' = @DelType then 1 else 0 end = 1

	--this looks like it gets FTPs (where deliverydestid is null)
	union
	select c.FTPURL, 'FTP', C.FirstName, c.LastName
			, ltrim(coalesce(C.FirstName,'') + ' ' + coalesce(c.LastName,'')) FullName
			, coalesce(co.CompanyName, c.GroupName) CompGrpName, dd.ID DeliveryDestID
			, 'Cust' SourceType, c.CustID SourceID
			, dd.DisabledStamp
			, c.FTPLogin, c.FTPPasswrd, c.FTPPath
			, dd.DestName
			,dd.CreatedNote Note
		from OrderControl..Customers c 
			left outer join OrderControl..Companies co on c.CompanyID = co.CompanyID
			left outer join JobControl..DeliveryDests dd on dd.sourceid = c.custID and dd.sourceType = 'Cust'
											and case when dd.DisabledStamp is null then 1 when dd.DisabledStamp is not null and @ShowDisabled = 1 then 1 else 0 end = 1
		where dd.ID is null
			and (coalesce(c.FTPURL,'') > '' )
			and (c.FTPURL like '%' + @SearchString + '%'
				or c.LastName like '%' + @SearchString + '%'
				or c.FirstName like '%' + @SearchString + '%'
				or coalesce(co.CompanyName, c.GroupName) like '%' + @SearchString + '%'
				or dd.DestName like '%' + @SearchString + '%'
				or dd.FTPUserName like '%' + @SearchString + '%')
					and case when @DelType = 'all' then 1 when @DelType in ('FTP','SFTP') then 1 else 0 end = 1
	
	--twg sales reps?
	union
	select sr.Email, 'Email' DestType, sr.FirstName, sr.LastName
		, ltrim(coalesce(sr.FirstName,'') + ' ' + coalesce(sr.LastName,'')) FullName
		, 'TWG Sales' CompGrpName, dd.ID DeliveryDestID
		, 'Rep' SourceType, sr.SalesRepID SourceID
		, dd.DisabledStamp
		, null FTPUserName, null FTPPassword, null FTPPath
		, dd.DestName
		,dd.CreatedNote Note
		from OrderControl..SalesReps sr
			left outer join JobControl..DeliveryDests dd on dd.sourceid = sr.SalesRepID and dd.sourceType = 'Rep'
											and case when dd.DisabledStamp is null then 1 when dd.DisabledStamp is not null and @ShowDisabled = 1 then 1 else 0 end = 1
		where (coalesce(sr.Email,'') > '' )
			and coalesce(sr.Disabled,0) = 0
			and sr.Email not like '%;%'
			and (sr.EMail like '%' + @SearchString + '%'
				or sr.LastName like '%' + @SearchString + '%'
				or sr.FirstName like '%' + @SearchString + '%'
				or 'TWG' like '%' + @SearchString + '%'
				or dd.DestName like '%' + @SearchString + '%')
					and case when @DelType = 'all' then 1 when 'Email' = @DelType then 1 else 0 end = 1
	
	--twg users?
	union
	select u.EmailAddress, 'Email' DestType, u.Firstname, u.lastname
		, ltrim(coalesce(concat(u.firstname,' ',u.Lastname),'')) FullName
		, 'TWG User' CompGrpName, dd.ID DeliveryDestID
		, 'User' SourceType, u.UserID SourceID
		, dd.DisabledStamp
		, null FTPUserName, null FTPPassword, null FTPPath
		, case when ltrim(coalesce(concat(u.firstname,' ',u.Lastname),'')) <> dd.DestName then dd.DestName else '' end
		,dd.CreatedNote Note
		from Support..MasterUser u 
			left outer join JobControl..DeliveryDests dd on dd.sourceid = u.UserID and dd.sourceType = 'User'
											and case when dd.DisabledStamp is null then 1 when dd.DisabledStamp is not null and @ShowDisabled = 1 then 1 else 0 end = 1
		where (coalesce(u.EmailAddress,'') > '' )
			and u.EmailAddress not like 'LocalAdmin%'
			and u.EmailAddress not in (select email from OrderControl..SalesReps where coalesce(Disabled,0) = 0)
			and coalesce(u.Disabled,0) = 0
			and (u.EmailAddress like '%' + @SearchString + '%'
				or dd.DestName like '%' + @SearchString + '%'
				or u.UserName like '%' + @SearchString + '%'
				or 'TWG' like '%' + @SearchString + '%')
					and case when @DelType = 'all' then 1 when 'Email' = @DelType then 1 else 0 end = 1
		) x
			
	order by case when (x.DeliveryDestID > 0) then 0 else 1 end, LastName,FirstName,CompGrpName,DestAddress	
END
