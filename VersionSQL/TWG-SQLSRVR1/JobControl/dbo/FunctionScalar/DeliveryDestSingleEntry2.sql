/****** Object:  ScalarFunction [dbo].[DeliveryDestSingleEntry2]    Committed by VersionSQL https://www.versionsql.com ******/

create FUNCTION dbo.DeliveryDestSingleEntry2
(@DestType varchar(10), @EmailCC bit, @DestName varchar(100), @DestAddress varchar(50), @FTPPath varchar(500), @FTPUserName varchar(100), @FTPUserPwd varchar(50))
RETURNS varchar(500)
AS
BEGIN
	DECLARE @Result varchar(500)

	set @Result = Support.FuncLib.ProperCase(@DestType)
							+ case when @DestType = 'EMail' then 
								case when @EmailCC = 1 then ' cc' else ' to' end
							else '' end
						+ ': '
						+ case when @DestName > '' and @DestType not in ('FTP', 'SFTP') then @DestName + ' [' + @Destaddress + ']'  else @Destaddress  end 
						+ case when @DestType in ('FTP', 'SFTP') and @FTPPath > '' then ' ('+ @FTPPath + ')' else '' end						
						+ case when @DestType in ('FTP', 'SFTP') then ' Acct: ' + @FTPUsername else '' end						
						+ case when @DestType in ('FTP', 'SFTP') then ' Pwd: ' + @FTPUserPwd else '' end						


	RETURN @Result

END
