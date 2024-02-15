/****** Object:  Procedure [dbo].[JC_AuditStep_DupCheck]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.JC_AuditStep_DupCheck
	@JobStepID int, @GroupRecID int
AS
BEGIN

	SET NOCOUNT ON;

	Declare @JobID int,
			@XForm bit,
			@AuditID int,
			@SQL varchar(max),
			@SourceTable varchar(100),
			@DependsOnStepIDs varchar(100);

	declare @StepPass bit = 1

	declare @ValidationClearedStamp datetime
	declare @ValidationClearedBy varchar(50)
	declare @FailedStamp datetime
	declare @DoDupcheck bit

	Select @JobID=JobID
			, @DependsOnStepIDs = isnull(DependsOnStepIDs,'')
			, @ValidationClearedStamp = ValidationClearedStamp
			, @ValidationClearedBy = coalesce(ValidationClearedBy,'')
			, @FailedStamp = FailedStamp
		from JobControl..JobSteps
		where StepID=@JobStepID

	declare @DependsOnStepTableName varchar(500)
	declare @XFormLayoutID int, @XFormStepID int

	print @DependsOnStepIDs

	select @DependsOnStepTableName = 'JobControlWork..' + dst.StepName + 'StepResults_J' + ltrim(str(djs.JobID)) + '_S' + ltrim(str(djs.StepID))
			, @XFormLayoutID = djs.FileLayoutID
			, @XFormStepID = djs.StepID
			, @DoDupcheck = coalesce(xv.NoDups,0)
		from JobControl..JobSteps djs
			join JobControl..JobStepTypes dst on djs.StepTypeID = dst.StepTypeID
			left outer join JobControl..XFormOtherValidataions xv on xv.LayoutID = djs.FileLayoutID
		where  ',' + @DependsonStepIDs + ',' like '%,' + ltrim(str(djs.StepID)) + ',%'
	
	print @DependsOnStepTableName 

	if @DoDupcheck = 1
	begin

		declare @DupCheckTable varchar(500) = 'JobControlWork..DupCheck_J' +ltrim(str(@JobID))  + '_S' + ltrim(str(@JobStepID))

		set @SQL = 'drop table if exists ' + @DupCheckTable
		--print @SQL
		exec(@SQL)

		set @SQL = 'select * into ' + @DupCheckTable + ' from ' + @DependsOnStepTableName
		--print @SQL
		exec(@SQL)

		set @SQL = 'begin try
			alter table ' + @DupCheckTable + ' drop column _IndexOrderKey
		end try
		begin catch
		end catch'

		--print @SQL
		exec(@SQL)

		set @SQL = 'begin try
			alter table ' + @DupCheckTable + ' drop column _IndexOrderKey
		end try
		begin catch
		end catch'

		--print @SQL
		exec(@SQL)

		--declare @ValPass bit, @ValLevel int, @ValResult varchar(2000), @ValType varchar(50)

	
		set @SQL = ' insert JobControl..ValsOtherCount (GroupRecID, ValPass, ValLevel, ValResult, ValType)
			select ' + ltrim(str(@GroupRecID)) + '
				, case when a.AllRecs - u.UniqueRecs = 0 then 1 else 0 end ValPass
				, case when a.AllRecs - u.UniqueRecs = 0 then 1 else 3 end ValLevel
				, case when a.AllRecs - u.UniqueRecs = 0 then ''No Dup Records Found'' 
					else ltrim(str(a.AllRecs - u.UniqueRecs)) + '' duplicate records found in '' + ltrim(str(a.AllRecs)) + '' total records ('' + convert(varchar,((a.AllRecs - u.UniqueRecs) / convert(money,a.AllRecs)) * 100) + ''%)'' end ValMess
				, ''DupCheck''
			from (select count(*) AllRecs from ' + @DupCheckTable + ') a
				join (select count(*) UniqueRecs from (select distinct * from ' + @DupCheckTable + ') x ) u on 1=1'

		print @SQL
		exec(@SQL)


	end

END
