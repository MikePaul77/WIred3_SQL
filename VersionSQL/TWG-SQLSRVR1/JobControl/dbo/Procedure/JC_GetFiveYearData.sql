/****** Object:  Procedure [dbo].[JC_GetFiveYearData]    Committed by VersionSQL https://www.versionsql.com ******/

-- ================================================
-- Author:		Mark W.
-- Create date: 05-06-2019
-- Description:	Gets data for the Five Year Reports
-- ================================================
CREATE PROCEDURE dbo.JC_GetFiveYearData
	@LastYear int,
	@CountyID int,
	@JobStepID int
AS
BEGIN
	SET NOCOUNT ON;
	Declare @TownID int, 
		@cyear int, 
		@usegrp varchar(10),
		@medsale decimal(10,2),
		@numsales decimal(10,2),
		@yearval int,
		@sql varchar(max),
		@CountyName varchar(100),
		@JobID int,
		@RecordCount int,
		@TargetFile varchar(100),
		@RCT varchar(10),
		@LogSourceName varchar(100),
		@LogInfo varchar(100),
		@ReportType int;  --3=Number of Sales - 2=Median Sales Price


	Select @JobID=JobID from JobControl..JobSteps where StepID=@JobStepID;
	Select @CountyName = fullname from lookups..counties where ID=@CountyID;
	Select @ReportType = StatsTypeID from JobControl..JobSteps where StepID=@JobStepID;
	Print @ReportType;
	if @ReportType=3
		Begin
			IF OBJECT_ID('tempdb.dbo.#NSBT', 'U') IS NOT NULL DROP TABLE #NSBT; 
			Create Table #NSBT(TownID int, TownName varchar(100), usegrp varchar(10), y1ns varchar(15), y2ns varchar(15), 
				y3ns varchar(15), y4ns varchar(15), y5ns varchar(15), ypc1 varchar(15), ypc2 varchar(15), 
				ypc3 varchar(15), ypc4 varchar(15), ypc5 varchar(15), sortval int, tc int )

			Insert into #NSBT(TownID, TownName, UseGrp)
			Select distinct isnull(ps.TownID,999999) as TownID, t.FullName as TownName, ps.usegrp
				from TWG_PropertyData_DL..PropStats ps 
					left join Lookups..towns t on ps.townid=t.id
				where ps.CountyID=@CountyID and ps.cyear>=@LastYear-4 and ps.cyear<=@LastYear and ps.period='YR'
				order by 1,3

			DECLARE FYT CURSOR FOR
				Select isnull(ps.TownID,999999) as TownID, ps.cyear, ps.usegrp, ps.numsales --,* 
					from TWG_PropertyData_DL..PropStats ps 
						left join Lookups..towns t on ps.townid=t.id
					where ps.CountyID=@CountyID and ps.cyear>=@LastYear-4 and ps.cyear<=@LastYear and ps.period='YR'
					order by ps.cyear, t.fullname, ps.usegrp

			OPEN FYT
			FETCH NEXT FROM FYT into @TownID, @cyear, @usegrp, @numsales
			WHILE @@FETCH_STATUS = 0
			BEGIN
				set @yearval = @cyear - @LastYear + 5; 
				set @sql = 'Update #NSBT set y' + convert(varchar,@yearval) + 'ns = ''' + convert(varchar,@numsales) + 
					''' where TownID = ' + convert(varchar,@TownID) + ' and usegrp=''' + @usegrp + ''''
				exec(@sql);
				FETCH NEXT FROM FYT into @TownID, @cyear, @usegrp, @numsales
			END

			CLOSE FYT
			DEALLOCATE FYT

			Update #NSBT 
				set ypc1 = dbo.GetPercentChange(convert(varchar,y1ns), convert(varchar,y2ns)),
					ypc2 = dbo.GetPercentChange(convert(varchar,y2ns), convert(varchar,y3ns)),
					ypc3 = dbo.GetPercentChange(convert(varchar,y3ns), convert(varchar,y4ns)),
					ypc4 = dbo.GetPercentChange(convert(varchar,y4ns), convert(varchar,y5ns)),
					ypc5 = dbo.GetPercentChange(convert(varchar,y1ns), convert(varchar,y5ns)),
					tc=0,
					sortval = 0 + CASE 
								when usegrp='1FA' then 1
								when usegrp='2FA' then 2
								when usegrp='3FA' then 3
								when usegrp='CND' then 4
								when usegrp='ALL' then 5
							  END
			Update #NSBT 
				set usegrp = CASE 
								when usegrp='1FA' then '1 Family'
								when usegrp='2FA' then '2 Family'
								when usegrp='3FA' then '3 Family'
								when usegrp='CND' then 'Condo'
								when usegrp='ALL' then 'All Sales'
							END

			Set @CountyName = @CountyName + ' County';
			Update #NSBT set TownName=@CountyName, tc=1 where TownId=999999


			set @TargetFile = 'JobControlWork.dbo.StatsStepResults_J' + convert(varchar, @JobID) + '_S' + Convert(varchar, @JobStepID)
			set @SQL = 'IF OBJECT_ID(''' + @TargetFile + ''', ''U'') IS NOT NULL DROP TABLE ' + @TargetFile;
			exec(@SQL)

			--Create Table
			set @SQL = 'Create table ' + @TargetFile + '(_IndexOrderKey INT NOT NULL IDENTITY(1,1), ' +
				'County varchar(100), Town varchar(100), LastYear int, Category varchar(10), ns1 varchar(15), ns2 varchar(15), ' +
				'ns3 varchar(15), ns4 varchar(15), ns5 varchar(15), ypc1 varchar(15), ypc2 varchar(15), ypc3 varchar(15), ' + 
				'ypc4 varchar(15), ypc5 varchar(15))';
			exec(@SQL)

			set @SQL = 'Insert into ' + @TargetFile + '(County, Town, LastYear, Category, ' +
							'ns1, ns2, ns3, ns4, ns5, ypc1, ypc2, ypc3, ypc4, ypc5) ' +
						'Select ''' + @CountyName + ''' as County, TownName as Town, ' + 
								convert(varchar, @LastYear) + ' as LastYear, usegrp as Category, ' +
								'y1ns as ns1, y2ns as ns2, y3ns as ns3, ' +
								'y4ns as ns4, y5ns as ns5, ypc1, ypc2, ypc3, ypc4, ypc5 ' +
							'from #NSBT ' +
							'order by tc, TownName, sortval ';
			Print @SQL;
			exec(@SQL)

			exec('Select * from ' + @TargetFile);

			Select @RecordCount=count(*) from #NSBT;
			set @RCT = convert(varchar, @RecordCount);
			set @LogSourceName = 'SP ' + Support.dbo.SPDBName(@@PROCID);
			set @LogInfo = 'SP Result Location:' + @TargetFile;
			Print @LogInfo;
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @RCT, 'StepRecordCount';
			IF OBJECT_ID('tempdb.dbo.#NSBT', 'U') IS NOT NULL DROP TABLE #NSBT; 
		End




	if @ReportType=2
		Begin
			IF OBJECT_ID('tempdb.dbo.#MSPBT', 'U') IS NOT NULL DROP TABLE #MSPBT; 
			Create Table #MSPBT(TownID int, TownName varchar(100), usegrp varchar(10), y1ms varchar(15), y2ms varchar(15), 
				y3ms varchar(15), y4ms varchar(15), y5ms varchar(15), ypc1 varchar(15), ypc2 varchar(15), 
				ypc3 varchar(15), ypc4 varchar(15), ypc5 varchar(15), sortval int, tc int )

			Insert into #MSPBT(TownID, TownName, UseGrp)
			Select distinct isnull(ps.TownID,999999) as TownID, t.FullName as TownName, ps.usegrp
				from TWG_PropertyData_DL..PropStats ps 
					left join Lookups..towns t on ps.townid=t.id
				where ps.CountyID=@CountyID and ps.cyear>=@LastYear-4 and ps.cyear<=@LastYear and ps.period='YR'
				order by 1,3

			DECLARE FYT CURSOR FOR
				Select isnull(ps.TownID,999999) as TownID, ps.cyear, ps.usegrp, ps.medsale --,* 
					from TWG_PropertyData_DL..PropStats ps 
						left join Lookups..towns t on ps.townid=t.id
					where ps.CountyID=@CountyID and ps.cyear>=@LastYear-4 and ps.cyear<=@LastYear and ps.period='YR'
					order by ps.cyear, t.fullname, ps.usegrp

			OPEN FYT
			FETCH NEXT FROM FYT into @TownID, @cyear, @usegrp, @medsale
			WHILE @@FETCH_STATUS = 0
			BEGIN
				set @yearval = @cyear - @LastYear + 5; 
				set @sql = 'Update #MSPBT set y' + convert(varchar,@yearval) + 'ms = ''' + convert(varchar,@medsale) + 
					''' where TownID = ' + convert(varchar,@TownID) + ' and usegrp=''' + @usegrp + ''''
				exec(@sql);
				FETCH NEXT FROM FYT into @TownID, @cyear, @usegrp, @medsale
			END

			CLOSE FYT
			DEALLOCATE FYT

			Update #MSPBT 
				set ypc1 = dbo.GetPercentChange(convert(varchar,y1ms), convert(varchar,y2ms)),
					ypc2 = dbo.GetPercentChange(convert(varchar,y2ms), convert(varchar,y3ms)),
					ypc3 = dbo.GetPercentChange(convert(varchar,y3ms), convert(varchar,y4ms)),
					ypc4 = dbo.GetPercentChange(convert(varchar,y4ms), convert(varchar,y5ms)),
					ypc5 = dbo.GetPercentChange(convert(varchar,y1ms), convert(varchar,y5ms)),
					tc=0,
					sortval = 0 + CASE 
								when usegrp='1FA' then 1
								when usegrp='2FA' then 2
								when usegrp='3FA' then 3
								when usegrp='CND' then 4
								when usegrp='ALL' then 5
							  END
			Update #MSPBT 
				set usegrp = CASE 
								when usegrp='1FA' then '1 Family'
								when usegrp='2FA' then '2 Family'
								when usegrp='3FA' then '3 Family'
								when usegrp='CND' then 'Condo'
								when usegrp='ALL' then 'All Sales'
							END

			Set @CountyName = @CountyName + ' County';
			Update #MSPBT set TownName=@CountyName, tc=1 where TownId=999999


			set @TargetFile = 'JobControlWork.dbo.StatsStepResults_J' + convert(varchar, @JobID) + '_S' + Convert(varchar, @JobStepID)
			set @SQL = 'IF OBJECT_ID(''' + @TargetFile + ''', ''U'') IS NOT NULL DROP TABLE ' + @TargetFile;
			exec(@SQL)

			--Create Table
			set @SQL = 'Create table ' + @TargetFile + '(_IndexOrderKey INT NOT NULL IDENTITY(1,1), ' +
				'County varchar(100), Town varchar(100), LastYear int, Category varchar(10), msp1 varchar(15), msp2 varchar(15), ' +
				'msp3 varchar(15), msp4 varchar(15), msp5 varchar(15), ypc1 varchar(15), ypc2 varchar(15), ypc3 varchar(15), ' + 
				'ypc4 varchar(15), ypc5 varchar(15))';
			exec(@SQL)

			set @SQL = 'Insert into ' + @TargetFile + '(County, Town, LastYear, Category, ' +
							'msp1, msp2, msp3, msp4, msp5, ypc1, ypc2, ypc3, ypc4, ypc5) ' +
						'Select ''' + @CountyName + ''' as County, TownName as Town, ' + 
								convert(varchar, @LastYear) + ' as LastYear, usegrp as Category, ' +
								'y1ms as msp1, y2ms as msp2, y3ms as msp3, ' +
								'y4ms as msp4, y5ms as msp5, ypc1, ypc2, ypc3, ypc4, ypc5 ' +
							'from #MSPBT ' +
							'order by tc, TownName, sortval ';
			Print @SQL;
			exec(@SQL)

			exec('Select * from ' + @TargetFile);

			Select @RecordCount=count(*) from #MSPBT;
			set @RCT = convert(varchar, @RecordCount);
			set @LogSourceName = 'SP ' + Support.dbo.SPDBName(@@PROCID);
			set @LogInfo = 'SP Result Location:' + @TargetFile;
			Print @LogInfo;
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @LogInfo, @LogSourceName;
			exec JobControl.dbo.JobStepLogInsert @JobStepID, 1, @RCT, 'StepRecordCount';
			IF OBJECT_ID('tempdb.dbo.#MSPBT', 'U') IS NOT NULL DROP TABLE #MSPBT; 
		End

END
