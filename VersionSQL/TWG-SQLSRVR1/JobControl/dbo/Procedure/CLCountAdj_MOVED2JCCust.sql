/****** Object:  Procedure [dbo].[CLCountAdj_MOVED2JCCust]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		MP
-- Create date: 9/16/20
-- Description:	ajusts the billing record counts for CoreLogic
--				For VA and OH they pay only per image (unique book, page and Doc)  
--				Adjustst the Layout column CLRecCount that starts at 
--				2 for MTG and Sale in same rec
--				1 For for stand along Sale or Mtg
--				1 for Assigments & Dischages
-- =============================================
CREATE PROCEDURE CLCountAdj @DependsonStepIDs varchar(100), @JobStepID int, @DocType varchar(10)
AS
BEGIN
	SET NOCOUNT ON;
		
	begin try

		declare @DependsOnStepTableName varchar(500)

		select @DependsOnStepTableName = 'JobControlWork..' + dst.StepName + 'StepResults_J' + ltrim(str(djs.JobID)) + '_S' + ltrim(str(djs.StepID))
		from JobControl..JobSteps djs
			join JobStepTypes dst on djs.StepTypeID = dst.StepTypeID
		where ',' + ltrim(str(djs.StepID)) + ',' like '%,' +  @DependsonStepIDs + ',%'

		if @DependsOnStepTableName is null
			begin
				print 'Aborting because there is no DependsOnStepID for this step';
				exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, 'No DependsOnStepID was specified', 'CLCountAdj';
				exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
				Return
			end
		else
			begin
				print @DependsOnStepTableName
				IF OBJECT_ID(@DependsOnStepTableName, 'U') IS NULL
				Begin
					print 'Aborting because the DependsOn Table does not exist';
					exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, 'DependsOn Table does not exist', 'CLCountAdj';
					exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail';
					Return
				end

				declare @cmd varchar(max)
				declare @StateIDList varchar(100) = '40,53'	-- OH,VA

				if @DocType = 'SM'	-- Sales & Morts
				begin

					set @cmd = ' update x set XF_CLRecCount = XF_CLRecCount - case when ds.MinTransID = x.XF_TRANID then 0
																					when dm.MinTransID = x.XF_TRANID then 0
																					when ds.MinTransID is not null and dm.MinTransID is not null then -2
																					when ds.MinTransID is not null or dm.MinTransID is not null then -1
																					else 0 end
						from ' + @DependsOnStepTableName + ' x
							left outer join (select stateID, countyID, TransactionType, SaleBook Book, SalePage Page, SaleDocumentNum DocNum, count(*) Recs, min(XF_TRANID) MinTransID
												from ' + @DependsOnStepTableName + '
												where stateID in (' + @StateIDList + ')
													and TransactionType = ''S''
													and SaleBook > 0 and SalePage > 0
												group by stateID, countyID, TransactionType, SaleBook, SalePage, SaleDocumentNum
												having count(*) > 1
											) ds on ds.StateID = x.StateID
														and ds.CountyId = x.CountyId
														and ds.TransactionType = x.TransactionType
														and ds.Book = x.SaleBook
														and ds.Page = x.SalePage
														and ds.DocNum = x.SaleDocumentNum
							left outer join (select StateID, countyID, TransactionType, MtgBook Book, MtgPage Page, MtgDocumentNum DocNum, count(*) Recs, min(XF_TRANID) MinTransID
												from ' + @DependsOnStepTableName + '
												where stateID in (' + @StateIDList + ')
													and MtgAmount > 1
													and MtgBook > 0 and MtgPage > 0
												group by stateID, countyID, TransactionType, MtgBook, MtgPage, MtgDocumentNum
												having count(*) > 1
											) dm on dm.StateID = x.StateID
														and dm.CountyId = x.CountyId
														and dm.TransactionType = x.TransactionType
														and dm.Book = x.MtgBook
														and dm.Page = x.MtgPage
														and dm.DocNum = x.MtgDocumentNum
						where x.stateID in (' + @StateIDList + ') '

						print @cmd
						exec(@cmd)

				end

				if @DocType = 'A'	-- Assigments
				begin
					set @cmd = ' update x set XF_CLRecCount = XF_CLRecCount - case when da.MinTransID = x.XF_ASSGNID then 0
													when da.MinTransID is not null then -1
													else 0 end
					from ' + @DependsOnStepTableName + ' x
						join (select stateID, countyID, Book, Page, DocumentNum, count(*) Recs, min(XF_ASSGNID) MinTransID
											from ' + @DependsOnStepTableName + '
											where stateID in (' + @StateIDList + ')
											group by stateID, countyID, Book, Page, DocumentNum
											having count(*) > 1
										) da on da.StateID = x.StateID
													and da.CountyId = x.CountyId
													and da.Book = x.Book
													and da.Page = x.Page
													and da.DocumentNum = x.DocumentNum
					where x.stateID in (' + @StateIDList + ') '

				end

				if @DocType = 'D'	-- Discharges
				begin
					set @cmd = ' update x set XF_CLRecCount = XF_CLRecCount - case when da.MinTransID = x.XF_DISCHID then 0
													when da.MinTransID is not null then -1
													else 0 end
					from ' + @DependsOnStepTableName + ' x
						join (select stateID, countyID, Book, Page, DocumentNum, count(*) Recs, min(XF_DISCHID) MinTransID
											from ' + @DependsOnStepTableName + '
											where stateID in (' + @StateIDList + ')
											group by stateID, countyID, Book, Page, DocumentNum
											having count(*) > 1
										) da on da.StateID = x.StateID
													and da.CountyId = x.CountyId
													and da.Book = x.Book
													and da.Page = x.Page
													and da.DocumentNum = x.DocumentNum
					where x.stateID in (' + @StateIDList + ') '
				end


			end

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

		exec JobControl.dbo.JobStepLogInsert @JobStepID, 3, @logEntry, 'CLCountAdj'

		exec JobControl.dbo.JobControlStepUpdate @JobStepID, 'Fail'

		RAISERROR (@ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  

	end catch

END
