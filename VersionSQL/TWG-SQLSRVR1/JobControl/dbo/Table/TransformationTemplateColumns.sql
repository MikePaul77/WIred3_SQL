/****** Object:  Table [dbo].[TransformationTemplateColumns]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.TransformationTemplateColumns(
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[TransformTemplateID] [int] NULL,
	[OutName] [varchar](200) NULL,
	[SourceCode] [varchar](max) NULL,
	[Disabled] [bit] NULL,
	[VFPSourceCode] [varchar](max) NULL,
	[VFPIn] [bit] NULL,
	[VFPIn_Status] [varchar](100) NULL,
	[LogKeyCol] [bit] NULL,
	[GroupCountCol] [bit] NULL,
	[GroupByCol] [bit] NULL,
	[CalcMaxCol] [bit] NULL,
	[CalcMinCol] [bit] NULL,
	[CalcAvgCol] [bit] NULL,
	[CalcCountCol] [bit] NULL,
	[CalcSumCol] [bit] NULL,
	[CalcMedianCol] [bit] NULL,
	[PivotValCol] [bit] NULL,
	[PivotCalcCol] [varchar](50) NULL,
	[PivotCalcType] [varchar](20) NULL,
 CONSTRAINT [PK_TransformationTemplateColumns] PRIMARY KEY CLUSTERED 
(
	[RecID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

CREATE NONCLUSTERED INDEX [TransformationTemplateColumns_LogKeyCol] ON dbo.TransformationTemplateColumns
(
	[LogKeyCol] ASC
)
INCLUDE([TransformTemplateID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [TransformTemplateID_LogKeyCol] ON dbo.TransformationTemplateColumns
(
	[TransformTemplateID] ASC,
	[LogKeyCol] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE TRIGGER [dbo].[Update_VFPJObs_Map_XForm_VFPCode]  
   ON  dbo.TransformationTemplateColumns 
   AFTER UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	declare @SourceCode varchar(max)
	declare @VFPSourceCode varchar(max)
	declare @ShortTransformationName varchar(100)
	declare @TransformTemplateID int

	if UPDATE(SourceCode)
	begin

		select @SourceCode = SourceCode
				, @VFPSourceCode = VFPSourceCode
				, @TransformTemplateID = TransformTemplateID
				, @ShortTransformationName = tt.ShortTransformationName
			from INSERTED i
				join TransformationTemplates tt on tt.Id = i.TransformTemplateID

		declare @cnt int
		select @cnt = count(*)
			from VFPJObs_Map_XForm_VFPCode
			where VFPSourceCode = @VFPSourceCode

		if @cnt > 1
		begin
			update Map set SQLCode = @SourceCode
				from VFPJObs_Map_XForm_VFPCode Map
					join TransformationTemplateColumns ttc on ttc.VFPSourceCode = Map.VFPSourceCode
															 and ttc.TransformTemplateID = @TransformTemplateID
															 and ttc.VFPIn = 1
				where Map.VFPSourceCode = @VFPSourceCode
					and Map.VFPLayoutID = @ShortTransformationName

			if @@ROWCOUNT = 0
			begin
				insert VFPJObs_Map_XForm_VFPCode (VFPSourceCode, SQLCode, VFPLayoutID)
					values (@VFPSourceCode, @SourceCode, @ShortTransformationName)
			end
		end
		else
			update Map set SQLCode = @SourceCode
				from VFPJObs_Map_XForm_VFPCode Map
					join TransformationTemplateColumns ttc on ttc.VFPSourceCode = Map.VFPSourceCode and ttc.VFPIn = 1
				where ttc.TransformTemplateID = @TransformTemplateID
					and Map.VFPSourceCode = @VFPSourceCode

	end


END

ALTER TABLE dbo.TransformationTemplateColumns ENABLE TRIGGER [Update_VFPJObs_Map_XForm_VFPCode]
