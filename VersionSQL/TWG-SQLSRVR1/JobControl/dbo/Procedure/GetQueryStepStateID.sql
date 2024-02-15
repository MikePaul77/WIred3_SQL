/****** Object:  Procedure [dbo].[GetQueryStepStateID]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetQueryStepStateID @StepID int, @StateID int output
AS
BEGIN
	SET NOCOUNT ON;

	declare @DependsOnStepIDs varchar(100), @JobID int, @QueryID int, @QueryStateID int
	declare @cmd nvarchar(max)

	select @DependsOnStepIDs = js.DependsOnStepIDs
			, @JobID = js.JobID
			, @QueryID = js.QueryCriteriaID
		from JobControl..JobSteps js 
			join QueryEditor..Queries q on js.QueryCriteriaID = q.ID
			join JobControl..Jobs j on j.JobID=js.JobID
		where js.StepID = @StepID

	Declare @SCT varchar(10)

	Select @SCT = CASE WHEN BeginLoopType=1 THEN 'State'
							WHEN BeginLoopType=2 THEN 'County'
							ELSE 'Town' END
		from JobControl..JobSteps 
		where StepID like @DependsOnStepIDs
			and StepTypeID=1107;

	Declare @LoopTable varchar(100), @SCTval int;
	set @LoopTable = 'JobControlWork..BeginLoopStepResults_J' + ltrim(str(@JobID)) + '_S' + @DependsOnStepIDs;

	if @SCT = 'State'
		set @cmd = ' select @SCTval = StateID 
						from ' + @LoopTable + '
						where ProcessFlag = 1 '
	if @SCT = 'County'
		set @cmd = ' select @SCTval = c.StateID
						from ' + @LoopTable + ' x
							join Lookups..Counties c on c.id = x.countyID
						where ProcessFlag = 1 '
	if @SCT = 'Town'
		set @cmd = ' select @SCTval = t.StateID
						from ' + @LoopTable + ' x
							join Lookups..Towns t on t.id = x.townID
						where ProcessFlag = 1 '

	if OBJECT_ID(@LoopTable, 'U') is not null
		Execute sp_executesql @cmd, N'@SCTval int OUTPUT', @SCTval = @SCTval output;

	select @QueryStateID = min(coalesce(ql.StateID, c.StateID, t.StateID))
		from QueryEditor..QueryLocations ql
			left outer join Lookups..Counties c on c.id = ql.countyID
			left outer join Lookups..towns t on t.id = ql.townID
		where ql.QueryID = @QueryID and coalesce(ql.Exclude,0) = 0

	select @StateID = coalesce(@SCTVal, @QueryStateID, 25) -- MA is the fall back default


END
