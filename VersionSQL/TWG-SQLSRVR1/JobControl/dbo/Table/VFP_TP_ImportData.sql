﻿/****** Object:  Table [dbo].[VFP_TP_ImportData]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE dbo.VFP_TP_ImportData(
	[JC_JobStepID] [int] NOT NULL,
	[PROPID] [int] NOT NULL,
	[SITEID] [int] NOT NULL,
	[TRANID] [int] NOT NULL,
	[MISCID] [int] NOT NULL,
	[CREDID] [int] NOT NULL,
	[SOURCE] [varchar](1) NULL,
	[NOTES] [varchar](max) NULL,
	[MAPREF] [varchar](25) NOT NULL,
	[CCODE] [varchar](2) NULL,
	[TOWN] [varchar](4) NULL,
	[NOSTNUM] [bit] NULL,
	[STREET] [varchar](25) NULL,
	[STNUM] [int] NULL,
	[STNUMEXT] [varchar](5) NULL,
	[UNIT] [varchar](6) NULL,
	[LOTCODE] [varchar](1) NULL,
	[CONDONAME] [varchar](21) NULL,
	[ZIPCODE] [varchar](5) NULL,
	[PLUS4] [varchar](4) NULL,
	[CNSSTRACT] [varchar](6) NULL,
	[CNSSBLGR] [varchar](4) NULL,
	[CARRIER_RT] [varchar](8) NULL,
	[LAT] [int] NULL,
	[LON] [int] NULL,
	[OWNER1] [varchar](25) NULL,
	[PHONE] [varchar](12) NULL,
	[EXACTDATE] [bit] NULL,
	[STATEUSE] [varchar](3) NULL,
	[PARCELID] [varchar](25) NULL,
	[PSTREET] [varchar](40) NULL,
	[OSTREET] [varchar](40) NULL,
	[FULLNAME1] [varchar](40) NULL,
	[FULLNAME2] [varchar](40) NULL,
	[BUYER1] [varchar](25) NULL,
	[BUYER2] [varchar](25) NULL,
	[BUYERREL] [varchar](1) NULL,
	[SELLER1] [varchar](25) NULL,
	[SELLER2] [varchar](25) NULL,
	[SELLERREL] [varchar](1) NULL,
	[DATE] [date] NULL,
	[PRICE] [int] NULL,
	[VALIDSALE] [varchar](1) NULL,
	[SALETYPE] [varchar](1) NULL,
	[DEEDTYPE] [varchar](2) NULL,
	[LENDER] [varchar](6) NULL,
	[LNAME] [varchar](40) NULL,
	[MORTGAGE] [int] NULL,
	[INTEREST] [decimal](6, 3) NULL,
	[INTTYPE] [varchar](1) NULL,
	[TERM] [decimal](2, 0) NULL,
	[SUBMTG] [varchar](1) NULL,
	[MTGCAT] [varchar](4) NULL,
	[MTGASSIGNE] [varchar](21) NULL,
	[EXTRYEAR] [varchar](4) NOT NULL,
	[EXTRWEEK] [varchar](2) NOT NULL,
	[DEF1NAME] [varchar](25) NULL,
	[DEF2NAME] [varchar](25) NULL,
	[DEFREL] [varchar](1) NULL,
	[ALIAS1] [varchar](25) NULL,
	[ALIAS1CODE] [varchar](1) NULL,
	[PLAINTIFF1] [varchar](25) NULL,
	[PLAINTIFF2] [varchar](25) NULL,
	[SHERATTY] [varchar](25) NULL,
	[DEPOSIT] [int] NULL,
	[SALEDATETM] [datetime] NULL,
	[SALELOC] [varchar](25) NULL,
	[ORIGMORTG] [date] NULL,
	[TAXTYPE1] [varchar](4) NULL,
	[TAXTYPE2] [varchar](4) NULL,
	[INITDATE] [date] NULL,
	[PUBDATE] [date] NULL,
	[PUB] [varchar](3) NULL,
	[RESPDATE] [date] NULL,
	[MISCTYPE] [varchar](2) NULL,
	[BOOK] [int] NULL,
	[PAGE] [int] NULL,
	[DOCKETREF] [varchar](12) NULL,
	[SELLNAME] [varchar](1) NULL,
	[ERROR] [int] NULL,
	[BATCHNUM] [int] NULL,
	[FILENAME] [varchar](10) NULL,
	[RECNUM] [int] NULL,
	[MODIDATE] [datetime] NOT NULL,
	[MODITYPE] [varchar](1) NOT NULL,
	[MODITBLE] [varchar](8) NULL,
	[POSTED] [bit] NULL,
	[POSTTIME] [datetime] NULL,
	[MATCHED] [varchar](1) NULL,
	[ADDRSTATS] [varchar](1) NULL,
	[SZIPPED] [varchar](1) NULL,
	[OZIPPED] [varchar](1) NULL,
	[NAMED] [varchar](1) NULL,
	[PHONED] [varchar](1) NULL,
	[DEDUPEFLAG] [varchar](1) NULL,
	[REVLEND] [varchar](1) NULL,
	[REVFD] [varchar](1) NULL,
	[TAXED] [varchar](1) NULL,
	[ADCPSTREET] [bit] NULL,
	[ADCOSTREET] [bit] NULL,
	[ADCNAMES] [bit] NULL,
	[ADCDESC] [bit] NULL,
	[INCINRPT] [bit] NULL,
	[ADDRSTATO] [varchar](1) NULL,
	[ADDRSTATR] [varchar](1) NULL,
	[RELAGE] [varchar](1) NULL,
	[ADCRESOWNR] [bit] NULL,
	[OOR_DATE] [date] NULL,
	[MAPREFED] [varchar](1) NULL,
	[TAXBILLNUM] [varchar](11) NULL,
	[OLDVALUE] [varchar](30) NULL,
	[USESOURCE] [varchar](24) NULL,
	[RCODE] [varchar](2) NULL,
	[NEEDRESRCH] [bit] NULL,
	[USEDDATE] [date] NULL,
	[ADDRREV] [varchar](1) NULL,
	[PRADDRSAME] [varchar](1) NULL,
	[NOMIID] [int] NOT NULL,
	[NOMSRCE] [varchar](1) NULL,
	[SADDRLEVEL] [varchar](1) NULL,
	[OADDRLEVEL] [varchar](1) NULL,
	[MTGDID] [int] NOT NULL,
	[CHNGDATE] [date] NULL,
	[INTADJ] [decimal](6, 3) NULL,
	[MTGBOOK] [int] NULL,
	[MTGPAGE] [int] NULL,
	[MTGDOCKETR] [varchar](12) NULL,
	[INDNAME] [varchar](7) NULL,
	[AUCCODE] [varchar](3) NULL,
	[PFPUBDATE] [date] NULL,
	[AUCSTCODE] [varchar](2) NULL,
	[AUCSTDATE] [date] NULL,
	[SALEDTNEW] [datetime] NULL,
	[ATTYPHONE] [varchar](12) NULL,
	[MIN] [varchar](18) NULL,
	[ORIGID] [varchar](10) NULL,
	[ORIGNAME] [varchar](27) NULL,
	[BROKERID] [varchar](8) NULL,
	[BROKERN] [varchar](45) NULL,
	[FHAVA] [varchar](30) NULL,
	[TRNDID] [int] NOT NULL,
	[SIGNDATE] [date] NULL,
	[SIGNER] [varchar](100) NULL,
	[MTGADDID] [int] NOT NULL,
	[DOCTYPE] [varchar](40) NULL,
	[ORIGBOOK] [int] NULL,
	[ORIGPAGE] [int] NULL,
	[ORIGDOC] [varchar](12) NULL,
	[ORIGDATE] [date] NULL,
	[ASNRLNAME] [varchar](40) NULL,
	[ASNRLENDER] [varchar](6) NULL,
	[ORIGMTG] [int] NULL,
	[ARCHIVEID] [int] NOT NULL,
	[OWNRID] [int] NOT NULL,
	[ASSRID] [int] NOT NULL,
	[BLDGID] [int] NOT NULL,
	[COMPLEVL] [varchar](1) NULL,
	[INACTVFL] [varchar](1) NULL,
	[OWNER2] [varchar](25) NULL,
	[OWNREL] [varchar](1) NULL,
	[RESOWNER] [varchar](1) NULL,
	[SALESRCE] [varchar](1) NULL,
	[LSTSLDATE] [date] NULL,
	[LSTSLPR] [int] NULL,
	[LSTSLVALID] [varchar](1) NULL,
	[LSTSLTYPE] [varchar](1) NULL,
	[LSTDDTYPE] [varchar](2) NULL,
	[LSTBOOK] [int] NULL,
	[LSTPAGE] [int] NULL,
	[LSTDOCREF] [varchar](12) NULL,
	[LSTMTGDATE] [date] NULL,
	[LSTMTG] [int] NULL,
	[LSTLDR] [varchar](6) NULL,
	[LSTMTGCAT] [varchar](4) NULL,
	[SUBMTGFLG] [varchar](1) NULL,
	[ASSDVALTOT] [int] NULL,
	[LSTINTTYPE] [varchar](1) NULL,
	[ASSDVALLND] [int] NULL,
	[LSTCHGDATE] [date] NULL,
	[ASSDVALBLD] [int] NULL,
	[LSTINTERST] [decimal](6, 3) NULL,
	[FY] [varchar](4) NULL,
	[LSTINTADJ] [decimal](6, 3) NULL,
	[TAXAMT] [int] NULL,
	[TAXYEAR] [varchar](4) NULL,
	[TAXDIST] [varchar](1) NULL,
	[ZONING] [varchar](6) NULL,
	[NUMBLDGS] [decimal](1, 0) NULL,
	[LOTSIZE] [decimal](10, 2) NULL,
	[LSUNITS] [varchar](1) NULL,
	[DPSTATDATE] [date] NULL,
	[DPSTATUS] [varchar](2) NULL,
	[LSTNOMDATE] [date] NULL,
	[LSTNOMBOOK] [int] NULL,
	[LSTNOMPAGE] [int] NULL,
	[LSTNOMDOCR] [varchar](11) NULL,
	[PREFCODE] [varchar](1) NULL,
	[SITESRCE] [varchar](1) NULL,
	[DPINID] [int] NOT NULL,
	[FSPUBDATE] [date] NULL,
	[REODATE] [date] NULL,
	[PUBNUMPF] [decimal](1, 0) NULL,
	[PUBNUMFS] [decimal](1, 0) NULL,
	[INITDATELN] [date] NULL,
	[PUBFS] [varchar](3) NULL,
	[PUBPF] [varchar](3) NULL,
	[ARDPID] [int] NOT NULL,
	[MERSVALID] [varchar](1) NULL,
	[MERSIND] [varchar](1) NULL,
	[BRR1ID] [varchar](2) NOT NULL,
	[BRR2ID] [varchar](2) NOT NULL,
	[DSPODATE] [date] NULL,
	[CONTRACTDT] [date] NULL,
	[ASNRSECID] [int] NOT NULL,
	[ASNESECID] [int] NOT NULL,
	[ASNRTRSTEE] [varchar](40) NULL,
	[ASNETRSTEE] [varchar](40) NULL,
	[RECLNAME] [varchar](21) NULL,
	[RTYPE] [varchar](1) NOT NULL,
	[NETFILE] [varchar](25) NOT NULL,
	[DSACCTN] [varchar](25) NULL,
	[LOANNUMBER] [varchar](25) NULL,
	[ASNEPOOLNM] [varchar](25) NULL,
	[MTGDSID] [int] NOT NULL,
	[VILLAGE] [varchar](25) NULL,
	[MAILADDR] [varchar](100) NULL,
	[NOIMAGE] [bit] NOT NULL,
	[RECNUMBER] [varchar](38) NOT NULL,
	[MAPBLLOT] [varchar](40) NOT NULL,
	[REPID] [varchar](10) NOT NULL,
	[SRCNETFILE] [varchar](25) NOT NULL,
	[ASSRSID] [int] NOT NULL,
	[ITEMDESC] [varchar](max) NULL,
	[BPMTID] [int] NOT NULL,
	[PERMITN] [varchar](25) NULL,
	[COST] [int] NULL,
	[CNAME] [varchar](25) NULL,
	[CNTMAILDDR] [varchar](60) NULL,
	[PERMTYPE] [varchar](2) NULL,
	[PNOTES] [varchar](249) NULL,
	[APPLICANT] [varchar](25) NULL,
	[PERMOWNER] [varchar](25) NULL,
	[PERMSFT] [int] NULL,
	[CPHONE] [varchar](12) NULL,
	[CSLIC] [varchar](10) NULL,
	[HICREG] [varchar](10) NULL,
	[CMAILCITY] [varchar](25) NULL,
	[CMAILSTATE] [varchar](2) NULL,
	[CMAILZIP] [varchar](10) NULL,
	[LSTSALEID] [int] NULL,
	[LSTMTGID] [int] NULL,
	[SECMTGID] [int] NULL,
	[LSTNOMIID] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]