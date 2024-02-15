/****** Object:  View [dbo].[vDistList]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE view dbo.vDistList
AS

	select x.*, js.JobID
			--, js.DeliveryTypeID
			, js.SendDeliveryConfirmationEmail
			, DLSeq = ROW_NUMBER() OVER (PARTITION BY js.JobID, js.StepID ORDER BY EntryType, EmailAddress)
		from (
		select ltrim(rtrim(coalesce(c.FirstName,'') + ' ' + coalesce(c.LastName,''))) EmailName
				, coalesce(c.FirstName,'') FirstName
				, coalesce(c.LastName,'') LastName
				, c.email EmailAddress
				, coalesce(FTPLOGIN,'') FTPLOGIN
				, coalesce(FTPPASSWRD,'') FTPPASSWRD
				, coalesce(FTPPATH,'') FTPPATH
				, coalesce(FTPURL,'') FTPURL
				, dls.JobStepID
				, dl.ID ListID
				, case when ltrim(rtrim(coalesce(dl.ListName,''))) = '' then 'List:' + ltrim(str(dl.ID)) else dl.ListName end ListName
				, c.CustID SourceID
				, 'Cust' EntryType
				, coalesce(co.CompanyName, c.GroupName) CompanyGroup
				, co.CompanyID
				, case when coalesce(dle.Email,0) = 1 and c.email > ''	then 1
					else 0 end EmailEntry
				, case when coalesce(dle.FTP,0) = 1 and FTPLOGIN > ''	then 1 
					else 0 end FTPEntry
				, c.CRM_ContactID
				, co.CRM_CompanyID
				, c.SalesRepID
			from OrderControl..Customers c
				left outer join OrderControl..Companies co on co.CompanyID = c.CompanyID 
				left outer join JobControl..DistListEntries dle on c.CustID = dle.SourceID 
																and dle.EntryType = 'Cust'
																and dle.Email = 1
																and coalesce(dle.disabled,0) = 0
				left outer join JobControl..DistLists dl on dle.ListID = dl.ID
																 and coalesce(dl.disabled,0) = 0
				left outer join JobControl..DistListJobSteps dls on dl.ID = dls.ListID

		union select ltrim(rtrim(coalesce(c.FirstName,'') + ' ' + coalesce(c.LastName,''))) EmailName
				, coalesce(c.FirstName,'') FirstName
				, coalesce(c.LastName,'') LastName
				, c.email EmailAddress
				, coalesce(FTPLOGIN,'') FTPLOGIN
				, coalesce(FTPPASSWRD,'') FTPPASSWRD
				, coalesce(FTPPATH,'') FTPPATH
				, coalesce(FTPURL,'') FTPURL
				, dls.JobStepID
				, dl.ID ListID
				, case when ltrim(rtrim(coalesce(dl.ListName,''))) = '' then 'List:' + ltrim(str(dl.ID)) else dl.ListName end ListName
				, c.CustID SourceID
				, 'Cust' EntryType
				, coalesce(co.CompanyName, c.GroupName) CompanyGroup
				, co.CompanyID
				, case when coalesce(dle.Email,0) = 1 and c.email > ''	then 1 
					else 0 end EmailEntry
				, case when coalesce(dle.FTP,0) = 1 and FTPLOGIN > ''	then 1 
					else 0 end FTPEntry
				, c.CRM_ContactID
				, co.CRM_CompanyID
				, c.SalesRepID
			from OrderControl..Customers c
				left outer join OrderControl..Companies co on co.CompanyID = c.CompanyID 
				left outer join JobControl..DistListEntries dle on c.CustID = dle.SourceID 
																and dle.EntryType = 'Cust'
																and dle.FTP = 1
																and coalesce(dle.disabled,0) = 0
				left outer join JobControl..DistLists dl on dle.ListID = dl.ID
																 and coalesce(dl.disabled,0) = 0
				left outer join JobControl..DistListJobSteps dls on dl.ID = dls.ListID
--=======================================
		union select ltrim(rtrim(coalesce(c.FirstName,'') + ' ' + coalesce(c.LastName,''))) EmailName
				, coalesce(c.FirstName,'') FirstName
				, coalesce(c.LastName,'') LastName
				, c.email EmailAddress
				, coalesce(FTPLOGIN,'') FTPLOGIN
				, coalesce(FTPPASSWRD,'') FTPPASSWRD
				, coalesce(FTPPATH,'') FTPPATH
				, coalesce(FTPURL,'') FTPURL
				, null JobStepID
				, null ListID
				, '' ListName
				, c.CustID SourceID
				, 'Cust' EntryType
				, coalesce(co.CompanyName, c.GroupName) CompanyGroup
				, co.CompanyID
				, case when c.email > '' then 1 else 0 end EmailEntry
				, 0 FTPEntry
				, c.CRM_ContactID
				, co.CRM_CompanyID
				, c.SalesRepID
			from OrderControl..Customers c
				left outer join OrderControl..Companies co on co.CompanyID = c.CompanyID 

		union select ltrim(rtrim(coalesce(c.FirstName,'') + ' ' + coalesce(c.LastName,''))) EmailName
				, coalesce(c.FirstName,'') FirstName
				, coalesce(c.LastName,'') LastName
				, c.email EmailAddress
				, coalesce(FTPLOGIN,'') FTPLOGIN
				, coalesce(FTPPASSWRD,'') FTPPASSWRD
				, coalesce(FTPPATH,'') FTPPATH
				, coalesce(FTPURL,'') FTPURL
				, null JobStepID
				, null ListID
				, '' ListName
				, c.CustID SourceID
				, 'Cust' EntryType
				, coalesce(co.CompanyName, c.GroupName) CompanyGroup
				, co.CompanyID
				, 0 EmailEntry
				, case when FTPLOGIN > ''	then 1 else 0 end FTPEntry
				, c.CRM_ContactID
				, co.CRM_CompanyID
				, c.SalesRepID
			from OrderControl..Customers c
				left outer join OrderControl..Companies co on co.CompanyID = c.CompanyID 

--======================================
		union select ltrim(rtrim(coalesce(c.FirstName,'') + ' ' + coalesce(c.LastName,''))) EmailName
				, coalesce(c.FirstName,'') FirstName
				, coalesce(c.LastName,'') LastName
				, c.email EmailAddress
				, coalesce(null,'') FTPLOGIN
				, coalesce(null,'') FTPPASSWRD
				, coalesce(null,'') FTPPATH
				, coalesce(null,'') FTPURL
				, dls.JobStepID
				, dl.ID ListID
				, case when ltrim(rtrim(coalesce(dl.ListName,''))) = '' then 'List:' + ltrim(str(dl.ID)) else dl.ListName end ListName
				, c.SalesRepID SourceID
				, 'SalesRep' EntryType
				, 'TWG SalesRep' CompanyGroup
				, null CompanyID
				, case when coalesce(dle.Email,0) = 1
						or (coalesce(dle.Email,0) = 0 and c.email > '')	then 1 
					else 0 end EmailEntry
				, convert(bit, 0) FTPEntry
				, null CRM_ContactID
				, null CRM_CompanyID
				, null SalesRepID
			from OrderControl..SalesReps c
				left outer join JobControl..DistListEntries dle on c.SalesRepID = dle.SourceID
																	and coalesce(dle.disabled,0) = 0
																	and EntryType = 'SalesRep'
				left outer join JobControl..DistLists dl on dl.ID = dle.ListID
																 and coalesce(dl.disabled,0) = 0
				left outer join JobControl..DistListJobSteps dls on dl.ID = dls.ListID
		
		union select ltrim(rtrim(mu.username)) EmailName
				, '' FirstName
				, '' LastName
				, mu.EmailAddress
				, coalesce(null,'') FTPLOGIN
				, coalesce(null,'') FTPPASSWRD
				, coalesce(null,'') FTPPATH
				, coalesce(null,'') FTPURL
				, dls.JobStepID
				, dl.ID ListID
				, case when ltrim(rtrim(coalesce(dl.ListName,''))) = '' then 'List:' + ltrim(str(dl.ID)) else dl.ListName end ListName
				, mu.UserID SourceID
				, 'User' EntryType
				, 'TWG Wired User' CompanyGroup
				, null CompanyID
				, case when coalesce(dle.Email,0) = 1
						or (coalesce(dle.Email,0) = 0 and coalesce(mu.EmailAddress,'') > '') then 1 
					else 0 end EmailEntry
				, convert(bit, 0) FTPEntry
				, null CRM_ContactID
				, null CRM_CompanyID
				, null SalesRepID
			from Support..MasterUser mu
				left outer join JobControl..DistListEntries dle on mu.UserID = dle.SourceID
																	and EntryType = 'User'
																	and coalesce(dle.disabled,0) = 0
				left outer join JobControl..DistLists dl on dl.ID = dle.ListID
															and coalesce(dl.disabled,0) = 0
				left outer join JobControl..DistListJobSteps dls on dls.ListID = dl.ID

		union select ltrim(rtrim(coalesce(dle.EmailName,''))) EmailName
				, '' FirstName
				, '' LastName
				, ltrim(rtrim(coalesce(dle.EmailAddress,''))) EmailAddress
				, coalesce(null,'') FTPLOGIN
				, coalesce(null,'') FTPPASSWRD
				, coalesce(null,'') FTPPATH
				, coalesce(null,'') FTPURL
				, dls.JobStepID
				, dl.ID ListID
				, case when ltrim(rtrim(coalesce(dl.ListName,''))) = '' then 'List:' + ltrim(str(dl.ID)) else dl.ListName end ListName
				, dle.SourceID
				, dle.EntryType
				, 'Standalone Email' CompanyGroup
				, null CompanyID
				, convert(bit, case when ltrim(rtrim(coalesce(dle.EmailAddress,''))) > '' then 1 else 0 end) EmailEntry
				, convert(bit, 0) FTPEntry
				, null CRM_ContactID
				, null CRM_CompanyID
				, null SalesRepID
			from JobControl..DistListJobSteps dls
				join JobControl..DistLists dl on dl.ID = dls.ListID
													and coalesce(dl.disabled,0) = 0
				join JobControl..DistListEntries dle on dle.ListID = dl.ID and coalesce(dle.disabled,0) = 0
			where ltrim(rtrim(coalesce(dle.EmailAddress,''))) > ''

		) x
		left outer join JobControl..JobSteps js on js.StepID = x.JobStepID

	where (x.EmailEntry = 1	or x.FTPEntry = 1)
