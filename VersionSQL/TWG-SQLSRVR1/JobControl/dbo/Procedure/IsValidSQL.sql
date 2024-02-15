/****** Object:  Procedure [dbo].[IsValidSQL]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE IsValidSQL @SqlCmd varchar(max)
AS
BEGIN
	SET NOCOUNT ON;

	declare @IsValid int = 0
	declare @NotValidIssue varchar(4000) = ''

	set @SqlCmd = 'set Noexec on;' + char(10) + @SqlCmd + char(10) + 'set Noexec off;' + char(10)

	begin Try
		Exec(@SQLCMD)
		set @IsValid = 1
	end Try
 	begin catch
		set @IsValid = 0

		DECLARE @ErrorMessage NVARCHAR(4000);  
		DECLARE @ErrorSeverity INT;  
		DECLARE @ErrorState INT;  
		DECLARE @ErrorNumber INT;  
		DECLARE @ErrorLine INT;  

		SELECT   
			@ErrorMessage = ERROR_MESSAGE(),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorNumber = ERROR_NUMBER(),  
			@ErrorLine = ERROR_LINE(),  
			@ErrorState = ERROR_STATE();  

		set @NotValidIssue =  @ErrorMessage


	end catch






	SELECT @IsValid IsValid, @NotValidIssue NotValidIssue
END
