/****** Object:  Procedure [dbo].[SetDefaultTemplate]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE SetDefaultTemplate @JobID int 
AS 
BEGIN

	SET NOCOUNT ON;

	print 'JobID: ' + ltrim(str(@JobID))	

	declare @JobName varchar(200) 
	declare @XFormID int
	declare @LayoutID int

	select @JobName = j.JobName
			, @XFormID = js.TransformationID
			, @LayoutID = js.FileLayoutID
		from JobControl..Jobs j 
			join JobControl..JobSteps js on js.JobID = j.JobID and js.TransformationID > 0
		where j.IsTemplate = 1 and j.ProductDefault = 1 and coalesce(j.disabled,0) = 0 and coalesce(j.deleted,0) = 0
			and j.JobID = @JobID

	print 'JobName: ' + @JobName
	print 'Old XFormID: ' + ltrim(str(@XFormID))	
	print 'Old LayoutID: ' + ltrim(str(@LayoutID))	

	drop table if exists #newXFID
				
	create table #newXFID (NewXFID int)

	insert Into #newXFID
	Exec JobControl..CloneXForm @XFormID

	declare @NewXFID int

	select @NewXFID = NewXFID from #newXFID

	print 'New XFormID: ' + ltrim(str(@NewXFID))	

	update js set TransformationID = @NewXFID
			, FileLayoutID = fl.Id
		from JobControl..JobSteps js
			join JobControl..FileLayouts fl on fl.TransformationTemplateId = @NewXFID and fl.DefaultLayout = 1 
		where js.JobID = @JobID and js.TransformationID = @XFormID

	declare @NewLayoutID int
	select @NewLayoutID = FileLayoutID
		from JobControl..JobSteps js
		where Js.JobID = @JobID and TransformationID = @NewXFID

	print 'New LayoutID: ' + ltrim(str(@NewLayoutID))	

	update JobControl..TransformationTemplates 
		set MasterXForm = 1
			, Description = @JobName
		where Id = @NewXFID


END
