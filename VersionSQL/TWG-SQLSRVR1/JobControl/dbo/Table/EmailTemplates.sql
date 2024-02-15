/****** Object:  Table [dbo].[EmailTemplates]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.EmailTemplates(
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[TemplateName] [varchar](200) NULL,
	[Subject] [varchar](200) NULL,
	[Body] [varchar](max) NULL,
	[Disabled] [bit] NULL,
	[TemplateCreateDate] [datetime] NULL,
	[TemplateLastUpdated] [datetime] NULL,
	[TemplateCreatedBy] [varchar](50) NULL,
	[IsHTML] [bit] NULL,
	[TemplateLastUpdatedBy] [varchar](50) NULL,
	[DefaultFTPSent] [bit] NULL,
	[DefaultWithFiles] [bit] NULL,
	[DefaultNoFiles] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE dbo.EmailTemplates ADD  CONSTRAINT [DF_EmailTemplates_Disabled]  DEFAULT ((0)) FOR [Disabled]
ALTER TABLE dbo.EmailTemplates ADD  CONSTRAINT [DF_EmailTemplates_TemplateCreateDate]  DEFAULT (getdate()) FOR [TemplateCreateDate]
ALTER TABLE dbo.EmailTemplates ADD  CONSTRAINT [DF_EmailTemplates_TemplateCreatedBy]  DEFAULT (suser_sname()) FOR [TemplateCreatedBy]
