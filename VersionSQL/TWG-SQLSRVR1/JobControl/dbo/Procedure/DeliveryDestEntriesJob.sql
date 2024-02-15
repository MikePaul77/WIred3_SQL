/****** Object:  Procedure [dbo].[DeliveryDestEntriesJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.DeliveryDestEntriesJob @JobID int
AS
BEGIN
	SET NOCOUNT ON;


	select DD.ID DestID, dj.JobID
			, case when dd.DestType = 'Email' then 1 else 0 end EmailEntry
			, case when dd.DestType in ('FTP','SFTP','FTP/S') then 1 else 0 end FTPEntry
			, dd.SourceType EntryType, dd.SourceID
			, case when dd.DestType = 'Email' then dd.DestAddress else null end EmailAddress
			, case when dd.DestType in ('FTP','SFTP','FTP/S') then isnull(dd.DestType,'') else '' end FTPType
			, case when dd.DestType in ('FTP','SFTP','FTP/S') then isnull(dd.DestAddress,'') else '' end FTPURL
			, isnull(dd.FTPPath,'') FTPPath, isnull(dd.FTPUserName,'') FTPLogin, isnull(dd.FTPPassword,'') FTPPassword
			, isnull(dd.FTPKey,'') FTPKey
			, case when dd.SourceType = 'Cust' then ltrim(coalesce(c.FirstName,'') + ' ' + coalesce(c.LastName,''))
				when dd.SourceType = 'Rep' then ltrim(coalesce(sr.FirstName,'') + ' ' + coalesce(sr.LastName,''))
				when dd.SourceType = 'User' then u.UserName else  '' end EmailName
			, coalesce(dj.EmailCC, 0) EmailCC
			, JobControl.dbo.DeliveryDestSingleEntry(dd.destType, dj.EmailCC, dd.DestName, dd.DestAddress, dd.FTPPath, dd.FTPUserName) DeliveryDestPreview
		from JobControl..DeliveryJobs dj 
			left outer join JobControl..DeliveryDests dd on dj.DeliveryDestID = dd.ID
			left outer join OrderControl..Customers c on c.CustID = dd.SourceID and dd.SourceType = 'Cust'
			left outer join OrderControl..SalesReps sr on sr.SalesRepID = dd.SourceID and dd.SourceType = 'Rep'
			left outer join Support..MasterUser u on u.UserID = dd.SourceID and dd.SourceType = 'User'
		where dj.JobID = @JobID
			and dj.DisabledStamp is null
		order by dj.CreatedStamp


END
