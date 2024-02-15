/****** Object:  ScalarFunction [dbo].[StepValid]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION StepValid (@ID int, @StepSource varchar(20))
RETURNS varchar(2000)
AS
BEGIN
	DECLARE @result varchar(200)
	set @result = ''

	declare @StepTypeID int = -1
	declare @QueryCriteriaID int
	declare @ReportListID int
	declare @FileLayoutID int
	declare @TransformationID int
	declare @DependsOnStepIDs varchar(200)

	if @StepSource = 'Job'
		select @StepTypeID = StepTypeID 
				, @QueryCriteriaID = QueryCriteriaID
				, @ReportListID = ReportListID
				, @FileLayoutID = FileLayoutID
				, @TransformationID = TransformationID
				, @DependsOnStepIDs = DependsOnStepIDs
			from JobControl..JobSteps 
			where StepID = @ID

	if @StepSource = 'JobTemplate'
		select @StepTypeID = StepTypeID 
				, @QueryCriteriaID = QueryCriteriaID
				, @ReportListID = ReportListID
				, @FileLayoutID = FileLayoutID
				, @TransformationID = TransformationID
				, @DependsOnStepIDs = DependsOnStepIDs
			from JobControl..JobTemplateSteps 
			where @ID = @ID

	if @StepTypeID  in (1, 29, 22)	--Append,Transform,Report
	begin
		if ltrim(rtrim(coalesce(@DependsOnStepIDs,''))) = ''
			set @result = @result + 'Depends on step is required and is not set' + char(10)
	end

		--Append
	if @StepTypeID = 1 and ltrim(rtrim(coalesce(@DependsOnStepIDs,''))) > ''
	begin
		declare @AppSteps int
		declare @StepTypes int
		declare @MaxStepTypeID int
		declare @FileLayouts int
		declare @XForms int
		declare @QueryTemplates int

		if @StepSource = 'Job'
			select @AppSteps = count(*)
					, @StepTypes = count(distinct StepTypeID)
					, @MaxStepTypeID = Max(StepTypeID)
					, @FileLayouts = count(distinct FileLayoutID)
					, @XForms = count(distinct TransformationID)
					, @QueryTemplates = count(distinct QueryTemplateId)
				from Support.FuncLib.SplitString(@DependsOnStepIDs,',') s
					join JobControl..JobSteps js on js.StepID = s.value

		if @StepSource = 'JobTemplate'
			select @AppSteps = count(*)
					, @StepTypes = count(distinct StepTypeID)
					, @MaxStepTypeID = Max(StepTypeID)
					, @FileLayouts = count(distinct FileLayoutID)
					, @XForms = count(distinct TransformationID)
					, @QueryTemplates = count(distinct QueryTemplateId)
				from Support.FuncLib.SplitString(@DependsOnStepIDs,',') s
					join JobControl..JobTemplateSteps jts on jts.ID = s.value
	
		if @AppSteps < 2
			set @result = @result + '2 or more steps must be selected' + char(10)
		else
			begin
				if @StepTypes > 1
					set @result = @result + 'Steps of differnet types can not be appended' + char(10)
				else
					begin
						if @MaxStepTypeID = 21
							if @QueryTemplates > 1
								set @result = @result + 'Queries of differnet types can not be appended' + char(10)
						if @MaxStepTypeID = 29
							if @XForms > 1
								set @result = @result + 'Transforms of differnet types can not be appended' + char(10)
					end
			end	
	end

	if @StepTypeID = 21	--Query
	begin
		if coalesce(@QueryCriteriaID,-1) = -1
			set @result = @result + 'No Query is set' + char(10)
	end

	if @StepTypeID = 29	--Transform
	begin
		if coalesce(@TransformationID,-1) = -1
			set @result = @result + 'No Transform is set' + char(10)
	end

	if @StepTypeID = 22	--Report
	begin
		if coalesce(@ReportListID,-1) = -1
			set @result = @result + 'No report is set' + char(10)
	end

	RETURN @result
END
