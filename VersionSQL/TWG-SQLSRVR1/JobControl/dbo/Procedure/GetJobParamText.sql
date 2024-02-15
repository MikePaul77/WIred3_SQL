/****** Object:  Procedure [dbo].[GetJobParamText]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: March 11, 2019
-- Description:	Returns a text string of the current job parameters
-- =============================================
CREATE PROCEDURE dbo.GetJobParamText
	@JobID int,
	@ReturnValue varchar(50) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	Declare @IssueMonth varchar(10)='',
		@IssueWeek varchar(10)='',
		@CalPeriod varchar(10)='',
		@CalYear varchar(10)='',
		@ParamName varchar(10)='',
		@ParamValue varchar(10)='',
		@StateCode varchar(10) = ''

	Declare jpCursor CURSOR for
		Select ltrim(rtrim(jp.ParamName)), jp.ParamValue
			from JobParameters jp
			where JobID=@JobID;
	Open jpCursor;
	Fetch Next from jpCursor into @ParamName, @ParamValue
	While @@Fetch_Status=0
	Begin
		if @ParamName='IssueMonth' and @IssueMonth='' set @IssueMonth=@ParamValue;
		if @ParamName='IssueWeek' and @IssueWeek='' set @IssueWeek=@ParamValue;
		if @ParamName='CalPeriod' and @CalPeriod='' set @CalPeriod=@ParamValue;
		if @ParamName='CalYear' and @CalYear='' set @CalYear=@ParamValue;
		if @ParamName='StateID' and @StateCode='' set @StateCode=@ParamValue;
		Fetch Next from jpCursor into @ParamName, @ParamValue
	End
	Close jpCursor;
	Deallocate jpCursor;

	If @IssueWeek<>''
		Begin
			Select @ReturnValue='IW: ' + @IssueWeek;
		End
	Else
		if @IssueMonth<>''
			Begin
				Select @ReturnValue='IM: ' + @IssueMonth + iif(@CalYear='','',' CY: '+@CalYear);
			End
		else
			if @CalPeriod <>''
			Begin
				Select @ReturnValue='CP: ' + @CalPeriod + iif(@CalYear='','',' CY: '+@CalYear);
			End
			else
				begin
					if @ParamName = 'FullLoad'
						begin
							Select @ReturnValue='Full Load'
						end
				else
					begin
					select @ReturnValue = ''
					end
				end
	if @StateCode <> ''
	Begin

		declare @StateList varchar(500)

			Select @StateList = coalesce(@StateList + ',','') + coalesce(s.code,'')	
				from Lookups..States s
			where ',' + @StateCode + ',' like '%,' + ltrim(str(s.Id)) + ',%'

		Select @ReturnValue = @ReturnValue + ' ST: ' +@StateList;
	end

RETURN
END
