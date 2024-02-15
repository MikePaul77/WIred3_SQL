/****** Object:  ScalarFunction [dbo].[JobStepRunStates]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.JobStepRunStates 
(
	@JobStepId int
)
RETURNS varchar(200)
AS
BEGIN
	DECLARE @RetVal varchar(200);

	Select @RetVal=string_agg(y.code, ',') from
		 (select distinct coalesce(zs.ID, t.StateID, c.StateID, ql.stateID) as JobStateID
                    from QueryEditor..QueryLocations ql
                        join JobSteps js on js.QueryCriteriaID = ql.QueryID and coalesce(js.Disabled,0) = 0 and ltrim(js.DependsOnStepIDs) = ''
                        left outer join Lookups..Counties c on ql.CountyID = c.ID
                        left outer join Lookups..Towns t on ql.TownID = t.ID
                        left outer join Support..Zip_5 z on ql.ZipCode = z.zipcode
                        left outer join Lookups..States zs on zs.Code = z.state
                    where coalesce(zs.ID, t.StateID, c.StateID, ql.stateID) > 0
                        and js.StepID = @JobStepID) x
						join Lookups..States y on x.JobStateID = y.ID ;

	RETURN isnull(@RetVal,'');

END
