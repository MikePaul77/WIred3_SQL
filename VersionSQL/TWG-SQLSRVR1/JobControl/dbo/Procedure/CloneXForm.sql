/****** Object:  Procedure [dbo].[CloneXForm]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.CloneXForm @OrigXFormID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @NewXFormID int

	select * 
		into #tempCloanTransformationTemplates
		from JobControl..TransformationTemplates
		where ID = @OrigXFormID

	alter table #tempCloanTransformationTemplates drop column ID

	insert into JobControl..TransformationTemplates
		select * from #tempCloanTransformationTemplates

	set @NewXFormID = @@IDENTITY

	drop table #tempCloanTransformationTemplates

	update JobControl..TransformationTemplates
		set Description = Description + ' [Cloaned from ' + ltrim(str(@OrigXFormID)) + ']'
			--, ShortTransformationName = ShortTransformationName + ' [Cloaned]'
			, AutoName = JobControl.dbo.AutoXFormLayoutName(ID,null)
			, VFPIn = 0
		where ID = @NewXFormID
	
	select * 
		into #tempCloanTransformationTemplateColumns
		from JobControl..TransformationTemplateColumns
		where TransformTemplateID = @OrigXFormID

	alter table #tempCloanTransformationTemplateColumns drop column RecID

	update #tempCloanTransformationTemplateColumns 
		set TransformTemplateID = @NewXFormID

	insert JobControl..TransformationTemplateColumns
		select * from #tempCloanTransformationTemplateColumns

	drop table #tempCloanTransformationTemplateColumns

	declare @OrigLayoutID int, @NewLayoutID int

	DECLARE CurCL CURSOR FOR
		select ID
			from JobControl..FileLayouts
			where TransformationTemplateId = @OrigXFormID

     OPEN CurCL

     FETCH NEXT FROM CurCL into @OrigLayoutID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
		
		select * 
			into #tempCloanFileLayouts
			from JobControl..FileLayouts
			where ID = @OrigLayoutID

		alter table #tempCloanFileLayouts drop column ID

		update #tempCloanFileLayouts
			set TransformationTemplateId = @NewXFormID

		insert JobControl..FileLayouts
			select * from #tempCloanFileLayouts

		set @NewLayoutID = @@IDENTITY

		update JobControl..FileLayouts 
			set AutoName = JobControl.dbo.AutoXFormLayoutName(null,Id)
			where id = @NewLayoutID

		drop table #tempCloanFileLayouts

		select *
			into #tempCloanFileLayoutFields
			from JobControl..FileLayoutFields
			where FileLayoutID = @OrigLayoutID

		alter table #tempCloanFileLayoutFields drop column RecID

		update #tempCloanFileLayoutFields
			set FileLayoutID = @NewLayoutID

		insert JobControl..FileLayoutFields
			select * from #tempCloanFileLayoutFields

		drop table #tempCloanFileLayoutFields

		insert jobcontrol..XFormCustValidataions (LayoutID, Disabled, CodeDescription, Code, UseXForm)
		select @NewLayoutID, Disabled, CodeDescription, Code, UseXForm from jobcontrol..XFormCustValidataions
		where LayoutID = @OrigLayoutID

		insert jobcontrol..XFormFieldValidations (LayoutID,  XFormFieldID, LayoutFieldID, Disabled, ValidationType, SuccessPct, CautionPct, AbovePct, DataCheck, SpecificValue, Note)
		select @NewLayoutID, XFormFieldID, LayoutFieldID, Disabled, ValidationType, SuccessPct, CautionPct, AbovePct, DataCheck, SpecificValue, Note from jobcontrol..XFormFieldValidations
		where LayoutID = @OrigLayoutID

		insert jobcontrol..XFormOtherValidataions (LayoutID, Disabled, LocationWarnRecs, LocationFailRecs, AllLocationsTotal, NoDups)
		select @NewLayoutID, Disabled, LocationWarnRecs, LocationFailRecs, AllLocationsTotal, NoDups from jobcontrol..XFormOtherValidataions
		where LayoutID = @OrigLayoutID

		FETCH NEXT FROM CurCL into @OrigLayoutID
     END
     CLOSE CurCL
     DEALLOCATE CurCL



	 select @NewXFormID as NewXFormID



END
