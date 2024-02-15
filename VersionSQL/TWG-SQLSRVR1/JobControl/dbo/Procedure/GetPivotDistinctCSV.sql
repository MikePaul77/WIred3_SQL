/****** Object:  Procedure [dbo].[GetPivotDistinctCSV]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetPivotDistinctCSV  @JobStepID int, @builtcsv varchar(max) output
AS
BEGIN
	SET NOCOUNT ON;

	declare @SrcTable varchar(500), @SrcField varchar(100), @XFormID int
	
	Declare @WorkDB varchar(50) = 'JobControlWork'

	set @builtcsv = ''

	select @SrcTable = @WorkDB + '..' + Djst.StepName + 'StepResults_J' + ltrim(str(Djs.JobID)) + '_S' + ltrim(str(Djs.StepID))
			, @XFormID = coalesce(js.TransformationID, 0)
		from JobSteps js 
			left outer join JobStepTypes jst on jst.StepTypeID =js.StepTypeID
			left outer join JobSteps Djs on js.JobID = Djs.JobID and ',' + js.DependsOnStepIDs + ',' like '%,' + ltrim(str(Djs.StepID)) + ',%'
			left outer join JobStepTypes Djst on Djst.StepTypeID = Djs.StepTypeID
		where js.StepID = @JobStepID

	SELECT @SrcField =  SourceCode
		FROM JobControl..TransformationTemplateColumns
		where TransformTemplateID = @XFormID 
			and coalesce(disabled,0) = 0
			and coalesce(PivotValCol,0) = 1

	if @SrcField > ''
	begin

		create table #vals (val varchar(500) null)

		declare @cmd varchar(max)

		set @cmd = 'select distinct ' + @SrcField + ' from ' + @SrcTable + ' x order by 1 '
		print @cmd

		insert into #vals execute (@cmd)

		select @builtcsv = COALESCE(@builtcsv + ',' ,'') + '[' + val + ']'
			from #vals
	
		if left(@builtcsv,1) = ','
			set @builtcsv = SUBSTRING(@builtcsv,2,4000)

	end

END
