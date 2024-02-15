/****** Object:  Procedure [dbo].[UpdateBlankLayoutLenByJob]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.UpdateBlankLayoutLenByJob @JobID int, @BlanksOnly bit
AS
BEGIN
	SET NOCOUNT ON;

	if @BlanksOnly is null
		set @BlanksOnly = 1

	declare @TableName varchar(500)
	declare @LayoutID int
	declare @FromPart varchar(500)
	declare @ReportDatabase varchar(500)

	declare @OutName varchar(100)
	declare @RecID int

     DECLARE curJSXF CURSOR FOR
		select  'JobControlWork..TransformStepResults_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID)) XFromTable
				, js.FileLayoutID
				, coalesce(qt.AlternateDB,s.Value) + '..' + qt.FromPart FromPart
				, coalesce(qt.AlternateDB,s.Value) ReportDatabase
			from JobControl..JobSteps js
				join JobControl..TransformationTemplates tt on tt.id = js.TransformationID
				join JobControl..QueryTemplates qt on qt.Id = tt.QueryTemplateID
				join JobControl..Settings s on s.Property = 'ReportDatabase'
			where js.JobID = @JobID and js.FileLayoutID > 0 and coalesce(js.Disabled,0) = 0

     OPEN curJSXF

     FETCH NEXT FROM curJSXF into @TableName, @LayoutID, @FromPart, @ReportDatabase
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN
			
			     DECLARE curLF CURSOR FOR
						select OutName, RecID
							from JobControl..FileLayoutFields
							where FileLayoutID = @LayoutID
								--and OutWidth = 0
				 OPEN curLF

				 FETCH NEXT FROM curLF into @OutName, @RecID
				 WHILE (@@FETCH_STATUS <> -1)
				 BEGIN

					declare @Cmd varchar(max)

					--set @Cmd = ' update FLF set outwidth = case when z.max_length > x.MaxLen then z.max_length
					--											when x.MaxLen > z.max_length then x.MaxLen
					--											else OutWidth end
					--				from JobControl..FileLayoutFields FLF
					--					join (select coalesce(Max(Len(ltrim(rtrim(' + @OutName + ')))),0) MaxLen
					--							from ' + @TableName + ' ) x on 1=1
					--					join (select b.max_length
					--						from ' + @ReportDatabase + '.sys.all_objects a, ' + @ReportDatabase + '.sys.all_columns b
					--							where a.object_id=b.object_id
					--								and b.name = ''' + @OutName + '''
					--								and ''' + @FromPart + ''' like ''%'' + a.name ) z on 1=1
					--				where FLF.RecID = ' + ltrim(str(@RecID)) + ' '

					if @BlanksOnly = 0

						set @Cmd = ' update FLF set outwidth = case when z.max_length > outwidth then z.max_length
																	else OutWidth end
										from JobControl..FileLayoutFields FLF
											join (select b.max_length
												from ' + @ReportDatabase + '.sys.all_objects a, ' + @ReportDatabase + '.sys.all_columns b
													where a.object_id=b.object_id
														and b.name = ''' + @OutName + '''
														and ''' + @FromPart + ''' like ''%'' + a.name ) z on 1=1
										where FLF.RecID = ' + ltrim(str(@RecID)) + ' '

					else

						set @Cmd = ' update FLF set outwidth = case when outwidth = 0 then z.max_length
																	else OutWidth end
										from JobControl..FileLayoutFields FLF
											join (select b.max_length
												from ' + @ReportDatabase + '.sys.all_objects a, ' + @ReportDatabase + '.sys.all_columns b
													where a.object_id=b.object_id
														and b.name = ''' + @OutName + '''
														and ''' + @FromPart + ''' like ''%'' + a.name ) z on 1=1
										where FLF.RecID = ' + ltrim(str(@RecID)) + ' '


					print '----------------------------------'
					print @cmd
					exec(@cmd)


					  FETCH NEXT FROM curLF into @OutName, @RecID
				 END
				 CLOSE curLF
				 DEALLOCATE curLF


          FETCH NEXT FROM curJSXF into @TableName, @LayoutID, @FromPart, @ReportDatabase
     END
     CLOSE curJSXF
     DEALLOCATE curJSXF

END
