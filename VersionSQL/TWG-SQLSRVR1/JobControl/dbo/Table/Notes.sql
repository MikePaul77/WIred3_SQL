/****** Object:  Table [dbo].[Notes]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.Notes(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[JobID] [int] NULL,
	[NoteType] [int] NULL,
	[Note] [varchar](max) NULL,
	[StepID] [int] NULL,
	[LastNoteUpdate] [datetime] NULL,
	[NoteBy] [varchar](50) NULL,
	[ShowInValidationAs] [int] NULL,
	[PreRunReminder] [bit] NULL,
	[RemindOnAfterParam] [varchar](20) NULL,
	[StopRemindOnAfter] [bit] NULL,
	[AutoNote] [bit] NULL,
 CONSTRAINT [PK_Notes] PRIMARY KEY CLUSTERED 
(
	[RecID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
