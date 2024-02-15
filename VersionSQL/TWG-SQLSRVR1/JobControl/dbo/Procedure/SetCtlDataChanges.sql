/****** Object:  Procedure [dbo].[SetCtlDataChanges]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.SetCtlDataChanges @CtlDataXFromID int,@CtlDataLayoutID int, @ReportXFormIDs varchar(500), @cols varchar(max) 
AS
BEGIN
	SET NOCOUNT ON;


		update ttc
			set GroupCountCol = 0
			from JobControl..TransformationTemplateColumns ttc
				join string_split(@ReportXFormIDs,',') x on x.value = ttc.TransformTemplateID
		    where GroupCountCol = 1

      --  update JobControl..TransformationTemplateColumns 
		    --set Disabled = 1
		    --where TransformTemplateID = @CtlDataXFromID

        update JobControl..FileLayoutFields
		    set Disabled = 1
		    where FileLayoutID = @CtlDataLayoutID
				and SrcName in ('__ReportName','__RecCount')


	
		insert JobControl..TransformationTemplateColumns (TransformTemplateID, OutName, SourceCode, Disabled, GroupCountCol)
			select x.value, c.value, 'x.' + c.value, 0, 1
				from string_split(@ReportXFormIDs,',') x
					join string_split(@cols,',') c on 1=1
					left outer join JobControl..TransformationTemplateColumns ttc on x.value = ttc.TransformTemplateID
																					and c.value = ttc.OutName
																					--and 'x.' + c.value = ttc.SourceCode
				where ttc.RecID is null
		
		update ttc 
			set  GroupCountCol = 1
				--, Disabled = 0
			from string_split(@ReportXFormIDs,',') x
					join string_split(@cols,',') c on 1=1
					join JobControl..TransformationTemplateColumns ttc on x.value = ttc.TransformTemplateID
																					and c.value = ttc.OutName
																					--and 'x.' + c.value = ttc.SourceCode


		--insert JobControl..TransformationTemplateColumns (TransformTemplateID, OutName, SourceCode, Disabled)
		--	select @CtlDataXFromID, 'XF_' + c.value, 'x.XF_' + c.value, 0
		--		from string_split(@cols,',') c
		--			left outer join JobControl..TransformationTemplateColumns ttc on ttc.TransformTemplateID = @CtlDataXFromID
		--																			and 'XF_' + c.value = ttc.OutName
		--																			and 'x.XF_' + c.value = ttc.SourceCode
		--		where ttc.RecID is null
		
		--update ttc 
		--	set Disabled = 0
		--	from string_split(@cols,',') c
		--			join JobControl..TransformationTemplateColumns ttc on ttc.TransformTemplateID = @CtlDataXFromID
		--																			and 'XF_' + c.value = ttc.OutName
		--																			and 'x.XF_' + c.value = ttc.SourceCode


	
		insert JobControl..FileLayoutFields (FileLayoutID, OutName, SrcName, Disabled, OutOrder)
			select @CtlDataLayoutID, c.value, 'XF_' + c.value, 0, 9999 
				from string_split(@cols,',') c
					left outer join JobControl..FileLayoutFields flf on flf.FileLayoutID = @CtlDataLayoutID
																	and c.value = flf.OutName
																	and 'XF_' + c.value = flf.SrcName
				where flf.RecID is null
		
		update flf 
			set Disabled = 0
			from string_split(@cols,',') c
					join JobControl..FileLayoutFields flf on flf.FileLayoutID = @CtlDataLayoutID
															and c.value = flf.OutName
															and 'XF_' + c.value = flf.SrcName

		
		declare @StartOutOrder int
		select @StartOutOrder = coalesce(max(OutOrder),0) + 1 from JobControl..FileLayoutFields 
			where FileLayoutID = @CtlDataLayoutID
				and OutOrder not in (0,9999)

		declare @RecID int, @OutOrder int
			   
		 DECLARE CTLOrderFixcurA CURSOR FOR
			  select RecID, OutOrder from JobControl..FileLayoutFields where FileLayoutID = @CtlDataLayoutID order by OutOrder, RecID

		 OPEN CTLOrderFixcurA

		 FETCH NEXT FROM CTLOrderFixcurA into @RecID, @OutOrder
		 WHILE (@@FETCH_STATUS <> -1)
		 BEGIN
			if @OutOrder = 0 or @OutOrder = 9999
			begin
				update JobControl..FileLayoutFields set OutOrder = @StartOutOrder where RecID = @RecID
				set @StartOutOrder = @StartOutOrder  + 1

			end

			  FETCH NEXT FROM CTLOrderFixcurA into @RecID, @OutOrder
		 END
		 CLOSE CTLOrderFixcurA
		 DEALLOCATE CTLOrderFixcurA
		

END
