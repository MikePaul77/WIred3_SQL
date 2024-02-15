/****** Object:  Procedure [dbo].[GetLayoutFields]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetLayoutFields @LayoutID int, @FieldRecID int
AS
BEGIN
	SET NOCOUNT ON;

	set @LayoutID = coalesce(@LayoutID,0)
	set @FieldRecID = coalesce(@FieldRecID,0)

	select *
	        from (
        select RecID
	        , OutOrder
	        , SortOrder
	        , SortDir
	        --, OutType
	        , OutWidth
	        , sum(case when coalesce(Disabled, 0) = 0 then OutWidth else 0 end) over (order by OutOrder) EndPosition
	        , SrcName
	        , OutName
	        , coalesce(Disabled, 0) Disabled
	        , coalesce(FutureUse, 0) FutureUse
	        , CaseChange
	        , coalesce(DoNotTrim, 0) DoNotTrim
	        , coalesce(Padding, 'None') Padding
	        , PaddingLength
	        , PaddingChar
	        , coalesce(XLNoFormat, 0) XLNoFormat
	        , XLAlign
	        , coalesce(Hide, 0) Hide
			, coalesce(LayoutFormatID, 0) LayoutFormatID
			, coalesce(FieldDescrip,'') FieldDescrip
			, coalesce(ConformToWidth, 0) ConformToWidth
			, coalesce(IgnoreDataTruncation, 0) IgnoreDataTruncation
	        from JobControl..FileLayoutFields
	        where FileLayoutID = @LayoutID 
		        or FileLayoutID = (select FileLayoutID from JobControl..FileLayoutFields where RecID = @FieldRecID)
        ) x
	order by x.OutOrder

END
