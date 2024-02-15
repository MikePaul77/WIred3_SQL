/****** Object:  Procedure [dbo].[GetTableRowCount]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 12-16-2018
-- Description:	Gets the number of records in a table more efficiently(on big tables) than using count(*)

-- Mark W. - 06-29-2020: This used to be a sp in JobControlWork.  Moved it to JobControl.  Added in a @DatabaseName
--						 parameter to be able to run on any database.
-- =============================================
CREATE PROCEDURE dbo.GetTableRowCount
	@TableName varchar(200), @RC int OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	Create table #TempStats(name varchar(255), rows int, reserved varchar(50), data varchar(50), 
								index_size varchar(50), unused varchar(50));
	Declare @DatabaseName varchar(200)=substring(@TableName,1,CHARINDEX('..', @TableName)-1)
	if @DatabaseName in ('JobControl','')
		IF OBJECT_ID(@TableName, 'U') IS NOT NULL 
			Begin
				INSERT INTO #TempStats exec sp_spaceused @TableName
				Select @RC=[rows] from #TempStats;
			END
		Else	
			Set @RC=0;
	ELSE
		Begin
			IF OBJECT_ID(@TableName, 'U') IS NOT NULL 
				Begin
					if CHARINDEX('..', @TableName)>0
						set @TableName=substring(@TableName,CHARINDEX('..', @TableName)+2, 200)
					Exec('Insert into #TempStats Exec ' + @DatabaseName + '.sys.sp_spaceused ''' + @TableName + '''')
					Select @RC=[rows] from #TempStats;
				END
			Else	
				Set @RC=0;
		End
	Drop Table #TempStats;
END
