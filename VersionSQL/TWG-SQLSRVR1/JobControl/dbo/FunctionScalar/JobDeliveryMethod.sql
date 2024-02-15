/****** Object:  ScalarFunction [dbo].[JobDeliveryMethod]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 03/14/2019 (Happy Pi Day)
-- Description:	Returns what the Job Delivery Method(s) is/are.
-- =============================================
CREATE FUNCTION dbo.JobDeliveryMethod 
(
	@JobID int
)
RETURNS varchar(25)
AS
BEGIN
	Declare @RetVal varchar(25) = '';

	Select @RetVal=Substring(
		iif(exists(select StepID from JobSteps where JobID=@JobID and StepTypeID=1091 and StepName='Deliver File(s) by EMail'),'/Email','')+
		iif(exists(select StepID from JobSteps where JobID=@JobID and StepTypeID=1091 and StepName='Deliver File(s) by FTP'),'/FTP','')+
		iif(exists(select StepID from JobSteps where JobID=@JobID and StepTypeID=1091 and StepName='Deliver File(s) by Postal Mail'),'/Postal Mail',''), 2, 25)
	
	RETURN @RetVal
END
