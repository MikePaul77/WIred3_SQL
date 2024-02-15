/****** Object:  Procedure [dbo].[GetJobStepLog]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.GetJobStepLog @jobID int, @DaysFilter int, @DeliveryOnly bit, @HideAudits bit, @ErrorsOnly bit
AS
BEGIN
		select * 
			from (
				SELECT LogStamp LogStamp
					,coalesce(LogInformation,'') Detail
					,case when LogInfoType = 1 then 'Info'
						when LogInfoType = 2 then 'Caution'
						when LogInfoType = 3 then 'Error'
						else 'Unknown' end [Type]
					,isnull(LogInfoSource,'') Source
					, LogRecID
					, LogInfoType
                FROM JobControl.dbo.JobStepLogHist
                where JobID = @jobID
					and case when @DaysFilter > 0 and LogStamp >= DATEADD(day, @DaysFilter * -1, GETDATE()) then 1
						when @DaysFilter = 0 then 1 else 0 end = 1

			union
              select dl.DeliveryTime LogStamp
                    ,  dd.DestType + ' was sent to | ' + dd.DestAddress + coalesce(dd.FTPPath,'') + ' | ' + dm.FileName + ' | DocID: ' + ltrim(STR(dm.DocumentID)) InformationDetail
                    , 'Info' Type
                    , 'Delivery Log' Source
                    , dl.ID LogRecID
                    , null
                from JobControl..DistributionLog2 dl
                    join DocumentLibrary..DocumentMaster dm on dm.DocumentID = dl.DocumentID
                    join JobControl..DeliveryDests dd on dd.id like dl.DistributionDestID
                where dl.JobID = @jobid
					and case when @DaysFilter > 0 and dl.DeliveryTime >= DATEADD(day, @DaysFilter * -1, GETDATE()) then 1
						when @DaysFilter = 0 then 1 else 0 end = 1
			) x
				where 
				case when @DaysFilter > 0 and LogStamp >= DATEADD(day, @DaysFilter * -1, GETDATE()) then 1
						when @DaysFilter = 0 then 1 else 0 end = 1
				and case when @DeliveryOnly = 1 and Source like 'Deliver%' then 1
					when @DeliveryOnly = 0 then 1 else 0 end = 1
				and case when @HideAudits = 1 and Source not like 'Audit%' then 1 
						when @HideAudits = 0 then 1 else 0 end = 1
				and case when @ErrorsOnly = 1 and LogInfoType = 3 then 1 
					when @ErrorsOnly = 0 then 1 else 0 end = 1
	            order by LogStamp desc


	--SET NOCOUNT ON;
	--select * from 
	--			(SELECT LogStamp LogStamp
	--				,coalesce(LogInformation,'') Detail
	--				,case when LogInfoType = 1 then 'Info'
	--					when LogInfoType = 2 then 'Caution'
	--					when LogInfoType = 3 then 'Error'
	--					else 'Unknown' end [Type]
	--				,isnull(LogInfoSource,'') Source
	--				, LogRecID
	--				, LogInfoType
 --               FROM JobControl.dbo.JobStepLogHist
 --               where JobID = @jobID

 --    --               union
 --    --           SELECT LogStamp LogStamp
	--				--,coalesce(LogInformation,'') Detail
	--				--	,case when LogInfoType = 1 then 'Info'
	--				--	when LogInfoType = 2 then 'Caution'
	--				--	when LogInfoType = 3 then 'Error'
	--				--	else 'Unknown' end [Type]
	--				--,isnull(LogInfoSource,'') Source
	--				--, LogRecID
	--				--, null
 --    --           FROM JobControl.dbo.JobStepLog
 --    --           where JobID = @jobID

	--			union
 --             select dl.DeliveryTime LogStamp
 --                   ,  dd.DestType + ' was sent to | ' + dd.DestAddress + coalesce(dd.FTPPath,'') + ' | ' + dm.FileName + ' | DocID: ' + ltrim(STR(dm.DocumentID)) InformationDetail
 --                   , 'Info' Type
 --                   , 'Delivery Log' Source
 --                   , dl.ID LogRecID
 --                   , null
 --               from JobControl..DistributionLog2 dl
 --                   join DocumentLibrary..DocumentMaster dm on dm.DocumentID = dl.DocumentID
 --                   join JobControl..DeliveryDests dd on dd.id like dl.DistributionDestID
 --               where dl.JobID = @jobid
	--				and case when @DaysFilter > 0 and dl.DeliveryTime >= DATEADD(day, @DaysFilter * -1, GETDATE()) then 1
	--					when @DaysFilter = 0 then 1 else 0 end = 1
	--		) x
	--			where 
	--			case when @DaysFilter > 0 and LogStamp >= DATEADD(day, @DaysFilter * -1, GETDATE()) then 1
	--					when @DaysFilter = 0 then 1 else 0 end = 1
	--			--and case when @DeliveryOnly = 1 and Source like 'Deliver%' then 1
	--			--	when @DeliveryOnly = 0 then 1 else 0 end = 1
	--			--and case when @HideAudits = 1 and Source not like 'Audit%' then 1 
	--			--		when @HideAudits = 0 then 1 else 0 end = 1
	--			--and case when @ErrorsOnly = 1 and LogInfoType = 3 then 1 
	--			--	when @ErrorsOnly = 0 then 1 else 0 end = 1
				
 --               order by LogStamp desc
 
END
