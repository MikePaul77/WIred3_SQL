/****** Object:  Procedure [dbo].[GroupCountProcessLoopDone]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GroupCountProcessLoopDone @BeginStepID int, @EndStepID int 
AS
BEGIN
	SET NOCOUNT ON;

	declare @cmd  varchar(max)

	begin try

		 declare @RepStepTable varchar(500)      
		 DECLARE RepStepcurA CURSOR FOR
				select 'ReportStepRepCount_J' + ltrim(str(Djs.JobID)) + '_S' + ltrim(str(Djs.StepID))
					from JobSteps js 
						join JobSteps jsB on jsB.StepID = @BeginStepID and js.StepOrder > jsB.StepOrder and jsB.JobID = js.JobID
						join JobSteps jsE on jsE.StepID = @EndStepID and js.StepOrder < jsE.StepOrder and jsE.JobID = js.JobID
						left outer join JobSteps Djs on js.JobID = Djs.JobID and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(Djs.StepID)) + ',%'
						left outer join JobStepTypes Djst on Djst.StepTypeID = Djs.StepTypeID
					where js.StepTypeID = 1101

		 OPEN RepStepcurA

		 FETCH NEXT FROM RepStepcurA into @RepStepTable  
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN

				set @cmd = 'update JobControlWork..' + @RepStepTable + ' set __Processed = 1 where __Processed = 0 '

				--print @cmd
				--exec JobControl.dbo.JobStepLogInsert @EndStepID, 1, @cmd, 'GroupCountProcessLoopDone'
				exec(@cmd)

			  FETCH NEXT FROM RepStepcurA into @RepStepTable  
		 END
		 CLOSE RepStepcurA
		 DEALLOCATE RepStepcurA

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

		exec JobControl.dbo.JobStepLogInsert @EndStepID, 3, @logEntry, 'GroupCountProcessLoopDone'

		exec JobControl.dbo.JobControlStepUpdate @EndStepID, 'Fail'

		RAISERROR (@ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  

	end catch

end
