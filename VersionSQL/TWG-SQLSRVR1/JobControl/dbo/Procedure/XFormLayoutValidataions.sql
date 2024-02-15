/****** Object:  Procedure [dbo].[XFormLayoutValidataions]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE XFormLayoutValidataions @XFormLayoutID int, @XFromDataTable varchar(500), @JobStepID int
AS
BEGIN
	SET NOCOUNT ON;

		declare @FieldName varchar(100), @FieldSource varchar(100), @SuccessPct int, @CautionPct int, @AbovePct bit, @DataCheck varchar(50), @SpecificValue varchar(50)

		declare @cmdA varchar(max)
		declare @cmdB varchar(max)
		declare @cmdC varchar(max)
		declare @Cond varchar(100)
		declare @eCond varchar(100)
		declare @Targets varchar(200)
		declare @SuccessCond varchar(500)
		declare @LevelCond varchar(500)
		declare @UseXForm bit
		declare @UseTableName varchar(200)
		declare @AuditID int
		declare @StepPass bit = 1

		drop table if exists #AuditResults
		drop table if exists #RawAuditResults

		create table #AuditResults (AuditRecID int null, AuditType varchar(10) null, Results varchar(1000) null, ResultPass bit null, LogLevelID int null, XFormLayoutID int null)
		create table #RawAuditResults (Results varchar(1000) null, ResultPass bit null, LogLevelID int null)


		print 'XForm Vals @XFormLayoutID: ' + ltrim(str(@XFormLayoutID))

     	DECLARE CurFieldAudits CURSOR FOR
			select coalesce(fl.OutName, tc.Outname), null, v.SuccessPct, v.CautionPct, coalesce(v.AbovePct,0), v.DataCheck, v.SpecificValue, v.RecID
				, case when Fl.RecID > 0 then 0 else 1 end UseXFrom
			from JobControl..XFormFieldValidations v
				left outer join JobControl..FileLayoutFields fl on fl.RecID = v.LayoutFieldID and fl.FileLayoutID = v.LayoutID and coalesce(Fl.Disabled,0) = 0
				left outer join JobControl..FileLayouts f on f.Id = v.LayoutID
				left outer join JobControl..TransformationTemplateColumns tc on tc.RecID = v.XFormFieldID and tc.TransformTemplateID = f.TransformationTemplateId
			where coalesce(v.disabled,0) = 0
				and v.LayoutID = @XFormLayoutID

    			OPEN CurFieldAudits

    			FETCH NEXT FROM CurFieldAudits into @FieldName, @FieldSource, @SuccessPct, @CautionPct, @AbovePct, @DataCheck, @SpecificValue, @AuditID, @UseXForm
    			WHILE (@@FETCH_STATUS <> -1)
    			BEGIN

				set @UseTableName = @XFromDataTable

				if @UseXForm=1 
					set @UseTableName = replace(@UseTableName, 'TransformStepResults_', 'TransformStepResultsA_')

				truncate table #RawAuditResults
		
				set @cmdC = JobControl.dbo.ValidationFieldCond(@AuditID,@UseTableName)

				if @cmdC > ''
				Begin
					--print '@@@@@@@@@@@@@@@@@@@@@@@@ After Start @@@@@@@@@@@@@@@@@@@@@@@@@@@@'
					--print @cmdC
					--print '@@@@@@@@@@@@@@@@@@@@@@@@ After End @@@@@@@@@@@@@@@@@@@@@@@@@@@'

					insert #RawAuditResults execute(@cmdC)

					insert #AuditResults (AuditRecID, AuditType, Results, ResultPass, LogLevelID, XFormLayoutID)
						select @AuditID, 'Field', Results, ResultPass, LogLevelID, @XFormLayoutID
							from #RawAuditResults
				End
				
				FETCH NEXT FROM CurFieldAudits into @FieldName, @FieldSource, @SuccessPct, @CautionPct, @AbovePct, @DataCheck, @SpecificValue, @AuditID, @UseXForm
    			END
    			CLOSE CurFieldAudits
    			DEALLOCATE CurFieldAudits

		-- select * from #AuditResults where ResultPass = 0

		print 'Layout Vals @XFormLayoutID: ' + ltrim(str(@XFormLayoutID))

		select a.AuditRecID, a.Results + case when f.Note > '' then ' Note:' + f.Note else '' end Results
					, a.ResultPass
					, 'Audit ' + a.AuditType + ' ' + ltrim(str(a.AuditRecID)) + ': '
								+ case when a.AuditType = 'Custom' then c.CodeDescription 
									when a.AuditType = 'Field' and fl.RecID > 0 then upper(F2.ShortFileLayoutName) + '.' + upper(fl.OutName) + ' LayoutFieldID: ' + ltrim(str(f.LayoutFieldID))
									when a.AuditType = 'Field' and tc.RecID > 0 then upper(tt.ShortTransformationName) + '.' + upper(TC.OutName) + ' XFormFieldID: ' + ltrim(str(f.XFormFieldID))
								else '' end CodeDescrip
					, a.LogLevelID
			from #AuditResults a
				left outer join JobControl..XFormCustValidataions c on c.RecID = a.AuditRecID and a.AuditType = 'Custom' and c.LayoutID = @XFormLayoutID
				left outer join JobControl..XFormFieldValidations f on f.RecID = a.AuditRecID and a.AuditType = 'Field' and f.LayoutID = @XFormLayoutID
				left outer join JobControl..FileLayoutFields fl on fl.RecID = f.LayoutFieldID and fl.FileLayoutID = f.LayoutID
				left outer join JobControl..FileLayouts f2 on f2.Id = F.LayoutID
				left outer join JobControl..TransformationTemplateColumns tc on tc.RecID = f.XFormFieldID and tc.TransformTemplateID = f2.TransformationTemplateId
				left outer join JobControl..TransformationTemplates tt on tt.id = f2.TransformationTemplateId
			where a.XFormLayoutID = @XFormLayoutID

			
END
