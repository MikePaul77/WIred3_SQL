/****** Object:  Procedure [dbo].[AppendTotals]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE AppendTotals @JobStepID int, @FieldMode varchar(20)
AS
BEGIN
	SET NOCOUNT ON;

	declare @QueryTemplateID int
	declare @GroupByTotals bit
	declare @GroupBySubTotals bit
	declare @FileLayoutID int
	declare @XformID int

	select @QueryTemplateID = tt.QueryTemplateID
			, @GroupByTotals = coalesce(GroupByTotals,0)
			, @GroupBySubTotals = coalesce(GroupBySubTotals,0)
			, @FileLayoutID = js.FileLayoutID
			, @XformID = tt.ID
		from JobControl..JobSteps js
			join JobCOntrol..TransformationTemplates tt on tt.Id = js.TransformationID
		where js.StepID = @JobStepID

		if @QueryTemplateID = -1  -- GroupBy
			and (@GroupBySubTotals = 1 or @GroupByTotals = 1)
		begin

			declare @IntoClause varchar(max)

			select @IntoClause = IntoClause
			from JobControl.dbo.LayoutSQLParts(@JobStepID, null, null, @FieldMode)

			declare @CountCol varchar(100)
			declare @GroupFields varchar(2000) = ''
			declare @BaseFields varchar(500) = ''
			declare @GroupField varchar(100)
			declare @Sep varchar(10) = ''
			declare @MaxDataIndex int

			drop Table if exists #MaxIndex
			create table #MaxIndex (MaxDataIndex int)

			declare @Cmd varchar(max)
			set @cmd = 'select max(_IndexOrderKey) from '+ replace(@IntoClause,'into ','')

			insert into #Maxindex exec(@cmd)

			select @MaxDataIndex = MaxDataIndex from #MaxIndex

			select @CountCol = lf.outname
				from JobControl..FileLayoutFields lf
					join JobControl..TransformationTemplateColumns ttc on ttc.TransformTemplateID = @XformID 
																	and lf.SrcName = 'XF_' + ttc.OutName + '_Count'
																	and coalesce(ttc.Disabled,0) = 0
																	and ttc.CalcCountCol = 1
				where lf.FileLayoutID = @FileLayoutID
					 and coalesce(lf.Disabled,0) = 0
				order by lf.OutOrder

			DECLARE curGBTot CURSOR FOR
				select lf.outname
					from JobControl..FileLayoutFields lf
						join JobControl..TransformationTemplateColumns ttc on ttc.TransformTemplateID = @XformID 
																		and lf.SrcName = 'XF_' + ttc.OutName
																		and coalesce(ttc.Disabled,0) = 0
																		and ttc.GroupByCol = 1
					where lf.FileLayoutID = @FileLayoutID
							and coalesce(lf.Disabled,0) = 0
					order by lf.OutOrder

			OPEN curGBTot

			FETCH NEXT FROM curGBTot into @GroupField
			WHILE (@@FETCH_STATUS <> -1)
			BEGIN

				set @GroupFields = @GroupFields + @Sep + @GroupField
				set @BaseFields = @BaseFields + @sep + ''''''
				set @Sep = ','

				FETCH NEXT FROM curGBTot into @GroupField
			END
			CLOSE curGBTot
			DEALLOCATE curGBTot

			declare @Field varchar(50)
			declare @Seq int
			declare @Fields varchar(2000)

			if @GroupBySubTotals = 1
			begin

				DECLARE curGBTot CURSOR FOR
						select value, Seq 
							, left(@BaseFields,CHARINDEX('''''',@BaseFields, 3 * (Seq - 1))-1)
								+ value + ' + '' - Total'' ' + value
								+ substring(@BaseFields,CHARINDEX('''''',@BaseFields, 3 * (Seq - 1))+2,2000)
						from Support.FuncLib.SplitString(@GroupFields,',') 

					OPEN curGBTot

					FETCH NEXT FROM curGBTot into @Field, @Seq, @Fields
					WHILE (@@FETCH_STATUS <> -1)
					BEGIN
						set @Cmd = 'insert ' + replace(@IntoClause,'into ','') + ' (' + @GroupFields + ', ' + @CountCol + ', _IndexOrderKey)
									select ' + @Fields + ', sum(convert(int,' + @CountCOl + '))
											, ' + ltrim(str(@MaxDataIndex * (@Seq * 10))) + ' 
										from ' + replace(@IntoClause,'into ','') + '
										where _IndexOrderKey <= ' + ltrim(str(@MaxDataIndex)) + '
									Group by ' + @Field
						print @cmd
						exec(@cmd)

						FETCH NEXT FROM curGBTot into @Field, @Seq, @Fields
					END
					CLOSE curGBTot
					DEALLOCATE curGBTot
			end
			if @GroupByTotals = 1
			begin

					select @Field = value
						, @Seq = Seq 
						, @Fields = left(@BaseFields,CHARINDEX('''''',@BaseFields, 3 * (Seq - 1))-1)
							+ '''Grand - Total''' + value
							+ substring(@BaseFields,CHARINDEX('''''',@BaseFields, 3 * (Seq - 1))+2,2000)
					from Support.FuncLib.SplitString(@GroupFields,',')
					where Seq = 1

					set @Cmd = 'insert ' + replace(@IntoClause,'into ','') + ' (' + @GroupFields + ', ' + @CountCol + ', _IndexOrderKey)
								select ' + @Fields + ', sum(convert(int,' + @CountCOl + '))
										, ' + ltrim(str(@MaxDataIndex * (@Seq * 1000))) + ' 
									from ' + replace(@IntoClause,'into ','') + '
									where _IndexOrderKey <= ' + ltrim(str(@MaxDataIndex)) 
					print @cmd
					exec(@cmd)

			end

		end



END
