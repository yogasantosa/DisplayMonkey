USE [DisplayMonkey]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Dashboard]    Script Date: 6/24/2014 6:05:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[sp_Get_Dashboard] as
/*
2014-06-05	MM	New object
				Proc returns dash board values
2014-06-24	MM	Limit top content to 50 char

exec sp_Get_Dashboard
*/
begin
set nocount on 

--- FRAMES ---------------------------------------
Declare @Number_of_Frames int, @Total_Duration_Hours decimal(5,2) 
select @Number_of_Frames = count(*), @Total_Duration_Hours = isnull(cast(sum([Duration])/3600.00 as decimal(5,2)), 0.00) from [dbo].[Frame] 

--- ACTIVE FRAMES ---------------------------------------
Declare @Number_of_Active_Frames int
select @Number_of_Active_Frames =  count(distinct t1.[FrameId]) 
from [dbo].[Frame] t1
inner join [dbo].[Panel] t2 on t1.[PanelId] = t2.[PanelId]
inner join [dbo].[Canvas] t3 on t2.[CanvasId] = t3.[CanvasId]
inner join [dbo].[Display] t4 on t4.[CanvasId] = t3.[CanvasId]
where 
(t1.[BeginsOn] > getdate() or t1.[BeginsOn] is null) and
(t1.[EndsOn] < getdate() or t1.[EndsOn] is null) 

--- FRAMES BY CONTENT TYPE ----------------------------------
declare @Number_of_Memos int, @Number_of_Memos_7 int, @Number_of_Pictures int, @Number_of_Pictures_7 int,  @Number_of_Reports int, @Number_of_Reports_7 int
		, @Number_of_Videos int, @Number_of_Videos_7 int
declare @tmp_Frames_by_Type table (Added_Last_7_Days int, Number_of_Memos_in_Frame int, Number_of_Pictures_in_Frame int, Number_of_Reports_in_Frame int
									, Number_of_Videos_in_Frame int)

insert @tmp_Frames_by_Type (Added_Last_7_Days, Number_of_Memos_in_Frame, Number_of_Pictures_in_Frame, Number_of_Reports_in_Frame, Number_of_Videos_in_Frame)
select
 Added_Last_7_Days
,sum(Number_of_Memos) Number_of_Memos_in_Frame
,sum(Number_of_Pictures) Number_of_Pictures_in_Frame
,sum(Number_of_Reports) Number_of_Reports_in_Frame
,sum(Number_of_Videos) Number_of_Videos_in_Frame
from
	(
	select 
	 case when t2.[FrameId] is not null then 1 else 0 end as Number_of_Memos
	,case when t3.[FrameId] is not null then 1 else 0 end as Number_of_Pictures
	,case when t4.[FrameId] is not null then 1 else 0 end as Number_of_Reports
	,case when t5.[FrameId] is not null then 1 else 0 end as Number_of_Videos
	,case when t1.[DateCreated] > getdate()-7 then 1 else 0 end Added_Last_7_Days
	from [dbo].[Frame] t1
	left join [dbo].[Memo] t2 on t1.[FrameId] = t2.[FrameId]
	left join [dbo].[Picture] t3 on t1.[FrameId] = t3.[FrameId]
	left join [dbo].[Report] t4 on t1.[FrameId] = t4.[FrameId]
	left join [dbo].[Video] t5 on t1.[FrameId] = t5.[FrameId]
	) s1
group by Added_Last_7_Days

-- set values for last 7 days -----------------------------------------------
select @Number_of_Memos_7 = Number_of_Memos_in_Frame, @Number_of_Pictures_7 = Number_of_Pictures_in_Frame, @Number_of_Reports_7 = Number_of_Reports_in_Frame
		, @Number_of_Videos_7 = Number_of_Videos_in_Frame
from @tmp_Frames_by_Type where Added_Last_7_Days = 1

select @Number_of_Memos_7 = isnull(@Number_of_Memos_7, 0), @Number_of_Pictures_7 = isnull(@Number_of_Pictures_7, 0), @Number_of_Reports_7 = isnull(@Number_of_Reports_7, 0)
		,@Number_of_Videos_7 = isnull(@Number_of_Videos_7, 0)

-- set values for all time ---------------------------------------------
select @Number_of_Memos = Number_of_Memos_in_Frame, @Number_of_Pictures = Number_of_Pictures_in_Frame, @Number_of_Reports = Number_of_Reports_in_Frame
		, @Number_of_Videos = Number_of_Videos_in_Frame
from @tmp_Frames_by_Type where Added_Last_7_Days = 0

select @Number_of_Memos = isnull(@Number_of_Memos, 0) + @Number_of_Memos_7, @Number_of_Pictures = isnull(@Number_of_Pictures, 0) + @Number_of_Pictures_7
		,@Number_of_Reports = isnull(@Number_of_Reports, 0) + @Number_of_Reports_7, @Number_of_Videos = isnull(@Number_of_Videos, 0) + @Number_of_Videos_7

--- TOP CONTENT ----------------------------------
declare @Top_Content_1 nvarchar(200), @Top_Content_2 nvarchar(200), @Top_Content_3 nvarchar(200), @Top_Content_4 nvarchar(200), @Top_Content_5 nvarchar(200),
		@Top_Content_1_Count int, @Top_Content_2_Count int, @Top_Content_3_Count int, @Top_Content_4_Count int, @Top_Content_5_Count int
declare @tmp_Top_Content table (ID int identity(1,1),Content_Name nvarchar(200), Content_Count int)

insert @tmp_Top_Content (Content_Name, Content_Count) 
select top 5
Content_Name
,sum(Content_Count) Content_Count
from
	(
	select 
	case 
	when t5.[Subject] is not null then t5.[Subject]
	when t6.[ContentId] is not null then t9.[Name]
	when t8.[ContentId] is not null then t10.[Name]
	when t7.[Name] is not null then t7.[Name] end Content_Name
	,1 Content_Count
	from [dbo].[Frame] t1
	inner join [dbo].[Panel] t2 on t1.[PanelId] = t2.[PanelId]
	inner join [dbo].[Canvas] t3 on t2.[CanvasId] = t3.[CanvasId]
	inner join [dbo].[Display] t4 on t4.[CanvasId] = t3.[CanvasId]
	left join [dbo].[Memo] t5 on t1.[FrameId] = t5.[FrameId]
	left join [dbo].[Picture] t6 on t1.[FrameId] = t6.[FrameId]
	left join [dbo].[Report] t7 on t1.[FrameId] = t7.[FrameId]
	left join [dbo].[VideoAlternative] t8 on t1.[FrameId] = t8.[FrameId]
	left join [dbo].[Content] t9 on t6.ContentId = t9.ContentId 
	left join [dbo].[Content] t10 on t8.ContentId = t10.ContentId
	where 
	(t1.[BeginsOn] > getdate() or t1.[BeginsOn] is null) and
	(t1.[EndsOn] < getdate() or t1.[EndsOn] is null) 
	) s1
group by Content_Name
order by Content_Count desc

select @Top_Content_1 = case when len(Content_Name) > 50 then left(Content_Name, 47) + '...' else Content_Name end , @Top_Content_1_Count = Content_Count from @tmp_Top_Content where ID = 1
select @Top_Content_2 = case when len(Content_Name) > 50 then left(Content_Name, 47) + '...' else Content_Name end, @Top_Content_2_Count = Content_Count from @tmp_Top_Content where ID = 2
select @Top_Content_3 = case when len(Content_Name) > 50 then left(Content_Name, 47) + '...' else Content_Name end, @Top_Content_3_Count = Content_Count from @tmp_Top_Content where ID = 3
select @Top_Content_4 = case when len(Content_Name) > 50 then left(Content_Name, 47) + '...' else Content_Name end, @Top_Content_4_Count = Content_Count from @tmp_Top_Content where ID = 4
select @Top_Content_5 = case when len(Content_Name) > 50 then left(Content_Name, 47) + '...' else Content_Name end, @Top_Content_5_Count = Content_Count from @tmp_Top_Content where ID = 5

select @Top_Content_1 = isnull(@Top_Content_1, ''), @Top_Content_2 = isnull(@Top_Content_2, ''), @Top_Content_3 = isnull(@Top_Content_3, ''), 
		@Top_Content_4 = isnull(@Top_Content_4, ''), @Top_Content_5 = isnull(@Top_Content_5, '')

--- LEVELS ----------------------------------
declare @Levels int		
select @Levels = count(*) from [dbo].[Level]

--- LOCATION ----------------------------------
declare @Location int		
select @Location = count(*) from [dbo].[Location]

--- CANVAS ----------------------------------
declare @Canvas int		
select @Canvas =  count(*) from [dbo].[Canvas]

--- PANEL ----------------------------------
declare @Panel int		
select @Panel = count(*) from [dbo].[Panel]

--- DISPLAYS ----------------------------------
declare @Display int		
select @Display = count(*) from [dbo].[Display]

--- RETURN VALUES -------------------------
select 
 @Number_of_Frames as Number_of_Frames -- Integer
,@Total_Duration_Hours as Total_Duration_Hours -- Decimal(5,2)
,@Number_of_Active_Frames as Number_of_Active_Frames -- Integer
,@Number_of_Memos as Number_of_Memos -- Integer
,@Number_of_Memos_7 as Number_of_Memos_7 -- Integer
,@Number_of_Pictures as Number_of_Pictures -- Integer
,@Number_of_Pictures_7 as Number_of_Pictures_7 -- Integer
,@Number_of_Reports as Number_of_Reports -- Integer
,@Number_of_Reports_7 as Number_of_Reports_7 -- Integer
,@Number_of_Videos as Number_of_Videos -- Integer
,@Number_of_Videos_7 as Number_of_Videos_7 -- Integer
,@Top_Content_1 as Top_Content_1 -- nvarchar(200) limited to 50 char
,@Top_Content_2 as Top_Content_2 -- nvarchar(200) limited to 50 char
,@Top_Content_3 as Top_Content_3 -- nvarchar(200) limited to 50 char
,@Top_Content_4 as Top_Content_4 -- nvarchar(200) limited to 50 char
,@Top_Content_5 as Top_Content_5 -- nvarchar(200) limited to 50 char
,@Top_Content_1_Count as Top_Content_1_Count -- Integer
,@Top_Content_2_Count as Top_Content_2_Count -- Integer
,@Top_Content_3_Count as Top_Content_3_Count -- Integer
,@Top_Content_4_Count as Top_Content_4_Count -- Integer
,@Top_Content_5_Count as Top_Content_5_Count -- Integer
,@Levels as Levels -- Integer
,@Location as Location -- Integer
,@Canvas as Canvas -- Integer
,@Panel as Panel -- Integer
,@Display as Display -- Integer
end