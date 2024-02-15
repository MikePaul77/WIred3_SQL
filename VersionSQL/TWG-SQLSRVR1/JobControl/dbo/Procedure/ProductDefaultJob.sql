/****** Object:  Procedure [dbo].[ProductDefaultJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE ProductDefaultJob @JobID int, @XFormID int, @DataView varchar(100), @DataSource varchar(50) 
AS
BEGIN
	SET NOCOUNT ON;

	declare @DataSourceCo varchar(50)

	Set @DataSourceCo = 'TWG'

	if @DataSource = 'National'
		Set @DataSourceCo = 'FA'

	select distinct j.JobID
		from JobControl..Jobs j
			join JobControl..JobSteps js on js.JobID = j.JobID and coalesce(js.Disabled,0) = 0
			left outer join JobControl..TransformationTemplates tt on tt.Id = js.TransformationID
			left outer join JobControl..QueryTemplates qt on qt.ID = Js.QueryTemplateID
		where j.ProductDefault = 1
			and coalesce(j.Disabled,0) = 0
			and coalesce(j.Deleted,0) = 0
			and (j.JobID = @JobID
				 or js.TransformationID = @XFormID
				 or (qt.FromPart = @DataView and qt.SourceCompany = @DataSourceCo))

END
