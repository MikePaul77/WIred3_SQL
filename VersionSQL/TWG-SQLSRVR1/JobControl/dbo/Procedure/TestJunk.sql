/****** Object:  Procedure [dbo].[TestJunk]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE TestJunk
AS
BEGIN
	SET NOCOUNT ON;

	print @@PROCID
	print OBJECT_NAME(@@PROCID)
	print OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

END
