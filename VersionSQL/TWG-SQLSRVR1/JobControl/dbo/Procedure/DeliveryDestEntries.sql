/****** Object:  Procedure [dbo].[DeliveryDestEntries]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.DeliveryDestEntries @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;


	select DD.ID DestID, js.StepID JobStepID, js.JobID, dd.DestType, dd.DestAddress
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
			, coalesce(djs.EmailCC, 0) EmailCC
			, JobControl.dbo.DeliveryDestSingleEntry2(dd.destType, djs.EmailCC, dd.DestName, dd.DestAddress, dd.FTPPath, dd.FTPUserName, dd.FTPPassword) DeliveryDestPreview
			, coalesce(e.TemplateName,'') TemplateName
			, js.StepTypeID STypeID
			, coalesce(js.Files2BothEmailFTP,0) Files2BothEmailFTP
			, coalesce(js.CtlFiles2BothEmailFTP,0) CtlFiles2BothEmailFTP
		from JobControl..DeliveryJobSteps djs 
			left outer join JobControl..DeliveryDests dd on djs.DeliveryDestID = dd.ID
			join JobControl..JobSteps js on js.StepID = djs.JobStepID
			left outer join OrderControl..Customers c on c.CustID = dd.SourceID and dd.SourceType = 'Cust'
			left outer join OrderControl..SalesReps sr on sr.SalesRepID = dd.SourceID and dd.SourceType = 'Rep'
			left outer join Support..MasterUser u on u.UserID = dd.SourceID and dd.SourceType = 'User'
			left outer join JobControl..EmailTemplates e on e.ID = js.EmailTemplateID
		where djs.JobStepID = @JobStepID
			and djs.DisabledStamp is null
			and dd.id is not null
		order by dd.DestType desc


END
