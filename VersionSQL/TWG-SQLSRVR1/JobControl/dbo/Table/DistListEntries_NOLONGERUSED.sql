/****** Object:  Table [dbo].[DistListEntries_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DistListEntries_NOLONGERUSED(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ListID] [int] NULL,
	[EntryType] [varchar](50) NULL,
	[Disabled] [bit] NULL,
	[SourceID] [int] NULL,
	[EmailAddress] [varchar](250) NULL,
	[EMailName] [varchar](250) NULL,
	[FTP] [bit] NULL,
	[Email] [bit] NULL,
	[CreateDate] [datetime] NULL,
	[CreateUser] [varchar](50) NULL,
 CONSTRAINT [PK_DistListEntries] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE dbo.DistListEntries_NOLONGERUSED ADD  CONSTRAINT [DF_DistListEntries_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
ALTER TABLE dbo.DistListEntries_NOLONGERUSED ADD  CONSTRAINT [DF_DistListEntries_CreateUser]  DEFAULT (suser_sname()) FOR [CreateUser]
CREATE Trigger [dbo].[trg_DistListEntries] on dbo.DistListEntries_NOLONGERUSED
	For Insert, Update, Delete
As
	If Exists (Select 0 from Deleted)
		Begin
			If Exists( Select 0 from Inserted)
				Insert into JobControl..DistListEntries_HistoryLog(ID, ListID, EntryType, Disabled, SourceID, EmailAddress,
					EmailName, FTP, Email, ActionType, ActionDate, ActionUser)
					Select I.ID, I.ListID, I.EntryType, I.Disabled, I.SourceID, I.EmailAddress, I.EmailName, I.FTP, I.Email,
						'Update', Getdate() as ActionDate, SYSTEM_USER as ActionUser from Inserted I
			else
				Insert into JobControl..DistListEntries_HistoryLog(ID, ListID, EntryType, Disabled, SourceID, EmailAddress,
					EmailName, FTP, Email, ActionType, ActionDate, ActionUser)
					Select D.ID, D.ListID, D.EntryType, D.Disabled, D.SourceID, D.EmailAddress, D.EmailName, D.FTP, D.Email,
						'Delete', Getdate() as ActionDate, SYSTEM_USER as ActionUser from Deleted D
		End
	Else
		Insert into JobControl..DistListEntries_HistoryLog(ID, ListID, EntryType, Disabled, SourceID, EmailAddress,
				EmailName, FTP, Email, ActionType, ActionDate, ActionUser)
			Select I.ID, I.ListID, I.EntryType, I.Disabled, I.SourceID, I.EmailAddress, I.EmailName, I.FTP, I.Email,
					'Insert', Getdate() as ActionDate, SYSTEM_USER as ActionUser from Inserted I
ALTER TABLE dbo.DistListEntries_NOLONGERUSED ENABLE TRIGGER [trg_DistListEntries]
