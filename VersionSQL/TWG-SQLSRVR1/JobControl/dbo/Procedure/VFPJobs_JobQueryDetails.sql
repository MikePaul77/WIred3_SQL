/****** Object:  Procedure [dbo].[VFPJobs_JobQueryDetails]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.VFPJobs_JobQueryDetails @JobID int, @Stepid int
AS
BEGIN
	SET NOCOUNT ON;

	print 'JobControl..JobParameters'
	select convert(varchar(50),ParamName) ParamName
		, convert(varchar(50),ParamValue) ParamValue
		 from JobControl..JobParameters where JobID = @JobID

	print 'JobControl..JobSteps'
	select StepID, js.stepName, StepOrder, st.Code
			, QueryCriteriaID, ReportListID, TransformationID, FileLayoutID, QueryTemplateID
			, VFP_QueryID, VFP_BTCRITID, VFP_LayoutID, VFP_ReportID
			, StepFileNameAlgorithm, DependsOnStepIDs
		from JobControl..JobSteps js
			join JobControl..JobStepTypes st on st.StepTypeID = js.StepTypeID
		where JobID = @JobID order by StepOrder

	declare @QueryCriteriaID int
	declare @VFPQueryID varchar(50) 
	declare @VFPBTCRITID varchar(50)
	declare @QueryTemplateID int
	declare @JobStepID int

	declare @VFPQueryWhere varchar(max) 
	declare @VFPBTCRIT varchar(max) 
	declare @SQLQuery varchar(max) 

     DECLARE curA CURSOR FOR
          select QueryCriteriaID, VFP_QueryID, VFP_BTCRITID, QueryTemplateID, StepID
			 from JobControl..JobSteps 
			 where JobID = @JobID and StepTypeID = 21 
				and (@Stepid is null or StepID = @StepID)
			 order by StepOrder

     OPEN curA

     FETCH NEXT FROM curA into @QueryCriteriaID, @VFPQueryID, @VFPBTCRITID, @QueryTemplateID, @JobStepID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

			print '############################  Query Steps  #######################################'
			select @JobID JobID, @JobStepID StepID, @QueryCriteriaID QueryID 
			
			select @VFPQueryWhere = SELECTEXP2 from DataLoad..Jobs_MF_query where QUERY_ID = @VFPQueryID

			select @VFPBTCRIT = CMDLINE from DataLoad..Jobs_MF_btcritss
				where CMDLINE like '%bctv_crit=%' and FUNCTIONID = @VFPBTCRITID

			print 'JobControl..VFPJobs_Map_TemplatesToConds'
			select NewCondPlace, NewCondType, NewCondField, NewCondNot, NewCondValue, Ignore, RecId, cond, 'TemplateCond' Source, @VFPQueryWhere VFPQueryWhere
				from JobControl..VFPJobs_Map_TemplatesToConds
					where @VFPQueryWhere like '%' + cond + '%' and ltrim(rtrim(cond)) > '' and TemplateID = @QueryTemplateID

			print 'JobControl..VFPJobs_Map_BitCritToConds'
			--select NewCondPlace, NewCondType, NewCondField, NewCondNot, NewCondValue, Ignore, RecId, cond, 'BitCritCond' Source, @VFPBTCRIT VFPBTCRIT
			--	from JobControl..VFPJobs_Map_BitCritToConds 
			--		where @VFPBTCRIT like '%' + cond + '%' and ltrim(rtrim(cond)) > '' and TemplateID = @QueryTemplateID
			declare @TemplateID int, @VFP_QueryID varchar(50)
			declare @CmdLine varchar(max), @VFP_BTCRITID varchar(50)
      
				 DECLARE CurB CURSOR FOR

					select distinct q.TemplateID
						, substring(Support.FuncLib.StringFromTo(bc.CMDLINE,'bctv_crit=',null,0),12,4000) CmdLine, x.VFP_BTCRITID, x.VFP_QueryID
						from (	select null TemplateID, JobID, VFP_BTCRITID, QueryCriteriaID, VFP_QueryID 
									from JobControl..JobSteps js
									where VFP_QueryID  > ''
										and js.JobID in (@JobID)
							) x
						join DataLoad..Jobs_MF_btcritss bc on bc.FUNCTIONID = x.VFP_BTCRITID and bc.CMDLINE like '%bctv_crit=%'
						join QueryEditor..Queries q on q.Id = x.QueryCriteriaID

				 OPEN CurB

				 FETCH NEXT FROM CurB into @TemplateID, @CmdLine, @VFP_BTCRITID, @VFP_QueryID
				 WHILE (@@FETCH_STATUS <> -1)
				 BEGIN

						select x.*, c.*
								, @CmdLine CmdLine
							from  Support.FuncLib.SplitString(@CmdLine,' and ') x
								left outer join JobControl..VFPJobs_Map_BitCritToConds c on c.cond = x.value 
																							and c.TemplateID = @TemplateID
																							and c.cond not in ('Prefcode = "P"')

					  FETCH NEXT FROM CurB into @TemplateID, @CmdLine, @VFP_BTCRITID, @VFP_QueryID
				 END
				 CLOSE CurB
				 DEALLOCATE CurB


			select *
				from QueryEditor..Queries where ID = @QueryCriteriaID

			select @SQLQuery = SQLCmd
				from QueryEditor..Queries where ID = @QueryCriteriaID

			print 'QueryID: ' + ltrim(str(@QueryCriteriaID))
			print '------------- SQL Cmd -------------'
			print @SQLQuery
			print '--------------------- -------------'
			
			print 'QueryEditor..QueryLocations'
			select StateID, TownID, CountyID, ZipCode, Exclude from QueryEditor..QueryLocations where QueryID = @QueryCriteriaID
			print 'QueryEditor..QueryRanges'
			select RangeSource, MinValue, MaxValue, Exclude from QueryEditor..QueryRanges where QueryID = @QueryCriteriaID
			print 'QueryEditor..QueryMultIDs'
			select ValueSource, ValueID, Exclude from QueryEditor..QueryMultIDs where QueryID = @QueryCriteriaID

          FETCH NEXT FROM curA into @QueryCriteriaID, @VFPQueryID, @VFPBTCRITID, @QueryTemplateID, @JobStepID
     END
     CLOSE curA
     DEALLOCATE curA

END
