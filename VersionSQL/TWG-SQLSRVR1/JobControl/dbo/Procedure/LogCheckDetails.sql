/****** Object:  Procedure [dbo].[LogCheckDetails]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.LogCheckDetails @Mode varchar(20), @CCRecID int
AS
BEGIN
	SET NOCOUNT ON;

	create table #LogChecks (JobName varchar(200)
								, CondDescription varchar(100)
								, CCRecid int
								, JobID int
								, StepID int
								, LogCheckTable varchar(100)
								, Logic varchar(max)
								, DetailType varchar(50)
								, Disabled bit
								)


	insert #LogChecks (JobName, CondDescription, CCRecid, JobID, StepID, LogCheckTable, DetailType, Disabled, Logic)
		select j.JobName, cc.CondDescription, CC.recid, j.JobID, js.StepID
				, 'JobControlCust.' + case when coalesce(js.LC_CustSchema, '') = '' then 'Job' + ltrim(str(js.JobID)) else coalesce(js.LC_CustSchema, '') end + '.LogCheck_J' + ltrim(str(js.JobID)) + '_S' + ltrim(str(js.StepID)) LogChecktable
				, DetailType
				, coalesce(cc.Disabled,0) Disabled
				, cc.CondLogic
			from JobControl..LogCheckConds cc
				join JobControl..JobSteps js on js.StepID = cc.JobStepID
				join JobControl..Jobs j on j.JobID = js.JobID
			where coalesce(cc.disabled,0) = 0	

	declare @Cmd varchar(max)									

	if @Mode = 'UnFixedCounts' or @Mode = 'AllCounts'
	begin

		create table #RecCounts (CCRecID int, UnFixed int)

		declare @LogCheckTable varchar(100), @CondRecID int

		DECLARE curUFCnts CURSOR FOR
		select LogCheckTable, CCRecID
			from #LogChecks

		OPEN curUFCnts

		FETCH NEXT FROM curUFCnts into @LogCheckTable, @CondRecID
		WHILE (@@FETCH_STATUS <> -1)
		BEGIN
			
			set @Cmd = 'select ' + ltrim(str(@CondRecID)) + ', count(*)
				from ' + @LogCheckTable + '
				where '','' + NeedAttnCondIDs + '','' like ''%,' + ltrim(str(@CondRecID)) + ',%'' '

			if @Mode = 'UnFixedCounts'
				set @Cmd = @Cmd + ' and FixedStamp is null '


			print @cmd
			print '--------------------------------------------------------'

			insert #RecCounts execute(@Cmd)

			FETCH NEXT FROM curUFCnts into @LogCheckTable, @CondRecID
		END
		CLOSE curUFCnts
		DEALLOCATE curUFCnts		

		select * 
			from #RecCounts rc
				join #LogChecks lc on rc.CCRecID = lc.CCRecid
			where case when @Mode = 'UnFixedCounts' and rc.UnFixed > 0 then 1
					when @Mode = 'AllCounts' then 1 else 0 end = 1

	end

	if @Mode = 'UnFixedDetails' or @Mode = 'AllDetails'
	begin
			declare @DetailType varchar(50)

			select @LogCheckTable = LogCheckTable
				, @DetailType = DetailType
			from #LogChecks
				where CCRecID = @CCRecID

			Declare @KeyField varchar(100)
			if @DetailType = 'Mtg'
				set @KeyField = '_Key_MortgageTransactionID'

			if @DetailType = 'Deed'
				set @KeyField = '_Key_SalesTransactionID'

			if @DetailType = 'Assign'
				set @KeyField = '_Key_MortgageAssignmentID'

			if @DetailType = 'Dischg'
				set @KeyField = '_Key_MortgageDischargeID'

			if @DetailType = 'Prop'
				set @KeyField = '_Key_PropertyID'

			create table #DetailID (RecID int
									, ParamName varchar(50)
									, ParamVal varchar(50)
									, KeyID bigint
									, FixedStamp datetime
									, FixedBy varchar(50)
									, ResendParamVal varchar(50))

			set @Cmd = 'select RecID, ParamName, ParamVal, ' + @KeyField + '
						, FixedStamp, FixedBy, ResendParamVal
				from ' + @LogCheckTable + '
				where '','' + NeedAttnCondIDs + '','' like ''%,' + ltrim(str(@CCRecID)) + ',%'' '

			if @Mode = 'UnFixedDetails'
				set @Cmd = @Cmd  + ' and FixedStamp is null '

			print @cmd
			print '--------------------------------------------------------'
			insert #DetailID execute(@Cmd)

			if @DetailType = 'Mtg'
			begin

				select @CCRecID CCRecID, IDs.RecID , IDs.ParamName, IDs.ParamVal
						, IDs.FixedStamp, IDs.FixedBy, IDs.ResendParamVal
					, s.Code State
					, c.FullName County
					, r.RegistryName Registry
					, t.FullName Town
					, tr.FilingDate, tr.Book, tr.Page, tr.DocumentNum, tr.MtgAmount, tr.VFP_TransactionId
					, concat(pa.FullStreetNumber, ' ' , pa.FullStreet, ' ', pa.FullUnit) PropAddress
				from #DetailID ids
					join TWG_PropertyData_Rep..MortgageTransactions tr on ids.Keyid = tr.ID and tr.ModificationType <> 'D'
					join Lookups..Towns t on t.id = tr.TownID
					join Lookups..Registries r on r.id = t.RegistryId
					join Lookups..Counties c on c.id = t.CountyId
					join Lookups..States s on s.id = t.StateID
					left outer join TWG_PropertyData_Rep..PropertyAddresses pa on pa.PropertyId = tr.PropertyId
																				 and pa.ModificationType <> 'D'
																				 and pa.PrefCode = 'P'

			end

			if @DetailType = 'Deed'
			begin

				select @CCRecID CCRecID, IDs.RecID , IDs.ParamName, IDs.ParamVal
						, IDs.FixedStamp, IDs.FixedBy, IDs.ResendParamVal
					, s.Code State
					, c.FullName County
					, r.RegistryName Registry
					, t.FullName Town
					, tr.FilingDate, tr.Book, tr.Page, tr.DocumentNum, tr.SalePrice, tr.VFP_TransactionId
					, concat(pa.FullStreetNumber, ' ' , pa.FullStreet, ' ', pa.FullUnit) PropAddress
				from #DetailID ids
					join TWG_PropertyData_Rep..SalesTransactions tr on ids.Keyid = tr.ID and tr.ModificationType <> 'D'
					join Lookups..Towns t on t.id = tr.TownID
					join Lookups..Registries r on r.id = t.RegistryId
					join Lookups..Counties c on c.id = t.CountyId
					join Lookups..States s on s.id = t.StateID
					left outer join TWG_PropertyData_Rep..PropertyAddresses pa on pa.PropertyId = tr.PropertyId
																				 and pa.ModificationType <> 'D'
																				 and pa.PrefCode = 'P'


			end

			if @DetailType = 'Assign'
			begin
				select @CCRecID CCRecID, IDs.RecID , IDs.ParamName, IDs.ParamVal
						, IDs.FixedStamp, IDs.FixedBy, IDs.ResendParamVal
					, s.Code State
					, c.FullName County
					, r.RegistryName Registry
					, t.FullName Town
					, tr.FilingDate, tr.Book, tr.Page, tr.DocumentNum
					, tr.OriginalFilingDate, tr.OriginalBook, tr.OriginalPage, tr.OriginalDocumentNum
					, tr.VFP_mtgaddid
					, concat(pa.FullStreetNumber, ' ' , pa.FullStreet, ' ', pa.FullUnit) PropAddress
				from #DetailID ids
					join TWG_PropertyData_Rep..MortgageAssignments tr on ids.Keyid = tr.ID and tr.ModificationType <> 'D'
					join Lookups..Towns t on t.id = tr.TownID
					join Lookups..Registries r on r.id = t.RegistryId
					join Lookups..Counties c on c.id = t.CountyId
					join Lookups..States s on s.id = t.StateID
					left outer join TWG_PropertyData_Rep..PropertyAddresses pa on pa.PropertyId = tr.PropertyId
																				 and pa.ModificationType <> 'D'
																				 and pa.PrefCode = 'P'

			end

			if @DetailType = 'Dischg'
			begin
				select @CCRecID CCRecID, IDs.RecID , IDs.ParamName, IDs.ParamVal
						, IDs.FixedStamp, IDs.FixedBy, IDs.ResendParamVal
					, s.Code State
					, c.FullName County
					, r.RegistryName Registry
					, t.FullName Town
					, tr.FilingDate, tr.Book, tr.Page, tr.DocumentNum
					, tr.OriginalFilingDate, tr.OriginalBook, tr.OriginalPage, tr.OriginalDocumentNum
					, tr.VFP_mtgdsid
					, concat(pa.FullStreetNumber, ' ' , pa.FullStreet, ' ', pa.FullUnit) PropAddress
				from #DetailID ids
					join TWG_PropertyData_Rep..MortgageDischarges tr on ids.Keyid = tr.ID and tr.ModificationType <> 'D'
					join Lookups..Towns t on t.id = tr.TownID
					join Lookups..Registries r on r.id = t.RegistryId
					join Lookups..Counties c on c.id = t.CountyId
					join Lookups..States s on s.id = t.StateID
					left outer join TWG_PropertyData_Rep..PropertyAddresses pa on pa.PropertyId = tr.PropertyId
																				 and pa.ModificationType <> 'D'
																				 and pa.PrefCode = 'P'
			
			end

			if @DetailType = 'Prop'
			begin
				select @CCRecID CCRecID, IDs.RecID , IDs.ParamName, IDs.ParamVal
						, IDs.FixedStamp, IDs.FixedBy, IDs.ResendParamVal
					, s.Code State
					, c.FullName County
					, r.RegistryName Registry
					, t.FullName Town
					, tr.VFP_Propid
					, concat(pa.FullStreetNumber, ' ' , pa.FullStreet, ' ', pa.FullUnit) PropAddress
				from #DetailID ids
					join TWG_PropertyData_Rep..Properties tr on ids.Keyid = tr.ID and tr.ModificationType <> 'D'
					left outer join TWG_PropertyData_Rep..PropertyAddresses pa on pa.PropertyId = tr.Id
																				 and pa.ModificationType <> 'D'
																				 and pa.PrefCode = 'P'
					join Lookups..Towns t on t.id = pa.TownID
					join Lookups..Registries r on r.id = t.RegistryId
					join Lookups..Counties c on c.id = t.CountyId
					join Lookups..States s on s.id = t.StateID

			end

	end


end
