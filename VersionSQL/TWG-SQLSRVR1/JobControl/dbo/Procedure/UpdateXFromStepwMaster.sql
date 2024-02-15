/****** Object:  Procedure [dbo].[UpdateXFromStepwMaster]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.UpdateXFromStepwMaster @StepID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @MasterXFormID int = 0
	declare @MasterVersion int = 1
	declare @IsTemplete bit = 0
	declare @NewXFormID int
	declare @NewLayoutID int

	select @MasterXFormID = case when tt.MasterXForm = 1 then tt.ID else 0 end
			, @MasterVersion = coalesce(tt.MasterVersion,1)
			, @IsTemplete = coalesce(j.IsTemplate,0)
		from JobControl..JobSteps js
			join JobControl..Jobs j on js.JobID = j.JobID
			join JobControl..TransformationTemplates tt on js.TransformationID = tt.Id
		where js.StepID = @StepID

	
	if @MasterXFormID > 0 and @IsTemplete = 0
	begin

			drop table if exists #newXFID
				
			create table #newXFID (NewXFID int)

			insert Into #newXFID
			Exec JobControl..CloneXForm @MasterXFormID

			--select @NewXFormID = x.NewXFID
			--		, @NewLayoutID = l.ID
			--	from #newXFID x
			--		join JobControl..FileLayouts l on l.TransformationTemplateId = x.NewXFID
			select @NewXFormID = x.NewXFID
					, @NewLayoutID = coalesce(ld.ID,la.id)
				from #newXFID x
					left outer join JobControl..FileLayouts ld on ld.TransformationTemplateId = x.NewXFID and ld.DefaultLayout = 1
					left outer join JobControl..FileLayouts la on la.TransformationTemplateId = x.NewXFID
				ORDER BY lD.id, lA.id 

			update JobControl..TransformationTemplates
				set MasterXForm = 0
					, SourceMasterXFormID = @MasterXFormID
					, SourceMasterXFormVersion = @MasterVersion
				where ID = @NewXFormID

			update JobControl..TransformationTemplates
				set AutoName = JobControl.dbo.AutoXFormLayoutName(ID,null)
				where ID = @NewXFormID

			update JobControl..JobSteps 
				set TransformationID = @NewXFormID
					, FileLayoutID = @NewLayoutID
				where StepID = @StepID


	end


END
