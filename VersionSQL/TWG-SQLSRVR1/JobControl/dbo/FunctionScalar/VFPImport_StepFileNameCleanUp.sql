/****** Object:  ScalarFunction [dbo].[VFPImport_StepFileNameCleanUp]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.VFPImport_StepFileNameCleanUp
(
	@OrigFileName varchar(2000)
)
RETURNS varchar(2000)
AS
BEGIN
	DECLARE @Result varchar(2000)

	Declare @OutPath varchar(2000)
	Declare @FileName varchar(2000)


	set @OrigFileName = ltrim(rtrim(@OrigFileName))
	set @OrigFileName = replace(@OrigFileName,' ','')
	set @OrigFileName = replace(@OrigFileName,'"\"','\')
	set @OrigFileName = replace(@OrigFileName,'''','"')

	set @OrigFileName = replace(@OrigFileName,'iif(oJC.CurState="MA","BT\","CR\")','<IfStMA|BT|CR>\')

	if charindex('\',reverse(@OrigFileName)) > 0
	begin
		set @OutPath = substring(@OrigFileName,1,len(@OrigFileName) - charindex('\',reverse(@OrigFileName)) + 1)
		set @FileName = substring(@OrigFileName,len(@OrigFileName) - charindex('\',reverse(@OrigFileName)) + 2,2000)
	end
	else
	begin
		set @OutPath = ''
		set @FileName = @OrigFileName
	end

	set @FileName = replace(@FileName,'iif(empty(oJC.ccode),oJC.CurState,strtran(alltrim(GetDescription(oJC.ccode,"Towns","ccode","County")),"","_"))','<CN><ST>')
	set @FileName = replace(@FileName,'alltrim(getdescription(ojc.ccode,towns,ccode,county))','<CN>')
	set @FileName = replace(@FileName,'strtran(dtoc(GetDescription(oJC.curstate+oJC.IssWeek,"WeekIssu","extrweek","IssDate")),"/","")','<IDT>')
	set @FileName = replace(@FileName,'strtran(dtos(datetime())+"_"+str(hour(datetime()),2)+str(minute(datetime()),2)," ","0")','<YYYYMMDD>_<HH><MI>')
	set @FileName = replace(@FileName,'strtran(dtoc(GetDescription(oJC.curstate+oJC.IssWeek,"WeekIssu","extrweek","IssDate")),"/","")','<IW6>')
	set @FileName = replace(@FileName,'strtran(alltrim(GetDescription(oJC.ccode,"MiscType","code","Fullname")),"","")','<TT>')
	set @FileName = replace(@FileName,'iif(empty(oJC.ccode),oJC.CurState,strtran(alltrim(GetDescription(oJC.ccode,"Towns","ccode","County")),"","_"))+oJC.CalPeriod+oJC.CalYear','<ST><CN><TN>')
	set @FileName = replace(@FileName,'strtran(alltrim(GetDescription(ojc.ccode,''Towns'',''ccode'',''County'')),'''','''')','<CN>')
	set @FileName = replace(@FileName,'strtran(alltrim(GetDescription(oJC.ccode, "Towns","ccode" , "County")),"","_")','<CN>')
	set @FileName = replace(@FileName,'strtran(alltrim(GetDescription(oJC.ccode,"Towns","ccode","County")),"","")','<CN>')
	set @FileName = replace(@FileName,'strtran(alltrim(GetDescription(oJC.town,"Towns","town","Fullname")),"","_")','<TN>')
	set @FileName = replace(@FileName,'iif(oJC.curstate="ME","E",left(lower(ojc.curState),1))','<IfStME|E|ST1>')
	set @FileName = replace(@FileName,'GetDescription(oJC.ccode,"Towns","ccode","County")','<CN>')
	set @FileName = replace(@FileName,'GetDescription(oJC.ccode, "Towns","ccode" , "County"))','<CN>')
	set @FileName = replace(@FileName,'getdescription(ojc.ccode,''towns'',''ccode'',''county'')','<CN>')
	set @FileName = replace(@FileName,'GetDescription(oJC.town,"Towns","town","Fullname")','<TN>')
	set @FileName = replace(@FileName,'GetDescription(ojc.ccode,"Towns","rcode","Registry")','<RN>')
	set @FileName = replace(@FileName,'GetDescription(oJC.ccode,"Towns","ccode","statefips")','<SFIP>')
	set @FileName = replace(@FileName,'GetDescription(oJC.ccode,"Towns","ccode","countyfips")','<CFIP>')
	set @FileName = replace(@FileName,'GetDescription(ojc.ccode,"Towns","rcode","Registry")','<RN>')
	set @FileName = replace(@FileName,'iif("PR"$upper(ojc.inTable),"pra","txa")','<IfProp|pr|tx>a')
	set @FileName = replace(@FileName,'iif("PR"$upper(ojc.inTable),"prc","txc")','<IfProp|pr|tx>c')
	set @FileName = replace(@FileName,'iif(ojc.curstate="CT","","_"+ojc.curstate)','<IfStCT||ST>')
	set @FileName = replace(@FileName,'strtran(str(ojc.jobid,7,0)," ","0")', '<JobID>')
	set @FileName = replace(@FileName,'transform(oJC.jobid)', '<JobID>')
	set @FileName = replace(@FileName,'left(lower(ojc.curState),1)', '<ST1>')
	set @FileName = replace(@FileName,'left(ojc.curState,1)', '<ST1>')
	set @FileName = replace(@FileName,'sys(2015)','<PrcName>')
	set @FileName = replace(@FileName,'alltrim(oJC.PassedMemo)','<TBD>')
	set @FileName = replace(@FileName,'dtos(datetime())','<YYYYMMDD>')
	set @FileName = replace(@FileName,'dtos(date())','<YYYYMMDD>')
	set @FileName = replace(@FileName,'str(hour(datetime()),2)','<HH>')
	set @FileName = replace(@FileName,'str(minute(datetime()),2)','<MI>')
	set @FileName = replace(@FileName,'substr(ojc.issMonth,5,2)','<IM2>')
	set @FileName = replace(@FileName,'substr(ojc.issMonth,1,2)','<IMY2>')
	set @FileName = replace(@FileName,'left(ojc.issMonth,2)','<IM2>')
	set @FileName = replace(@FileName,'Getmonth(oJC.issMonth)','<IM2>')
	set @FileName = replace(@FileName,'right(ojc.issMonth,2)','<IMY2>')
	set @FileName = replace(@FileName,'substr(oJC.issweek,3)','<IW4>')
	set @FileName = replace(@FileName,'SUBSTR(oJC.issweek,3,4)','<IW4>')
	set @FileName = replace(@FileName,'substr(oJC.issweek,3)','<IW4>')
	set @FileName = replace(@FileName,'right(oJC.IssWeek,4)','<IW4>')
	set @FileName = replace(@FileName,'right(oJC.CalYear,2)','<CY2>')
	set @FileName = replace(@FileName,'right(ojc.fy,2)','<FY2>')

	set @FileName = replace(@FileName,'oJC.CalPeriod','<CP>')
	set @FileName = replace(@FileName,'oJC.CalYear','<CY>')

	set @FileName = replace(@FileName,'oJC.tablename','<TBLN>')
	set @FileName = replace(@FileName,'ojc.CCode','<CC>')
	set @FileName = replace(@FileName,'ojc.town','<TC>')
	set @FileName = replace(@FileName,'oJC.IssMonth','<IM6>')
	set @FileName = replace(@FileName,'oJC.issweek','<IW6>')
	set @FileName = replace(@FileName,'oJC.curstate','<ST>')

	set @FileName = replace(@FileName,'strtran(','')

	declare @Code varchar(50), @cnt int

    DECLARE curA CURSOR FOR
		select '<TBLN>'
		union select '<RN>'
		union select '<TN>'
		union select '<TC>'
		union select '<CN>'
		union select '<CC>'
		union select '<ST>'
		union select '<CP>'
		union select '<CY>'
		union select '<YYYYMMDD>'

     OPEN curA

     FETCH NEXT FROM curA into @Code
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

		set @Cnt = 1
		while @cnt <= 3
		begin
			 set @FileName = replace(@FileName,'strtran(' + @Code + '," ","")',@Code)
			 set @FileName = replace(@FileName,'strtran(' + @Code + ',,)',@Code)
			 set @FileName = replace(@FileName,'strtran(' + @Code + ',,_)',@Code)
			 set @FileName = replace(@FileName,'alltrim(' + @Code + ')',@Code)
			 set @FileName = replace(@FileName,'strtran(' + @Code + '," ","0")',@Code)
			 set @FileName = replace(@FileName,'strtran(' + @Code + ',,0)',@Code)
			 set @FileName = replace(@FileName,'proper(' + @Code + ')',@Code)
			 set @FileName = replace(@FileName,'upper(' + @Code + ')',@Code)
			 set @FileName = replace(@FileName,'lower(' + @Code + ')',@Code)
			 --set @FileName = replace(@FileName,'proper(' + @Code + ')','<Pc' + replace(@Code,'<','') + '<')
			 --set @FileName = replace(@FileName,'upper(' + @Code + ')','<Uc' + replace(@Code,'<','') + '<')
			 --set @FileName = replace(@FileName,'lower(' + @Code + ')','<Lc' + replace(@Code,'<','') + '<')
			set @cnt = @cnt + 1
		end


         FETCH NEXT FROM curA into @Code
     END
     CLOSE curA
     DEALLOCATE curA

	set @FileName = replace(@FileName,'LEFT(<TBLN>,12)','<TBLN12>')
	set @FileName = replace(@FileName,'LEFT(<TBLN>,2)','<TBLN12>')
	set @FileName = replace(@FileName,'strtran(<YYYYMMDD>_<HH><MI>,,0)','<YYYYMMDD>_<HH><MI>')

    DECLARE curA CURSOR FOR
		select '<TBLN12>'
		union select '<TBLN12>'
		union select '<YYYYMMDD>_<HH><MI>'

     OPEN curA

     FETCH NEXT FROM curA into @Code
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

		set @FileName = replace(@FileName,'strtran(' + @Code + '," ","")',@Code)
		set @FileName = replace(@FileName,'alltrim(' + @Code + ')',@Code)
		set @FileName = replace(@FileName,'proper(' + @Code + ')',@Code)
		set @FileName = replace(@FileName,'upper(' + @Code + ')',@Code)
		set @FileName = replace(@FileName,'lower(' + @Code + ')',@Code)

         FETCH NEXT FROM curA into @Code
     END
     CLOSE curA
     DEALLOCATE curA

	set @FileName = replace(@FileName,'''','')
	set @FileName = replace(@FileName,'"','')
	set @FileName = replace(@FileName,'+','')
	set @FileName = replace(@FileName,' ','')

	set @FileName = replace(@FileName,'))',')')
	set @FileName = replace(@FileName,',,)','')
	set @FileName = replace(@FileName,',,0)','')
	set @FileName = replace(@FileName,',,_)','')

	declare @PeriodMark int

	set @PeriodMark = CHARINDEX('.',@FileName)
	if @PeriodMark > 0
		set @FileName = Left(@FileName,@PeriodMark-1)

	set @OutPath = replace(@OutPath,'oJC.curstate','<ST>')

	set @OutPath = replace(@OutPath,'''','')
	set @OutPath = replace(@OutPath,'"','')
	set @OutPath = replace(@OutPath,'+','')
	set @OutPath = replace(@OutPath,' ','')
	set @OutPath = replace(@OutPath,'\redp\output\','R:\Wired3\ReportsOut\')
	set @OutPath = replace(@OutPath,'redp\output\','R:\Wired3\ReportsOut\')
	set @OutPath = replace(@OutPath,'\redp\work\','R:\Wired3\ReportsOut\work\')
	set @OutPath = replace(@OutPath,'\redp\dbc\','R:\Wired3\ReportsOut\dbc\')
	set @OutPath = replace(@OutPath,'\TWGDB\','R:\Wired3\ReportsOut\TWGDB\')

	set @Result = @OutPath + @FileName

	if @OutPath like '%\work\query\%'
		set @Result = ''

	RETURN @Result

END
