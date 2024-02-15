/****** Object:  Procedure [dbo].[Iterative_SCT]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 5/15/2019
-- Description:	Finds out if a report is part of an iterative loop.  
--				If so a value starting with a State, County or Town and then
--				is followed with the State, County or Town name (or ID).
-- =============================================
CREATE PROCEDURE dbo.Iterative_SCT 
	@JobStepID int,
	@NameOrID varchar(1),
	@SCT varchar(100) OUTPUT,
	@ReturnID int OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
    Declare @JobID int, 
		@StepOrder int,
		@LoopStepID int,
		@StepName varchar(100),
		@StepTypeID int,
		@SCTID int;

	Set @SCT='';

	Select @JobID=JobID, @StepOrder = StepOrder from JobControl..JobSteps where StepID=@JobStepID;

	Select Top 1 @StepName=[StepName], @LoopStepID = StepID, @StepTypeID = StepTypeID
		from JobControl..JobSteps 
		where JobId=@JobID 
			and StepOrder<@StepOrder 
			--and StepName like '%Loop%'
			and StepTypeID in (1107,1108) -- Begin and End Loop
		Order by StepOrder desc;

--	If @StepName='Begin Loop'
	If @StepTypeID = 1107    -- Begin Loop
		Begin	
			Declare @TargetFile varchar(100) = 'JobControlWork..BeginLoopStepResults_J' + convert(varchar, @JobID) + '_S' + convert(varchar, @LoopStepID);
			Declare @SCTName varchar(100), @dSQL nvarchar(100)
			IF OBJECT_ID(@TargetFile, 'U') IS NOT NULL
				Begin
					IF COL_LENGTH(@TargetFile, 'RegistryID') IS NOT NULL
						set @SCT='Registry'
					else
						IF COL_LENGTH(@TargetFile, 'CountyID') IS NOT NULL
							set @SCT='County'
						else
							IF COL_LENGTH(@TargetFile, 'TownID') IS NOT NULL
								set @SCT='Town'
							else
								set @SCT='State';

					set @dSQL='Select @SCTID=' + @SCT + 'ID from ' + @TargetFile + ' where ProcessFlag=1';
					exec sp_executesql @dSQL, N' @SCTID int Output', @SCTID output;
					set @ReturnID=@SCTID;


					if @NameOrID='N'
						Begin
							if @SCT='Registry'
								Select @SCTName=Registryname from lookups..Registries where ID=@SCTID;
							else
								if @SCT='County'
									Select @SCTName=fullname from lookups..Counties where ID=@SCTID;
								else
									if @SCT='Town'
										Select @SCTName=fullname from lookups..Towns where ID=@SCTID;
									else
										Select @SCTName=fullname from lookups..States where ID=@SCTID;
							Set @SCT = @SCT + ': ' + isnull(@SCTName, '');
						End
					Else
						Set @SCT = @SCT + ': ' + convert(varchar, @SCTID)
				End
		End

	Return;
END
