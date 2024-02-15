/****** Object:  ScalarFunction [dbo].[ApplyLayoutFormat]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.ApplyLayoutFormat
(
	@Value varchar(100), @FormatID int
)
RETURNS varchar(100)
AS
BEGIN

	DECLARE @Result varchar(100)

	--declare @FormatGroup varchar(50)

	set @Value = Ltrim(rtrim(@Value))

	--select @FormatGroup = FormatGroup 
	--	from JobControl..LayoutFormats
	--	where ID = @FormatID

	Set @Result = @Value

	--if @FormatGroup = 'Date'
	if @FormatID in (1,2,3,4,5,6,7,48,1059,1063) -- Date
	begin
		if isdate(@Value) = 1
		Begin
			declare @DateValue datetime
			set @DateValue = @Value
			if @FormatID = 1
				set @Result = Format(@DateValue, 'MM-dd-yy')
			if @FormatID = 2
				set @Result = Format(@DateValue, 'MM-dd-yyyy')
			if @FormatID = 3
				set @Result = Format(@DateValue, 'MM.dd.yy')
			if @FormatID = 4
				set @Result = Format(@DateValue, 'MM.dd.yyyy')
			if @FormatID = 5
				set @Result = Format(@DateValue, 'MM/dd/yy')
			if @FormatID = 6
				set @Result = Format(@DateValue, 'MM/dd/yyyy')
			if @FormatID = 7
				set @Result = Format(@DateValue, 'yyyyMMdd')
			if @FormatID = 1059
				set @Result = Format(@DateValue, 'MMddyyyy')
			if @FormatID = 48
				set @Result = Format(@DateValue, 'M/d')
			if @FormatID = 1063
				set @Result = Format(@DateValue, 'MM/yy')
		end
	end

	if @FormatID in (1054,1055,1056) -- Time
	begin
		if isdate(@Value) = 1
		Begin
			declare @TimeValue datetime
			set @TimeValue = @Value
			if @FormatID = 1054
				set @Result = Format(@TimeValue, 'hh:mm tt')
			if @FormatID = 1055
				set @Result = Format(@TimeValue, 'HH:mm')
			if @FormatID = 1056
				set @Result = Format(@TimeValue, 'hh:mm')
		end
	end

	--if @FormatGroup like 'Num %'
	if @FormatID in (8,9,10,11,12,13,14,15,16,17,18,19,49,50,51,1050,1051,1052,1053,1057,1058) -- Num
	begin
		set @Value = Replace(@Value,',','')
		set @Value = Replace(@Value,'$','')
		set @Value = Replace(@Value,'%','')
		if isnumeric(@Value) = 1
		Begin
			declare @FloatValue float
			set @FloatValue = @Value
			if @FormatID = 8
				set @Result = Format(Round(@FloatValue, 0, 0), '####')
			if @FormatID = 9
				set @Result = Format(Round(@FloatValue, 1, 0), '####.0')
			if @FormatID = 10
				set @Result = Format(Round(@FloatValue, 2, 0), '####.00')
			if @FormatID = 11
				set @Result = Format(Round(@FloatValue, 0, 0), '#,###')
			if @FormatID = 12
				set @Result = Format(Round(@FloatValue, 1, 0), '#,###.0')
			if @FormatID = 13
				set @Result = Format(Round(@FloatValue, 2, 0), '#,###.00')
			if @FormatID = 14
				set @Result = Format(Round(@FloatValue, 0, 1), '####')
			if @FormatID = 15
				set @Result = Format(Round(@FloatValue, 1, 1), '####.0')
			if @FormatID = 16
				set @Result = Format(Round(@FloatValue, 2, 1), '####.00')
			if @FormatID = 17
				set @Result = Format(Round(@FloatValue, 0, 1), '#,###')
			if @FormatID = 18
				set @Result = Format(Round(@FloatValue, 1, 1), '#,###.0')
			if @FormatID = 19
				set @Result = Format(Round(@FloatValue, 2, 1), '#,###.00')
			if @FormatID = 49
				set @Result = '$' + Format(Round(@FloatValue, 0, 1), '#,###')
			if @FormatID = 1057
				set @Result = '$' + Format(Round(coalesce(@FloatValue,0), 0, 1), '#,##0')
			if @FormatID = 50
				set @Result = Format(Round(@FloatValue, 3, 0), '##.000')
			if @FormatID = 51
				set @Result = Format(Round(@FloatValue, 3, 1), '##.000')
			if @FormatID = 1050
				set @Result = Format(Round(@FloatValue, 2, 0), '###0.00')
			if @FormatID = 1051
				set @Result = Format(Round(@FloatValue, 2, 1), '###0.00')
			if @FormatID = 1052
				set @Result = Format(Round(@FloatValue, 2, 0), '###0.0')
			if @FormatID = 1053
				set @Result = Format(Round(@FloatValue, 2, 1), '###0.0')
			if @FormatID = 1058
				set @Result = Format(Round(@FloatValue, 6, 1), '###0.000000')
		end
	end

	--if @FormatGroup = 'Zip'
	if @FormatID in (22,23) -- Zip
	begin
		set @Value = Replace(@Value,'-','')
		if isnumeric(@Value) = 1 and len(@Value) in (4,5,8,9) and @Value not like '%.%'
		Begin
			declare @ZipValue varchar(20)
			set @ZipValue = @Value
			if len(@ZipValue) in (4,8)
				set @ZipValue = '0' + @ZipValue
			if @FormatID = 22
				set @Result = left(@ZipValue,5)
			if @FormatID = 23
			Begin
				set @Result = left(@ZipValue,5)
				if len(@ZipValue) > 5
					set @Result = @Result + '-' + substring(@ZipValue,6,4)
			End
		end
	end

	--if @FormatGroup = 'Phone'
	if @FormatID in (20,21,24) -- Phone
	begin
		set @Value = Replace(@Value,'-','')
		set @Value = Replace(@Value,'(','')
		set @Value = Replace(@Value,')','')
		set @Value = Replace(@Value,'.','')
		set @Value = Replace(@Value,' ','')
		if isnumeric(@Value) = 1
		Begin
			declare @PhoneValue varchar(20)
			set @PhoneValue = @Value
			if len(@PhoneValue) = 10
			Begin
				if @FormatID = 20
					set @Result = substring(@PhoneValue,1,3) + '-' + substring(@PhoneValue,4,3) + '-' + substring(@PhoneValue,7,4)
				if @FormatID = 21
					set @Result = '(' + substring(@PhoneValue,1,3) + ') ' + substring(@PhoneValue,4,3) + '-' + substring(@PhoneValue,7,4)
				if @FormatID = 24
					set @Result = substring(@PhoneValue,1,3) + '.' + substring(@PhoneValue,4,3) + '.' + substring(@PhoneValue,7,4)
			end
		end
	end

	RETURN @Result

END
