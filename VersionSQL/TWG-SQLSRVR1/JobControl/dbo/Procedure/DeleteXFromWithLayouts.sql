/****** Object:  Procedure [dbo].[DeleteXFromWithLayouts]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE DeleteXFromWithLayouts @XfromID int
AS
BEGIN


	delete JobControl..FileLayoutFields where FileLayoutID in ( 
                        select ID from JobControl..FileLayouts where TransformationTemplateId = @XfromID ) 

    delete JobControl..FileLayouts where TransformationTemplateId = @XfromID

    delete JobControl..TransformationTemplates where ID = @XfromID
     
	delete JobControl..TransformationTemplateColumns where TransformTemplateId = @XfromID

END
