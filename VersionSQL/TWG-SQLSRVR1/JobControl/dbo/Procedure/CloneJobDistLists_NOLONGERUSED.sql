/****** Object:  Procedure [dbo].[CloneJobDistLists_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE CloneJobDistLists @OrigJobID int, @NewJobID int
AS
BEGIN
	SET NOCOUNT ON;

	declare @PrevListID int, @NewListID int, @NewStepID int, @PrevStepID int

	DECLARE curClnJDL CURSOR FOR
		select dljs.ListID, njs.StepID NewStepID, pjs.StepID PrevStepID
			from JobControl..DistListJobSteps dljs
				join JobControl..JobSteps pjs on pjs.StepID = dljs.JobStepID
				join JobControl..JobSteps njs on njs.JobID = @NewJobID
												 and pjs.stepOrder = njs.stepOrder
			where pjs.JobID = @OrigJobID

     OPEN curClnJDL

     FETCH NEXT FROM curClnJDL into @PrevListID, @NewStepID, @PrevStepID
     WHILE (@@FETCH_STATUS <> -1)
     BEGIN

		insert JobControl..DistLists (ListName, ListCat)
			select ListName, ListCat
				from JobControl..DistLists
				where ID = @PrevListID

		select @NewListID = Max(ID) from JobControl..DistLists

		insert JobControl..DistListJobSteps (JobStepID, ListID)
			values (@NewStepID, @NewListID)

		insert JobControl..DistListEntries (ListID, EntryType, Disabled, SourceID, EmailAddress, EMailName)
			select @NewListID, EntryType, Disabled, SourceID, EmailAddress, EMailName
				from JobControl..DistListEntries
				where ListID = @PrevListID

          FETCH NEXT FROM curClnJDL into @PrevListID, @NewStepID, @PrevStepID
     END
     CLOSE curClnJDL
     DEALLOCATE curClnJDL

END
