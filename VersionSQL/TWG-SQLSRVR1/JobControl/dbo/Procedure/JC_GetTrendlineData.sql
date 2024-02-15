/****** Object:  Procedure [dbo].[JC_GetTrendlineData]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: May 1, 2019
-- Description:	Creates table for Trendline Reporting
-- =============================================
CREATE PROCEDURE dbo.JC_GetTrendlineData 
	@JobStepID int,
	@CountyID int,
	@ReportMonth int,
	@CurrentYear int
AS
BEGIN
	SET NOCOUNT ON;

	Declare @UseMonth varchar(2) = RIGHT('0' + Convert(varchar(2),@ReportMonth),2);
	Declare @CountyName varchar(100);
	Select @CountyName = ltrim(rtrim(fullname))+' County' from lookups..counties where ID=@CountyID;
	Declare @JobID int;
	Select @JobID=JobID from JobSteps where StepID=@JobStepID;
	Declare @TargetFile varchar(100) = 'JobControlWork.dbo.StatsStepResults_J' + convert(varchar, @JobID) + '_S' + Convert(varchar, @JobStepID)
	declare @LogSourceName varchar(100) = 'SP ' + Support.dbo.SPDBName(@@PROCID);

	IF OBJECT_ID('tempdb.dbo.#TrendlineTemp', 'U') IS NOT NULL
	  DROP TABLE #TrendlineTemp; 

	Create table #TrendlineTemp(TownID int, TownCounty varchar(100), tc int, sortval int, usegrp varchar(10), numsales1 varchar(10), 
		numsales2 varchar(10), delta1 varchar(20), ytdnumsales1 varchar(10), ytdnumsales2 varchar(10), 
		delta2 varchar(20), medsales1 varchar(20), medsales2 varchar(20), delta3 varchar(20),
		ytdmedsales1 varchar(20), ytdmedsales2 varchar(20), delta4 varchar(20), TownCode varchar(4));

	Insert into #TrendlineTemp(TownID, TownCounty, tc, usegrp, numsales2, ytdnumsales2, medsales2, ytdmedsales2, TownCode)
	Select isnull(ps.TownID,0) as TownID, t.fullname as TownCounty, iif(ps.TownID is null,1,0) as tc, ps.usegrp as usegrp, 
			ps.numsales as numsales1, ps.ytdnumsale as ytdnumsaled1, ps.medsale as medsales1, ps.ytdmedsale as ytdmedsales1,
			t.code as TownCode
		from TWG_PropertyData..PropStats2 ps
			left join lookups..towns t on ps.TownID = t.ID
		where ps.CountyID=@CountyID and ps.year=@CurrentYear and ps.period=@UseMonth

	Update #TrendlineTemp set TownCounty=@CountyName where tc=1

	Update T
		Set T.numsales1 = x.numsales1,
			T.ytdnumsales1 = x.ytdnumsales1,
			T.medsales1 = x.medsales1,
			T.ytdmedsales1 = x.ytdmedsales1
		From #TrendlineTemp T
			join 
				(Select isnull(ps.TownID,0) as TownID2, t.fullname as fullname2, ps.Usegrp as usegrp2, 
						ps.numsales as numsales1, ps.ytdnumsale as ytdnumsales1, ps.medsale as medsales1, ps.ytdmedsale as ytdmedsales1
					from TWG_PropertyData..PropStats2 ps
						left join lookups..towns t on ps.TownID = t.ID
					where ps.CountyID=@CountyID and ps.year=@CurrentYear-1 and ps.period=@UseMonth) x 
			on (x.usegrp2 = t.usegrp) and (T.TownID = x.TownID2)

	
	Update #TrendlineTemp
		Set medsales1=iif(medsales1='0','',medsales1),
			medsales2=iif(medsales2='0','',medsales2),
			ytdmedsales1=iif(ytdmedsales1='0','',ytdmedsales1),
			ytdmedsales2=iif(ytdmedsales2='0','',ytdmedsales2),
			sortval = 0 + CASE 
					when usegrp='1FA' then 1
					when usegrp='2FA' then 2
					when usegrp='3FA' then 3
					when usegrp='CND' then 4
					when usegrp='ALL' then 5
				  END

	Update #TrendlineTemp
		Set Delta1 = dbo.GetPercentChange(numsales1,numsales2),
			Delta2 = dbo.GetPercentChange(ytdnumsales1,ytdnumsales2),
			Delta3 = dbo.GetPercentChange(medsales1,medsales2),
			Delta4 = dbo.GetPercentChange(ytdmedsales1,ytdmedsales2),
			usegrp = CASE 
						when usegrp='1FA' then '1 Family'
						when usegrp='2FA' then '2 Family'
						when usegrp='3FA' then '3 Family'
						when usegrp='CND' then 'Condo'
						when usegrp='ALL' then 'All Sales'
					END

	Delete from #TrendlineTemp where numsales1 is null or TownCode='ZZZZ';

	Declare @SQL varchar(max) = 'IF OBJECT_ID(''' + @TargetFile + ''', ''U'') IS NOT NULL DROP TABLE ' + @TargetFile;
	exec(@SQL)

	--Create Table
	set @SQL = 'Create table ' + @TargetFile + '(_IndexOrderKey INT NOT NULL IDENTITY(1,1), ' +
		'County varchar(100), Town varchar(100), Category varchar(10), v01 varchar(15), v02 varchar(15), ' +
		'v03 varchar(15), v04 varchar(15), v05 varchar(15), v06 varchar(15), v07 varchar(15), v08 varchar(15), ' + 
		'v09 varchar(15), v10 varchar(15), v11 varchar(15), v12 varchar(15))';
	exec(@SQL)

	set @SQL = 'Insert into ' + @TargetFile + '(County, Town, Category, ' +
					'v01, v02, v03, v04, v05, v06, v07, v08, v09, v10, v11, v12) ' +
				'Select ''' + @CountyName + ''' as County, TownCounty as Town, usegrp as Category, ' +
						'numsales1 as v01, numsales2 as v02, delta1 as v03, ' +
						'ytdnumsales1 as v04, ytdnumsales2 as v05, delta2 as v06, ' +
						'coalesce(medsales1,''0.00'') as v07, coalesce(medsales2,''0.00'') as v08, coalesce(delta3,''N/A'') as v09, ' +
						'coalesce(ytdmedsales1,''0.00'') as v10, coalesce(ytdmedsales2,''0.00'') as v11, coalesce(delta4,''N/A'') as v12 ' +
					'from #TrendlineTemp ' +
					'order by tc, TownCounty, sortval '
	exec(@SQL)
	Declare @RCT varchar(10) = convert(varchar, @@ROWCOUNT);
	
	DROP TABLE #TrendlineTemp; 


	Declare @LogInfo varchar(100) = 'SP Result Location:' + @TargetFile;
	Print @LogInfo;
	exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;
	exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @RCT, 'StepRecordCount';
END
