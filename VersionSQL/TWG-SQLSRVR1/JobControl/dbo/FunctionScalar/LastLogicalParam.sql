/****** Object:  ScalarFunction [dbo].[LastLogicalParam]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION dbo.LastLogicalParam
(
	@JobID int
)
RETURNS varchar(50)
AS
BEGIN
	DECLARE @Result varchar(50)

    select @Result = x.OrderParam
        from (
        select jl.JobID, jl.QueueJobParams, jl.JobParameters
                , case when left(jl.QueueJobParams,3) = 'CA:' then try_convert(int,right(jl.QueueJobParams,4)) * 100 + 13
                        when left(jl.QueueJobParams,3) = 'CM:' then try_convert(int,right(jl.QueueJobParams,4)) * 100 + try_convert(int,substring(jl.QueueJobParams,4,2))
                        when left(jl.QueueJobParams,3) in ('IW:','IM:') then try_convert(int,right(jl.QueueJobParams,6))
                        else -1 end OrderParam
                , ParamSeq = ROW_NUMBER() OVER (PARTITION BY Jl.jobID ORDER BY case when left(jl.QueueJobParams,3) = 'CA:' then try_convert(int,right(jl.QueueJobParams,4)) * 100 + 13
                        when left(jl.QueueJobParams,3) = 'CM:' then try_convert(int,right(jl.QueueJobParams,4)) * 100 + try_convert(int,substring(jl.QueueJobParams,4,2))
                        when left(jl.QueueJobParams,3) in ('IW:','IM:') then try_convert(int,right(jl.QueueJobParams,6))
                        else -1 end desc)
            from JobControl..JobLog jl
            where jl.JobID = @JobID
                    and jl.CancelTime is null and jl.StartTime is not null
                    and jl.QueueJobParams > ''
        ) x 
    where x.ParamSeq = 1
   
    RETURN @Result

END
