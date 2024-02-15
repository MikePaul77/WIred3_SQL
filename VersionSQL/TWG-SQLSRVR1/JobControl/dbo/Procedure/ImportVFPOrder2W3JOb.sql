/****** Object:  Procedure [dbo].[ImportVFPOrder2W3JOb]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.ImportVFPOrder2W3JOb @W3JobID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @VFPJobID int

	select @VFPJobID = VFPJobID 
		from JobControl..Jobs
		where JobID = @W3JobID

	declare @VFPOrderID int

	select @VFPOrderID = co.OrderID
		from DataLoad..Jobs_custorders co
			left outer join DataLoad..Jobs_orderjobs oj on oj.orderid = co.ORDERID
		where oj.jobid = @VFPJobID

	create table #noj (OrderID int null, JobID int null, PrevOrderID int null, CustID int null, VFPJobID int null)

	insert #noj (OrderID, JobID, PrevOrderID, CustID, VFPJobID)
	select co.OrderID, coalesce(nj.JobID,-1), co.ORDERIDOLD, co.CUSTID, oj.jobid
		from DataLoad..Jobs_custorders co
			left outer join DataLoad..Jobs_orderjobs oj on oj.orderid = co.ORDERID
			left outer join JobControl..Jobs nj on nj.VFPJobID = oj.jobid
	where co.OrderID = @VFPOrderID
		order by co.ORDERID desc

	declare @JobID int, @PrevOrderID int

     DECLARE curInVFP CURSOR FOR
          select OrderID
			from #noj
			where JobID is not null

     OPEN curInVFP

     FETCH NEXT FROM curInVFP into @PrevOrderID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

		select @PrevOrderID = ORDERIDOLD from DataLoad..Jobs_custorders where OrderID = @PrevOrderID
		
		Print @PrevOrderID

		while coalesce(@PrevOrderID,0) > 0
		begin

			insert #noj (OrderID, JobID, PrevOrderID, CustID, VFPJobID)
			select distinct co.OrderID
					, coalesce(nj.JobID,-1)
					, co.ORDERIDOLD, co.CUSTID
					, oj.jobid
				from DataLoad..Jobs_custorders co
					left outer join DataLoad..Jobs_orderjobs oj on oj.orderid = co.ORDERID
					left outer join JobControl..Jobs nj on nj.VFPJobID = oj.jobid
					--join #noj noj on noj.OrderID = co.ORDERID
					left outer join #noj pnoj on pnoj.OrderID = co.OrderID
				where co.OrderID = @PrevOrderID
					and pnoj.OrderID is null
			
			select @PrevOrderID = ORDERIDOLD from DataLoad..Jobs_custorders where OrderID = @PrevOrderID
		end

		FETCH NEXT FROM curInVFP into @PrevOrderID
     END
     CLOSE curInVFP
     DEALLOCATE curInVFP

	delete oj
		from OrderControl..OrderJobs oj
			join OrderControl..Orders o on oj.OrderID = o.OrderID
		where o.VFPIn = 1 and o.VFPOrderID in (select OrderID from #noj)

	delete oi
		from OrderControl..OrderInvoices oi
			join OrderControl..Orders o on oi.OrderID = o.OrderID
		where o.VFPIn = 1 and o.VFPOrderID in (select OrderID from #noj)

	delete OrderControl..Orders where VFPIn = 1 and VFPOrderID in (select OrderID from #noj)


	insert OrderControl..Orders (Description
							, OrderCustID
							, BillingCustID
							, ProductID
							, SalesRepID
						--, OrderStatusID
						--, JobID
							, IsSuspended
							, CreatedStamp, UpdatedStamp
							, BillingFrequencyID, Cost, TaxAmt
							, OrderDate, StartDate, EndDate
							, VFPIn, VFPOrderID
							, PaymentTypeID, PaymentTermsID
							, PONum) 
	select distinct co.ORDERDESC
		, cp.CustID PrimaryCustID
		, cb.CustID BillingCustID
		, coalesce(p.ProductID,p2.ProductID)
		, sr.SalesRepID
--		, os.ID
		--, j.JobID
		, case when os.ID in (13,14,15,16) then 1 else 0 end
		, co.ORDERDATE, co.MODIDATE
		, case when co.billcycle = 'MP' then 3	--	Monthly Per Record
				when co.billcycle = 'QF' then 5	--		Quarterly Fee
				when co.billcycle = 'QP' then 5	--		Quarterly Per Record
				when co.billcycle = '1F' then 7	--		1 Time-Fixed Fee
				when co.billcycle = '1X' then 7	--		1 Time-Per Record
				when co.billcycle = '' then null	--	???	
				when co.billcycle = 'RY' then null	--		Royalty
				when co.billcycle = 'AS' then 6	--	Subscription-Prepaid
				when co.billcycle = 'NB' then null	--	No Billing Required
				when co.billcycle = 'CP' then null	--	Complimentary
				when co.billcycle = 'IH' then null	--	Inhouse Usage
				when co.billcycle = 'MF' then 3	--	Monthly Fee
				when co.billcycle = 'MA' then 6	--	Monthly PrePaid
				else null end BillingFrequencyID
		, case when co.TOTALAMT > 1 then co.TOTALAMT else 0 end
		, case when TOTALAMT > 0 then TOTALAMT - GROSSAMT else 0 end
		, co.ORDERDATE
		, case when isdate(left(co.FISSMONTH,2) + '/1/' + right(co.FISSMONTH,4)) = 1
				then convert(date,left(co.FISSMONTH,2) + '/1/' + right(co.FISSMONTH,4))
			else null end StartExp
		, case when isdate(left(co.ORDEREXP,2) + '/1/' + right(co.ORDEREXP,4)) = 1
				then Support.FuncLib.GetLastDateOfMonth(convert(date,left(co.ORDEREXP,2) + '/1/' + right(co.ORDEREXP,4)))
			else null end EndExp
		, 1, co.ORDERID
		, bt.BillingTypeID, bi.ID
		, co.PONUM
	from (select distinct * from #noj) x
		join DataLoad..Jobs_custorders co on co.ORDERID = x.OrderID
		left outer join OrderCOntrol..SalesReps sr on sr.VFPUserID = coalesce(co.LSREPID,108)
		left outer join JobControl..Jobs j on j.JobID = x.JobID
		left outer join DataLoad..Jobs_jobs vj on vj.JobID = j.VFPJobID
		left outer join OrderControl..Products p on p.JobTemplateID_ForImport = j.JobTemplateID
		left outer join OrderControl..OrderStatus os on co.ORDACTST = os.Code
		left outer join (select distinct Min(ProductID) ProductID, min(FrequencyID) FrequencyID, QBItem 
							from OrderControl..Products
							group by QBItem) p2 on p2.QBItem = coalesce(vj.ACCTPARTN, co.SKU)
		left outer join OrderControl..Customers cp on cp.VFP_CustID = x.CUSTID
		left outer join OrderControl..Customers cb on cb.BillingCustID = cp.VFP_CustID
		left outer join OrderControl..BillingInfo bi on bi.code = co.BILLCYCLE
		left outer join OrderControl..BillingTypes bt on bt.code = co.PAYMENTMET

	update o set PrevOrderID = po.OrderID
		from OrderControl..Orders o
			join (select distinct * from #noj) x on x.OrderID = o.VFPOrderID
			left outer join DataLoad..Jobs_custorders pco on pco.OrderID = x.PrevOrderID
			left outer Join OrderControl..Orders po on po.VFPOrderID = pco.ORDERID

--select distinct * from #noj

	insert OrderControl..OrderJobs (OrderID, JobID, VFPJobID, VFPIn)
	select distinct o.OrderID, j.JobID, j.VFPJobID, 1
		from (select distinct * from #noj) x
			join OrderControl..Orders o on o.VFPOrderID = x.ORDERID
			join JobControl..Jobs j on j.VFPJobID = x.VFPJobID
			join DataLoad..Jobs_custorders co on co.ORDERID = x.OrderID
			--left outer join DataLoad..Jobs_jobs vj on vj.JobID = x.JobID
			left outer join OrderControl..Products p on p.JobTemplateID_ForImport = j.JobTemplateID

	--update oj set JobID = poj.JobID, VFPJobID = poj.VFPJobID
	--	from OrderControl..OrderJobs oj
	--		join OrderControl..Orders o on o.OrderID = oj.OrderID
	--		join OrderControl..OrderJobs poj on poj.OrderID = o.PrevOrderID and poj.JobID > 0
	--	where oj.VFPJobID is null and oj.VFPIn = 1

	update o set PrimaryStateID4Class = x.StateID, NumStateIDs2Class = x.States
		from OrderControl..Orders o
			join OrderControl..OrderJobs oj on oj.OrderID = o.OrderID
			left outer join (
				select j.JobID, min(coalesce(s.Id,sma.id)) StateID, count(s.Id) States
					from JobControl..Jobs j
						left outer join Lookups..States s on s.id > 0 and ',' + j.JobStateReference + ',' like '%,' + s.Code + ',%'
						left outer join Lookups..States sma on sma.Code = 'MA'
					group by j.JobID
				) x on x.JobID = oj.JobID

	insert OrderControl..OrderInvoices (OrderID, InvDate, DueDate, Notes, VFPIn)
	select distinct o.OrderID, co.ORDERDATE, dateadd(dd,10,co.ORDERDATE), co.INVNOTES, 1
		from (select distinct * from #noj) x
			join DataLoad..Jobs_custorders co on co.ORDERID = x.OrderID
			join OrderControl..Orders o on o.VFPOrderID = co.ORDERID

	drop table #noj


END
