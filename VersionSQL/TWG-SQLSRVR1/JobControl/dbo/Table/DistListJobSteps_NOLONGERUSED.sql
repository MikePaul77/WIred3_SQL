/****** Object:  Table [dbo].[DistListJobSteps_NOLONGERUSED]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.DistListJobSteps_NOLONGERUSED(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobStepID] [int] NULL,
	[ListID] [int] NULL,
	[CreateDate] [datetime] NULL,
	[CreateUser] [varchar](50) NULL,
 CONSTRAINT [PK_DistListJobSteps] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [NonClusteredIndex-20190729-105712] ON dbo.DistListJobSteps_NOLONGERUSED
(
	[JobStepID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE dbo.DistListJobSteps_NOLONGERUSED ADD  CONSTRAINT [DF_DistListJobSteps_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
ALTER TABLE dbo.DistListJobSteps_NOLONGERUSED ADD  CONSTRAINT [DF_DistListJobSteps_CreateUser]  DEFAULT (suser_sname()) FOR [CreateUser]
CREATE Trigger [dbo].[trg_DistListJobSteps] on dbo.DistListJobSteps_NOLONGERUSED
	For Insert, Update, Delete
As
	If Exists (Select 0 from Deleted)
		Begin
			If Exists( Select 0 from Inserted)
				Insert into JobControl..DistListJobSteps_HistoryLog(JobStepID, ListID, ActionType, ActionDate, ActionUser)
					Select I.JobStepID, I.ListID, 'Update', Getdate() as ActionDate, SYSTEM_USER as ActionUser from Inserted I
			else
				Insert into JobControl..DistListJobSteps_HistoryLog(JobStepID, ListID, ActionType, ActionDate, ActionUser)
					Select D.JobStepID, D.ListID, 'Delete', Getdate() as ActionDate, SYSTEM_USER as ActionUser from Deleted D
		End
	Else
		Insert into JobControl..DistListJobSteps_HistoryLog(JobStepID, ListID, ActionType, ActionDate, ActionUser)
			Select I.JobStepID, I.ListID, 'Insert', Getdate() as ActionDate, SYSTEM_USER as ActionUser from Inserted I
ALTER TABLE dbo.DistListJobSteps_NOLONGERUSED ENABLE TRIGGER [trg_DistListJobSteps]
