/****** Object:  Table [dbo].[JobControlChangeLog]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.JobControlChangeLog(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[ChangeStamp] [datetime] NULL,
	[ChangeUser] [varchar](50) NULL,
	[TableChange] [varchar](100) NULL,
	[KeyID] [int] NULL,
	[FieldChange] [varchar](100) NULL,
	[PreviousValue] [varchar](200) NULL,
	[NewValue] [varchar](200) NULL,
	[type] [int] NULL
) ON [PRIMARY]
