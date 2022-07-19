--Preview dataset
select TOP 10 *
from Bellabeat..baseDailyActivity
	   

--Count total rows in dataset
select count(*)
from Bellabeat..baseDailyActivity


--Count number of unique IDs in dataset
select count(distinct Id)
from Bellabeat..baseDailyActivity


--Count number of entries per ID
select ID, count(*) as num_entries
from Bellabeat..baseDailyActivity
group by Id
order by 2


--Create Temp Table
--Remove IDs with few entries
--Add column calculating day of week
drop table if exists #functional_table
select id, ActivityDate, datename(weekday, ActivityDate) as day_of_week,
	TotalSteps, VeryActiveMinutes, FairlyActiveMinutes, 
	LightlyActiveMinutes, SedentaryMinutes, Calories
Into #functional_table
from Bellabeat..baseDailyActivity
where id not in (4057192912,2347167796,8253242879,3372868164)


--Count total rows in temp table
select count(*)
from #functional_table


--Count unique IDs in Temp Table
select count(distinct id)
from #functional_table


--
Drop table if exists Bellabeat..DailyActivity;
WITH CTE_Total_Time as
(
	select Id, ActivityDate, sum(VeryActiveMinutes + FairlyActiveMinutes + 
		LightlyActiveMinutes + SedentaryMinutes) as total_recorded_time
	from #functional_table
	group by  ID, ActivityDate	
)
select fun.Id, fun.activitydate, fun.day_of_week, fun.VeryActiveMinutes,
	fun.FairlyActiveMinutes, fun.LightlyActiveMinutes, fun.SedentaryMinutes,
	tt.total_recorded_time, fun.TotalSteps, fun.Calories
INTO Bellabeat..DailyActivity
from #functional_table as fun
join CTE_Total_Time as tt
	on fun.id = tt.id and fun.ActivityDate = tt.ActivityDate


select *
from Bellabeat..DailyActivity


select id, ActivityDate, total_recorded_time, cast((total_recorded_time/1440)*100 as int) as percent_day_worn 
from Bellabeat..DailyActivity


select id, day_of_week, cast(avg(total_recorded_time) as int) as average_time_worn,
	cast((avg(total_recorded_time)/1440)*100 as int) as percent_day_worn 
from Bellabeat..DailyActivity
group by Id, day_of_week
order by 1,4 desc


select day_of_week, cast(avg(total_recorded_time) as int) as average_time_worn,
	cast((avg(total_recorded_time)/1440)*100 as int) as percent_day_worn 
from Bellabeat..DailyActivity
group by day_of_week
order by 3 desc


select id, cast(avg(total_recorded_time) as int) as average_time_worn,
	cast((avg(total_recorded_time)/1440)*100 as int) as percent_day_worn 
from Bellabeat..DailyActivity
group by Id
order by 3 desc

	   




