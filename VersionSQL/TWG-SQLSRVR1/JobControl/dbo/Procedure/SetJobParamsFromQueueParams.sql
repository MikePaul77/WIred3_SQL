/****** Object:  Procedure [dbo].[SetJobParamsFromQueueParams]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE dbo.SetJobParamsFromQueueParams @JobLogID int
AS
BEGIN
	SET NOCOUNT ON;


	declare @QueueParam varchar(50)
	declare @JobID int
	declare @NextParam int

	select @QueueParam = jl.QueueJobParams
			, @JobID = jl.JobID
			, @NextParam = coalesce(j.NextParamTarget,0)
		from JobControl..JobLog jl
			join JobControl..Jobs j on j.Jobid = jl.JobID
		where jl.ID = @JobLogID

	update JobControl..Jobs set CurrParamTarget = @QueueParam where JobID = @JobID

	delete JobControl..JobParameters
		where JobID = @JobID

	declare @CalP varchar(10)
	declare @CalY varchar(10)

	if left(@QueueParam,2) = 'IW'
	begin
		insert JobControl..JobParameters (JobID, ParamName, ParamValue)
							values (@JobID, 'IssueWeek', replace(@QueueParam,'IW:',''))
		
	end
	if left(@QueueParam,2) = 'IM'
	begin
		insert JobControl..JobParameters (JobID, ParamName, ParamValue)
							values (@JobID, 'IssueMonth', replace(@QueueParam,'IM:',''))

	end
	if left(@QueueParam,2) = 'CM'
	begin

		set @CalP = substring(@QueueParam,4,2)
		set @CalY = substring(@QueueParam,6,4)

		insert JobControl..JobParameters (JobID, ParamName, ParamValue)
				values (@JobID, 'CalPeriod', @CalP)
				, (@JobID, 'CalYear', @CalY)

	end
	if left(@QueueParam,2) = 'BA'
	begin

		set @CalP = substring(@QueueParam,4,2)
		set @CalY = substring(@QueueParam,6,4)

		insert JobControl..JobParameters (JobID, ParamName, ParamValue)
				values (@JobID, 'CalPeriod', @CalP)
				, (@JobID, 'CalYear', @CalY)

	end
	if left(@QueueParam,2) = 'CQ'
	begin

		set @CalP = substring(@QueueParam,4,2)
		set @CalY = substring(@QueueParam,6,4)

		insert JobControl..JobParameters (JobID, ParamName, ParamValue)
				values (@JobID, 'CalPeriod', @CalP)
				, (@JobID, 'CalYear', @CalY)

	end
	if left(@QueueParam,2) = 'CA'
	begin

		set @CalP = substring(@QueueParam,4,2)
		set @CalY = substring(@QueueParam,6,4)

		insert JobControl..JobParameters (JobID, ParamName, ParamValue)
				values (@JobID, 'CalPeriod', @CalP)
				, (@JobID, 'CalYear', @CalY)

	end

	--Set New ParmTarget for Scheduling

    if JobControl.dbo.IsNextLogicalParam(@JobID, @QueueParam) = 1
    begin

        if left(@QueueParam,2) = 'IW'
        begin
            if isnumeric(replace(@QueueParam,'IW:','')) = 1
            Begin
                declare @CurIW int 
                set @CurIW = convert(int,replace(@QueueParam,'IW:',''))
                if @NextParam < @CurIW
                    Update JobControl..Jobs set NextParamTarget = @CurIW + 1 where JobID = @JobID
            end
        end

        if left(@QueueParam,2) in ('IM','CM')
        begin
            if isnumeric(replace(@QueueParam,'IM:','')) = 1 or isnumeric(replace(@QueueParam,'CM:','')) = 1
            Begin
                declare @CurIM int 
                declare @WorkIM varchar(20)
                declare @CalcQueueParam date
                declare @CalcNextParam varchar(20)

                set @WorkIM = substring(@QueueParam,6,4) + substring(@QueueParam,4,2)
                set @CurIM = convert(int,@WorkIM)

                set @CalcQueueParam = case when isdate(substring(@QueueParam,4,2) + '/1/' + substring(@QueueParam,6,4)) = 1
                                        then convert(date,substring(@QueueParam,4,2) + '/1/' + substring(@QueueParam,6,4))
                                        else null end
                
                if @CalcQueueParam is not null
                begin
                    set @CalcQueueParam = dateadd(mm,1,@CalcQueueParam)
                    set @CalcNextParam = Support.FuncLib.PadWithLeft(month(@CalcQueueParam),2,'0') + ltrim(str(year(@CalcQueueParam)))
                end

                if @NextParam < @CurIM
                    Update JobControl..Jobs set NextParamTarget = @CalcNextParam where JobID = @JobID
            end
        end

        if left(@QueueParam,2) in ('BA')
        begin
            if isnumeric(replace(@QueueParam,'BA:','')) = 1
            Begin
                declare @CurIM2 int 
                declare @WorkIM2 varchar(20)
                declare @CalcQueueParam2 date
                declare @CalcNextParam2 varchar(20)

                set @WorkIM2 = substring(@QueueParam,6,4) + substring(@QueueParam,4,2)
                set @CurIM2 = convert(int,@WorkIM2)

                set @CalcQueueParam2 = case when isdate(substring(@QueueParam,4,2) + '/1/' + substring(@QueueParam,6,4)) = 1
                                        then convert(date,substring(@QueueParam,4,2) + '/1/' + substring(@QueueParam,6,4))
                                        else null end

                if @CalcQueueParam2 is not null
                begin
                    set @CalcQueueParam2 = dateadd(mm,6,@CalcQueueParam2)
                    set @CalcNextParam2 = Support.FuncLib.PadWithLeft(month(@CalcQueueParam2),2,'0') + ltrim(str(year(@CalcQueueParam2)))
                end

                if @NextParam < @CurIM
                    Update JobControl..Jobs set NextParamTarget = @CalcNextParam2 where JobID = @JobID
            end
        end
    end
END
