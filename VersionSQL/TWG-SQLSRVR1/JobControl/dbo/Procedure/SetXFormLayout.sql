/****** Object:  Procedure [dbo].[SetXFormLayout]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE SetXFormLayout @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @FileLayoutID int
	declare @DestTable varchar(100)
	declare @Cmd varchar(max)

	Declare @WorkDB varchar(50) = 'JobControlWork'

	select @FileLayoutID = js.FileLayoutID
			, @DestTable = jst.StepName + 'StepResults_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID))
		from JobSteps js 
			left outer join JobStepTypes jst on jst.StepTypeID =js.StepTypeID
	where js.StepID = @JobStepID

	declare @OutType varchar(50),
			@OutWidth int,
			@OutName varchar(200),
			@CaseChange varchar(50),
			@DoNotTrim bit,
			@Padding varchar(20),
			@PaddingLength int,
			@PaddingChar varchar(5),
			@DecimalPlaces int,
			@XLNoFormat bit,
			@XLAlign varchar(7),
			@Hide bit,
			@LayoutFormatID int


     DECLARE curFLF CURSOR FOR
          select OutType, OutWidth, OutName, CaseChange, DoNotTrim, Padding, PaddingLength, PaddingChar, DecimalPlaces, XLNoFormat, XLAlign, Hide, LayoutFormatID
			from JobControl..FileLayoutFields
			where FileLayoutID = @FileLayoutID
				and coalesce(Disabled,0) = 0
			order by OutOrder

     OPEN curFLF

     FETCH NEXT FROM curFLF into @OutType, @OutWidth, @OutName, @CaseChange, @DoNotTrim, @Padding, @PaddingLength, @PaddingChar, @DecimalPlaces, @XLNoFormat, @XLAlign, @Hide, @LayoutFormatID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

			if coalesce(@CaseChange,'None') = 'lower'
			Begin

				set @Cmd = 'update ' + @WorkDB + '..' +  @DestTable + ' set [' + @OutName + ']  = lower([' + @OutName + ']) '
				print @Cmd
				exec(@Cmd)

			End

			if coalesce(@CaseChange,'None') = 'upper'
			Begin

				set @Cmd = 'update ' + @WorkDB + '..' +  @DestTable + ' set [' + @OutName + ']  = upper([' + @OutName + ']) '
				print @Cmd
				exec(@Cmd)

			End

			if coalesce(@CaseChange,'None') = 'proper'
			Begin

				set @Cmd = 'update ' + @WorkDB + '..' +  @DestTable + ' set [' + @OutName + ']  = Support.FuncLib.ProperCase([' + @OutName + ']) '
				print @Cmd
				exec(@Cmd)

			End

          FETCH NEXT FROM curFLF into @OutType, @OutWidth, @OutName, @CaseChange, @DoNotTrim, @Padding, @PaddingLength, @PaddingChar, @DecimalPlaces, @XLNoFormat, @XLAlign, @Hide, @LayoutFormatID
     END
     CLOSE curFLF
     DEALLOCATE curFLF	

END
