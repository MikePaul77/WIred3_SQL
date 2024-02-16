/****** Object:  Table [dbo].[DistLists_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DistLists_NOLONGERUSED(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ListName] [varchar](500) NULL,
	[Disabled] [bit] NULL,
	[ListCat] [varchar](50) NULL,
	[CreateDate] [datetime] NULL,
	[CreateUser] [varchar](50) NULL,
 CONSTRAINT [PK_DistLists] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE dbo.DistLists_NOLONGERUSED ADD  CONSTRAINT [DF_DistLists_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
ALTER TABLE dbo.DistLists_NOLONGERUSED ADD  CONSTRAINT [DF_DistLists_CreateUser]  DEFAULT (suser_sname()) FOR [CreateUser]
CREATE Trigger [dbo].[trg_DistLists] on dbo.DistLists_NOLONGERUSED
	For Insert, Update, Delete
As
	If Exists (Select 0 from Deleted)
		Begin
			If Exists( Select 0 from Inserted)
				Insert into JobControl..DistLists_HistoryLog(ID, ListName, Disabled, ListCat, ActionType, ActionDate, ActionUser)
					Select I.ID, I.ListName, I.Disabled, I.ListCat, 'Update', Getdate() as ActionDate, SYSTEM_USER as ActionUser from Inserted I
			else
				Insert into JobControl..DistLists_HistoryLog(ID, ListName, Disabled, ListCat, ActionType, ActionDate, ActionUser)
					Select D.ID, D.ListName, D.Disabled, D.ListCat, 'Delete', Getdate() as ActionDate, SYSTEM_USER as ActionUser from Deleted D
		End
	Else
		Insert into JobControl..DistLists_HistoryLog(ID, ListName, Disabled, ListCat, ActionType, ActionDate, ActionUser)
			Select I.ID, I.ListName, I.Disabled, I.ListCat, 'Insert', Getdate() as ActionDate, SYSTEM_USER as ActionUser from Inserted I
ALTER TABLE dbo.DistLists_NOLONGERUSED ENABLE TRIGGER [trg_DistLists]
