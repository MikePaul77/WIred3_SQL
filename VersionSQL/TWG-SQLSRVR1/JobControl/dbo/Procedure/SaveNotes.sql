/****** Object:  Procedure [dbo].[SaveNotes]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Mark W.
-- Create date: 08-25-2019
-- Description:	Used for saving notes and logging the history
-- =============================================
CREATE PROCEDURE dbo.SaveNotes
	@JobID int,
	@NewNote varchar(max),
	@NoteType int,
	@StepID int
AS
BEGIN
	SET NOCOUNT ON;

	if @StepID=0 set @StepID = Null;
	declare @OldNote varchar(max)

	If @StepID is null
		Select @OldNote=isnull(Note,'') from Notes where JobID=@JobID and NoteType=@NoteType and StepID is null;
	ELSE
		Select @OldNote=isnull(Note,'') from Notes where JobID=@JobID and NoteType=@NoteType and StepID=@StepID;

	Print '@OldNote: ' + @OldNote;
	Print '@NewNote: ' + @NewNote;

	Set @OldNote = Replace(@OldNote, ''', '''');
	Set @NewNote = Replace(@NewNote, ''', '''');

	if (@OldNote<>'' or @NewNote<>'') and @OldNote<>@NewNote
		insert JobControl..JobControlChangeLog (ChangeStamp, ChangeUser, TableChange, FieldChange, KeyID, PreviousValue, NewValue, type)
			values(getdate(), SYSTEM_USER, 'Notes', 'Notes', iif(@StepID is null, @JobID, @StepID), left(isnull(@OldNote,''),200), left(@NewNote,200), @NoteType)


	if @NewNote='' and @OldNote<>''
		Begin
			Print 'Delete from Notes where JobID=' + convert(varchar,@JobID) + ' and NoteType=' + convert(varchar,@NoteType) 
				+ ' and StepID=' + iif(@StepID is null, 'null', convert(varchar,@StepID)) + ';';
			if @StepID is null
				Delete from Notes where JobID=@JobID and NoteType=@NoteType and StepID is null;
			else
				Delete from Notes where JobID=@JobID and NoteType=@NoteType and StepID=@StepID;
		End
	else
		if @NewNote<>''
			Begin
				if @OldNote<>''
					Begin
						If @StepID is null
							Update Notes set Note=@NewNote, LastNoteUpdate=GetDate() 
								where JobID=@JobID and NoteType=@NoteType and StepID is null;
						else
							Update Notes set Note=@NewNote, LastNoteUpdate=GetDate() 
								where JobID=@JobID and NoteType=@NoteType and StepID=@StepID;
					End
				else
					Insert into Notes(JobID, NoteType, Note, StepID, LastNoteUpdate)
						values(@JobID, @NoteType, @NewNote, @StepID, GetDate());
			End
END
