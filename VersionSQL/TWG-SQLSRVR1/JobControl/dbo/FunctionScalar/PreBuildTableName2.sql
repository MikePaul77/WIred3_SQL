/****** Object:  ScalarFunction [dbo].[PreBuildTableName2]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.PreBuildTableName2
(
	@StepID int, @QueueJobParam varchar(50)
)
RETURNS varchar(500)
AS
BEGIN
	DECLARE @NewFileName varchar(500) = ''

	declare @PreBuildQuery bit

	select @PreBuildQuery = isnull(js.PreBuildQuery,0)
			, @NewFileName = qt.FromPart
		from JobControl..JobSteps js
			join JobControl..QueryTemplates qt on qt.Id = js.QueryTemplateID
		where js.StepID = @StepID;

	if @PreBuildQuery = 1
	begin
		Declare @StateCode varchar(2), @StateID int
		select Top 1 @StateCode=s.Code, @StateID=q.StateID 
			from QueryEditor..QueryLocations q 
				join Lookups..states s on s.ID=q.StateID
			where q.StateID is not null
				and q.QueryID=(Select QueryCriteriaID from JobSteps where StepID=@StepID)

		Set @NewFileName = 'JobControlWork..pb' + rtrim(ltrim(@NewFileName)) + '_' + @StateCode + '_'
				+ case when @QueueJobParam like 'IW:%' then 'IW_' + replace(@QueueJobParam,'IW:','') 
						when @QueueJobParam like 'IM:%' then 'IM_' + replace(@QueueJobParam,'IM:','')
						when @QueueJobParam like 'CM:%' then 'CP_' + replace(@QueueJobParam,'CM:','')
						when @QueueJobParam like 'CQ:%' then 'CP_' + replace(@QueueJobParam,'CQ:','')
						when @QueueJobParam like 'CY:%' then 'CP_' + replace(@QueueJobParam,'CY:','')
						when @QueueJobParam like 'CP:%' then 'CP_' + replace(@QueueJobParam,'CP:','')
					else '' end 

	end

	RETURN @NewFileName

END
