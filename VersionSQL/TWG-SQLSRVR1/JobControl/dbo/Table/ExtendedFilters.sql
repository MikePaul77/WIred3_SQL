/****** Object:  Table [dbo].[ExtendedFilters]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.ExtendedFilters(
	[ID] [int] IDENTITY(0,1) NOT NULL,
	[FilterName] [varchar](200) NULL,
	[Description] [varchar](500) NULL,
	[disabled] [bit] NULL,
	[DisplayOrder] [int] NULL,
	[ScheduleID_NOLONGERUSED] [int] NULL,
	[SQLCode] [varchar](max) NULL,
	[IsPublic] [bit] NULL,
	[CreatedByUserID] [int] NULL,
	[IsCritical] [bit] NULL,
	[Jobs] [int] NULL,
	[CountStamp] [datetime] NULL,
	[QuickList] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
