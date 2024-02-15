/****** Object:  ScalarFunction [dbo].[ValidationFieldCondText]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE function dbo.ValidationFieldCondText
(
	@RecID int
)
RETURNS varchar(1000)
As
Begin

	declare @FieldName varchar(100), @FieldSource varchar(100), @SuccessPct int, @CautionPct int, @AbovePct bit, @DataCheck varchar(50), @SpecificValue varchar(50)
	declare @ReadableDataCheck varchar(100)
	declare @UseXForm bit

	declare @Result varchar(1000)

	set @Result = ''

	select @FieldName = coalesce(fl.OutName, tc.Outname)
			, @SuccessPct = v.SuccessPct
			, @CautionPct = coalesce(v.CautionPct,0)
			, @AbovePct = coalesce(v.AbovePct,0)
			, @DataCheck = v.DataCheck
			, @ReadableDataCheck = case when v.DataCheck = 'IsBlank' then 'is blank'
										when v.DataCheck = 'IsNotBlank' then 'is filled'
										when v.DataCheck = 'Contains' then 'has'
										when v.DataCheck = 'Specific' then 'is'
										else '???' end
			, @SpecificValue = coalesce(v.SpecificValue,'')
			, @UseXForm = case when Fl.RecID > 0 then 0 else 1 end
	from JobControl..XFormFieldValidations v
		left outer join JobControl..FileLayoutFields fl on fl.RecID = v.LayoutFieldID and fl.FileLayoutID = v.LayoutID and coalesce(Fl.Disabled,0) = 0
		left outer join JobControl..FileLayouts f on f.Id = v.LayoutID
		left outer join JobControl..TransformationTemplateColumns tc on tc.RecID = v.XFormFieldID and tc.TransformTemplateID = f.TransformationTemplateId
	where coalesce(v.disabled,0) = 0
		and v.RecID = @RecID

		              --  string Result = "";
                --string FieldInfo = $"{LayoutFieldName} {DataCheck} {SpecificValue}";
                --string Direction = AbovePct ? "above" : "below";
                --string Success = $"{SuccessPct}";
                --string Warn = CautionPct > 0 ? $" / {CautionPct}% - Warn" : "";

                --if (Disabled == false)
                --{
                --    Result = $"{FieldInfo} {Direction} {Success}% - Fails{Warn}";
                --}
                --return Result;

	if @FieldName > ''
	begin
		declare @FieldInfo varchar(500), @Direction varchar(20), @Warn varchar(100)
		
		set @FieldInfo = @FieldName + ' ' + @ReadableDataCheck + rtrim(' ' + @SpecificValue)
		
		set @Direction = 'less then'
		if @AbovePct = 1
			set @Direction = 'more then'

		set @Warn = ''
		if @CautionPct > 0
		begin
			set @Warn = ' / ' + ltrim(str(@CautionPct))+ '% - Warn'
		end
		 
		set @Result = @FieldInfo + ' ' + @Direction + ' ' + ltrim(str(@SuccessPct)) + '% - Fails' + @Warn

	end


	RETURN @Result

end
