/****** Object:  Procedure [dbo].[BuildFileName]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.BuildFileName @JobStartStamp varchar(50), @StartPath varchar(500), @StepID int, @FullRunOption varchar(50), @NormalRunOption varchar(50)
AS
BEGIN
	SET NOCOUNT ON;

		drop table if exists #FullOps 
		create table #FullOps (FullPath varchar(500),Code Varchar(50), ReplacementValue varchar(50), PriOrder int, UsageQueryTemplateID int)

		drop table if exists #StdOps 
		create table #StdOps (FullPath varchar(500),Code Varchar(50), ReplacementValue varchar(50), PriOrder int, UsageQueryTemplateID int)

		insert into #FullOps 
		exec JobControl..BuildFileNameOpts @JobStartStamp, @FullRunOption, @StepID, '', ''

		insert into #StdOps 
		exec JobControl..BuildFileNameOpts @JobStartStamp, @NormalRunOption, @StepID, '', ''


		declare @FinalFullOp varchar(500) = @FullRunOption
		declare @FinalStdOp varchar(500) = @NormalRunOption
		declare @fullPath varchar(500), @Code Varchar(50), @ReplacementValue varchar(50)

		DECLARE curFName CURSOR FOR
		select fullPath, code, ReplacementValue
					from (
					select fullPath, code, ReplacementValue, UsageQueryTemplateID
						, PrioritySeq = ROW_NUMBER() OVER (PARTITION BY code ORDER BY PriOrder)
							from #FullOps 
						where ReplacementValue is not null
					) y
					where PrioritySeq = 1

		OPEN curFName

		FETCH NEXT FROM curFName into @fullPath, @Code, @ReplacementValue
		WHILE (@@FETCH_STATUS <> -1)
		BEGIN
			--if @FinalFullOp = ''
			--	set @FinalFullOp = @fullPath

			set @FinalFullOp = Replace(@FinalFullOp,@Code, @ReplacementValue)

			FETCH NEXT FROM curFName into @fullPath, @Code, @ReplacementValue
		END
		CLOSE curFName
		DEALLOCATE curFName

		DECLARE curFName CURSOR FOR
		select fullPath, code, ReplacementValue
					from (
					select fullPath, code, ReplacementValue, UsageQueryTemplateID
						, PrioritySeq = ROW_NUMBER() OVER (PARTITION BY code ORDER BY PriOrder)
							from #StdOps 
						where ReplacementValue is not null
					) y
					where PrioritySeq = 1
		OPEN curFName

		FETCH NEXT FROM curFName into @fullPath, @Code, @ReplacementValue
		WHILE (@@FETCH_STATUS <> -1)
		BEGIN
			--if @FinalStdOp = ''
			--	set @FinalStdOp = @fullPath

			set @FinalStdOp = Replace(@FinalStdOp,@Code, @ReplacementValue)

			FETCH NEXT FROM curFName into @fullPath, @Code, @ReplacementValue
		END
		CLOSE curFName
		DEALLOCATE curFName


		drop table if exists #FinalOps 
		create table #FinalOps (FullPath varchar(500),Code Varchar(50), ReplacementValue varchar(50), PriOrder int, UsageQueryTemplateID int)

		insert into #FinalOps 
		exec JobControl..BuildFileNameOpts @JobStartStamp, @StartPath, @StepID, @FinalFullOp, @FinalStdOp


		select fullPath, code, ReplacementValue, UsageQueryTemplateID
					from (
					select fullPath, code, ReplacementValue, UsageQueryTemplateID
						, PrioritySeq = ROW_NUMBER() OVER (PARTITION BY code ORDER BY PriOrder)
							from #FinalOps 
						where ReplacementValue is not null
					) y
					where PrioritySeq = 1


END
