/****** Object:  Procedure [dbo].[AddValidataionToJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.AddValidataionToJob @JobID int
AS
BEGIN
	SET NOCOUNT ON;

		declare @ValStepID int
		declare @RecCount int

		select @ValStepID = StepID from JobControl..JobSteps where JobID = @JobID and coalesce(disabled,0) = 0 and StepTypeID in (1121)

		if @ValStepID is null
		begin

			update JobControl..Jobs set NoticeOnFailure = 1 where JobID = @JobID

			declare @DelivDestID int
			 DECLARE curAddDests CURSOR FOR
				  select ID from JobControl..DeliveryDests 
					--where ID in (846,1026,1217) -- Mike, Sam, Ellen
					where ID in (2772) -- JobValidations@theWarrenGroup.com

			 OPEN curAddDests

			 FETCH NEXT FROM curAddDests into @DelivDestID
			 WHILE (@@FETCH_STATUS <> -1)
			 BEGIN

					select @RecCount = Count(*) from JobControl..DeliveryJobs where JobID = @JobID and DeliveryDestID = @DelivDestID
					if @RecCount = 0
						insert JobControl..DeliveryJobs (DeliveryDestID, JobID, CreatedStamp, CreatedByUser) values (@DelivDestID, @JobID, getdate(), '')

				  FETCH NEXT FROM curAddDests into @DelivDestID
			 END
			 CLOSE curAddDests
			 DEALLOCATE curAddDests

			declare @DelivStepID int
			declare @DelivStepOrder int
			declare @XFormStepID int
			declare @XFormLayoutID int

			declare @DeliverySteps int
			declare @XFormSteps int


			select @DeliverySteps = count(*)
				from JobControl..JobSteps 
				where JobID = @JobID and coalesce(disabled,0) = 0 and StepTypeID in (1091,1125)

			select @XFormSteps = count(*)
				from JobControl..JobSteps 
				where JobID = @JobID and coalesce(disabled,0) = 0 and StepTypeID in (29)

			select top 1 @DelivStepID = StepID, @DelivStepOrder = StepOrder 
				from JobControl..JobSteps 
				where JobID = @JobID 
					--and coalesce(disabled,0) = 0
					and StepTypeID in (1091,1125)
				order by StepOrder desc
 
			Declare @XFormIDsCSV varchar(500) = ''
			DECLARE curXFormSteps CURSOR FOR
				select StepID, FileLayoutID  
					from JobControl..JobSteps 
					where JobID = @JobID and coalesce(disabled,0) = 0 and StepTypeID in (29)

			OPEN curXFormSteps

			FETCH NEXT FROM curXFormSteps into @XFormStepID, @XFormLayoutID
			WHILE (@@FETCH_STATUS <> -1)
			BEGIN
				
				if @XFormIDsCSV = ''
					set @XFormIDsCSV = ltrim(str(@XFormStepID))
				else
					set @XFormIDsCSV = @XFormIDsCSV  + ',' + ltrim(str(@XFormStepID))

				select @RecCount = Count(*) from XFormOtherValidataions where LayoutID = @XFormLayoutID
				if @RecCount = 0
				begin
					insert XFormOtherValidataions (LayoutID, Disabled, LocationWarnRecs, LocationFailRecs, AllLocationsTotal) values (@XFormLayoutID,0,0,0,1)
				end
				else
				begin
					update XFormOtherValidataions set Disabled = 0, LocationWarnRecs = 0, LocationFailRecs = 0, AllLocationsTotal = 1
						where LayoutID = @XFormLayoutID
				end

				select @RecCount = Count(*) from XFormRunCountValidataions where LayoutID = @XFormLayoutID
				if @RecCount = 0
				begin
					insert XFormRunCountValidataions (LayoutID, LastRuns, PctFail, PctWarn, Disabled) values (@XFormLayoutID,0,0,0,1)
				end
				else
				begin
					update XFormRunCountValidataions set Disabled = 1
						where LayoutID = @XFormLayoutID
				end


				FETCH NEXT FROM curXFormSteps into @XFormStepID, @XFormLayoutID
			END
			CLOSE curXFormSteps
			DEALLOCATE curXFormSteps


			declare @Disabled bit = 0
			if @DeliverySteps <> 1 or @XFormSteps <> 1
				set @Disabled = 1

			insert JobControl..JobSteps (JobID, StepOrder, StepName, StepTypeID, SQLJobStepID, RunModeID, DependsOnStepIDs, Disabled, UpdatedStamp, UnSavedTempStep)
				values(@JobID, @DelivStepOrder,'', 1121, @DelivStepOrder, 1 , @XFormIDsCSV, @Disabled, getdate(), 0)

			update JobControl..JobSteps set StepOrder = StepOrder + 1, SQLJobStepID = SQLJobStepID + 1
				where JobID = @JobID and StepTypeID <> 1121 and StepOrder >= @DelivStepOrder

		end

		select @JobID JobID
			, case when @DeliverySteps <> 1 then 2
					when @XFormSteps <> 1 then 2
					when @ValStepID > 1 then 3 else 1 end Result
			, case when @DeliverySteps <> 1 then 'Multiple enabled Delivery Steps; ' else '' end
				+ case when @XFormSteps <> 1 then 'Multiple enabled XFrom Steps; ' else '' end
				+ case when @ValStepID > 1 then 'Validation Step allready exists; ' else '' end Issue

END
