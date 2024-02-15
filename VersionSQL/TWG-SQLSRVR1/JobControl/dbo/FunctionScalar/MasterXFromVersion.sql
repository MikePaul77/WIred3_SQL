/****** Object:  ScalarFunction [dbo].[MasterXFromVersion]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION MasterXFromVersion
(
	@ID int
)
RETURNS int
AS
BEGIN
	DECLARE @Result int

	declare @CurrentVersion int
	declare @MaxUsedVersion int
	declare @MasterXForm bit

	select @CurrentVersion = coalesce(MasterVersion,1)
			, @MasterXForm = coalesce(MasterXForm,0)
		from JobControl..TransformationTemplates tt
		where ID = @ID

	select @MaxUsedVersion = max(coalesce(SourceMasterXFormVersion,0)) 
		from JobControl..TransformationTemplates tt
		where SourceMasterXFormID = @ID

	if @MasterXForm = 0
		begin
			set @Result = 0
		end
	else
		Begin
		if @CurrentVersion <= @MaxUsedVersion 
			set @Result = @CurrentVersion + 1
		else
			set @Result = @CurrentVersion
		end

	return @Result
	
END
