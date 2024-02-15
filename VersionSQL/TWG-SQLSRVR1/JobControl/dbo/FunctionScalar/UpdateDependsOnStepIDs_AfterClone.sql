/****** Object:  ScalarFunction [dbo].[UpdateDependsOnStepIDs_AfterClone]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 7/10/2020
-- Description:	Updates the DependsOnStepIDs for a StepID after a job has been cloned
-- =============================================
CREATE FUNCTION dbo.UpdateDependsOnStepIDs_AfterClone  
(
	@pStepID int
)
RETURNS varchar(500)
AS
BEGIN
	Declare @ReturnedList varchar(500)='',
			@NewJobID int, 
			@IDList varchar(500);

	Select @NewJobID=JobID, @IDList=DependsOnStepIDs
		from JobSteps where StepID=@pStepID;

	if @IDList<>''
		Begin
			Declare @StepCount int, 
				@CurrentStep int = 1, 
				@CurrentStepID int, 
				@NewStepID int, 
				@sCurrentStepID varchar(10);
			Set @IDList=@IDList + ',';
			select @StepCount = len(@IDList) - len(replace(@IDList, ',', ''))
			While (@CurrentStep<=@StepCount)
			Begin
				set @sCurrentStepID=substring(@IDList, 1, CHARINDEX(',',@IDLIST)-1);
				Set @IDList=substring(@IDList, CHARINDEX(',',@IDLIST)+1,100)
				set @CurrentStepID=convert(int, @sCurrentStepID);
				Select @NewStepID=StepID 
					from JobSteps 
					where JobID=@NewJobID 
						and StepOrder=(Select StepOrder from JobSteps where StepID=@CurrentStepID);
				Set @ReturnedList=@ReturnedList + convert(varchar, @NewStepID) + ','
				Set @CurrentStep=@CurrentStep+1
			End
			if right(@ReturnedList,1)=',' set @ReturnedList=left(@ReturnedList,len(@ReturnedList)-1)
		End
	RETURN @ReturnedList;
END
