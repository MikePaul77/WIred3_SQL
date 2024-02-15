/****** Object:  Procedure [dbo].[JC_--JobStep SP Template--]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_--JobStep SP Template-- @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

	begin try

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Start'

		--===================  Do Work Here  ===========================

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Complete'

	end try
	begin catch
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

		declare @logEntry varchar(500)

		set @logEntry ='Error Number ' + cast(@ErrorNumber AS nvarchar(50))+ ', ' +
                         'Error Line '   + cast(@ErrorLine AS nvarchar(50)) + ', ' +
                         'Error Message : ''' + @ErrorMessage + ''''

		print @logEntry

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, @LogSourceName

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

		RAISERROR (@ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  

	end catch

END
