/****** Object:  Procedure [dbo].[AddCountStepsToJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.AddCountStepsToJob @JobStepID int, @GroupByFields varchar(max)
as
BEGIN
	SET NOCOUNT ON;


	declare @XFormID int, @LayoutID int, @QueryTemplateID int, @JobID int, @DeliveryStepID int
	declare @NewXFormID int, @NewLayoutID int, @DeliveryStepOrder int

	select @XFormID = js.TransformationID
			, @LayoutID  = js.FileLayoutID
			, @QueryTemplateID = js.QueryTemplateID
			, @JobID = js.JobID
		from JobControl..Jobsteps js
		where js.stepID = @JobStepID
			and js.StepTypeID = 29

	select @DeliveryStepID = js.StepID
			, @DeliveryStepOrder = js.StepOrder
		from JobControl..Jobsteps js
		where js.JobID = @JobID
			and js.StepTypeID = 1125

	declare @CountField varchar(100)

	select @CountField = value
			from Support.FuncLib.Splitstring(@GroupByFields,'|')
			where seq = 1

	insert JobControl..TransformationTemplates (QueryTemplateID) values(-1)

	select @NewXFormID = Max(ID) from JobControl..TransformationTemplates where QueryTemplateID = -1

	update JobControl..TransformationTemplates set AutoName = JobControl.dbo.AutoXFormLayoutName(ID,null) where ID = @NewXFormID

	insert JobControl..TransformationTemplateColumns (TransformTemplateID, OutName, SourceCode, Disabled, GroupByCol, CalcCountCol)
		select @NewXFormID, Value, '[' + Value + ']', 0, 1, 0 
			from Support.FuncLib.Splitstring(@GroupByFields,'|')

	insert JobControl..TransformationTemplateColumns (TransformTemplateID, OutName, SourceCode, Disabled, GroupByCol, CalcCountCol)
		select @NewXFormID, 'RecordsCNT', '[' + @CountField + ']', 0, 0, 1 

	insert JobControl..FileLayouts (TransformationTemplateID, DefaultLayout) values (@NewXFormID, 1)

	select @NewLayoutID = Max(ID) from JobControl..FileLayouts where TransformationTemplateID = @NewXFormID

	update JobControl..FileLayouts set AutoName = JobControl.dbo.AutoXFormLayoutName(null,ID) where ID = @NewLayoutID

	insert JobControl..FileLayoutFields (FileLayoutID, OutOrder, OutName, SrcName)
		select @NewLayoutID, Seq + 1, Value, 'XF_' + Value 
			from Support.FuncLib.Splitstring(@GroupByFields,'|')
		union 
			select @NewLayoutID, 1, 'Record_Count', 'XF_RecordsCNT_Count'

	insert JobControl..JobSteps (JobID, TransformationID, FileLayoutID, StepTypeID, StepOrder, StepName, RunModeID, CreatedStamp, UpdatedStamp, Disabled)
							values (@JobID, @NewXFormID, @NewLayoutID, 1117, @DeliveryStepOrder, '', 1, getdate(), getdate(), 0)

	insert JobControl..JobSteps (JobID, ReportListID, StepTypeID, StepOrder, StepFileNameAlgorithm, StepName, RunModeID, CreatedStamp, UpdatedStamp, CreateZeroRecordReport, SharableReport, Disabled)
							values (@JobID, 4, 22, @DeliveryStepOrder + 1, '<CO>Counts<YYYYMMDD>.xlsx','',1, getdate(), getdate(), 0, 0, 0)

	declare @NewGroupXFormStepID int, @NewReportStepID int

	select @NewGroupXFormStepID = Max(StepID) from JobControl..JobSteps where JobID = @JobID and StepTypeID = 1117
	select @NewReportStepID = Max(StepID) from JobControl..JobSteps where JobID = @JobID and StepTypeID = 22

	update JobControl..JobSteps set DependsOnStepIDs = @JobStepID
		where StepID = @NewGroupXFormStepID

	update JobControl..JobSteps set DependsOnStepIDs = @NewGroupXFormStepID
		where StepID = @NewReportStepID

	update JobControl..JobSteps 
		Set StepOrder = StepOrder + 2 
		where JobID = @JobID and StepID = @DeliveryStepID


END
