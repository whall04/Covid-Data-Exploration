								-- Bellabeat Case Study --

--Preview activity dataset
SELECT TOP 10 *
FROM Bellabeat..baseDailyActivity
  

--Count total rows
SELECT COUNT(*)
FROM Bellabeat..baseDailyActivity


--Count number of unique IDs
SELECT COUNT(DISTINCT Id)
FROM Bellabeat..baseDailyActivity


--Check for duplicate rows
SELECT *, COUNT(*) AS numRow
FROM Bellabeat..baseDailyActivity
GROUP BY Id, ActivityDate, TotalSteps, TotalDistance, TrackerDistance, 
	LoggedActivitiesDistance, VeryActiveDistance, ModeratelyActiveDistance,
	LightActiveDistance, SedentaryActiveDistance, VeryActiveMinutes, FairlyActiveMinutes, LightlyActiveMinutes, SedentaryMinutes, Calories
HAVING COUNT(*) > 1


--Check for activity during each day
SELECT *
FROM Bellabeat..baseDailyActivity
WHERE TotalSteps < 1


--Count number of entries with activity per ID
SELECT ID, COUNT(*) AS num_entries
FROM (
	SELECT *
	FROM Bellabeat..baseDailyActivity
	WHERE TotalSteps > 1
	) sub
GROUP BY Id
ORDER BY 2


--Create Temp Table
--Remove IDs with few entries
--Add column calculating day of week
DROP TABLE IF EXISTS #functional_table;
WITH CTE_lowact AS(
SELECT ID, COUNT(*) AS num_entries
FROM (
	SELECT *
	FROM Bellabeat..baseDailyActivity
	WHERE TotalSteps > 1
	) sub
GROUP BY Id
)
SELECT id, ActivityDate, DATENAME(WEEKDAY, ActivityDate) AS day_of_week,
	TotalSteps, VeryActiveMinutes, FairlyActiveMinutes, 
	LightlyActiveMinutes, SedentaryMinutes, Calories
INTO #functional_table
FROM Bellabeat..baseDailyActivity
WHERE id in (
	SELECT ID
	FROM CTE_lowact
	WHERE num_entries > 20)


--Count total rows in temp table
SELECT COUNT(*)
FROM #functional_table


--Count unique IDs in Temp Table
SELECT COUNT(DISTINCT id)
FROM #functional_table


--Create new table containijng only active users 
--Inlude column for total activity time
DROP TABLE IF exists Bellabeat..DailyActivity;
WITH CTE_Total_Time AS
(
	SELECT Id, ActivityDate, SUM(VeryActiveMinutes + FairlyActiveMinutes + 
		LightlyActiveMinutes + SedentaryMinutes) AS TotalTime
	FROM #functional_table
	GROUP BY  ID, ActivityDate	
)
SELECT fun.Id, fun.activitydate, fun.day_of_week, fun.VeryActiveMinutes,
	fun.FairlyActiveMinutes, fun.LightlyActiveMinutes, fun.SedentaryMinutes,
	tt.TotalTime, fun.TotalSteps, fun.Calories
INTO Bellabeat..DailyActivity
FROM #functional_table AS fun
JOIN CTE_Total_Time AS tt
	ON fun.id = tt.id and fun.ActivityDate = tt.ActivityDate


--Preview new table
SELECT *
FROM Bellabeat..DailyActivity


--Create view for pie chart
CREATE VIEW pieChart AS
SELECT SUM(VeryActiveMinutes) AS totVAct, SUM(FairlyActiveMinutes) AS totFAct, SUM(LightlyActiveMinutes) AS totLAct, SUM(SedentaryMinutes) AS totSAct, SUM(TotalTime) AS totTime
FROM Bellabeat..DailyActivity


--Pivot columns for proper formatting
SELECT *
FROM   
   (SELECT totVAct, totFAct, totLAct, totSACT
   FROM pieChart) p  
UNPIVOT  
   (TimeSpent FOR Category IN   
      (totVAct, totFAct, totLAct, totSACT)  
)AS unpvt; 


--Calculate time device is worn 
SELECT id, ActivityDate, TotalTime, CAST((TotalTime/1440)*100 AS int) AS percent_day_worn 
FROM Bellabeat..DailyActivity


--Calculate average wearing habits by day of week per user
SELECT id, day_of_week, CAST(AVG(TotalTime) AS int) AS average_time_worn,
	CAST((AVG(TotalTime)/1440)*100 AS int) AS percent_day_worn 
FROM Bellabeat..DailyActivity
GROUP BY Id, day_of_week
ORDER BY 1,4 DESC


--Preview sleep dataset
SELECT *
FROM Bellabeat..baseSleepDay


--Count total rows
SELECT COUNT(*)
FROM Bellabeat..baseSleepDay


--Count number of unique IDs
SELECT COUNT(DISTINCT ID)
FROM Bellabeat..baseSleepDay


--Count number of unique IDs included in both data sets
SELECT COUNT(DISTINCT dai.ID)
FROM Bellabeat..DailyActivity dai
JOIN Bellabeat..baseSleepDay slp
	on dai.Id = slp.id AND ActivityDate=SleepDay


--Count number of entries for each ID included in both data sets
SELECT dai.ID, COUNT(*) AS num_entries
FROM Bellabeat..DailyActivity dai
JOIN Bellabeat..baseSleepDay slp
	on dai.Id = slp.id AND ActivityDate=SleepDay
GROUP BY dai.Id
HAVING COUNT(*) > 14
ORDER BY 2 


--Create new table by joining with activity table
--Remove users with fewer than 2 weeks of data
DROP TABLE IF EXISTS SleepDay;
WITH CTE_Sleep AS (
	SELECT dai.ID, COUNT(*) AS num_entries
	FROM Bellabeat..DailyActivity dai
	JOIN Bellabeat..baseSleepDay slp
		on dai.Id = slp.id AND ActivityDate=SleepDay
	GROUP BY dai.Id
	HAVING COUNT(*) > 14
	)
SELECT dai.ID, ActivityDate, day_of_week, VeryActiveMinutes, FairlyActiveMinutes,
	LightlyActiveMinutes, SedentaryMinutes, TotalTime, TotalSteps, Calories,
	TotalMinutesAsleep, TotalTimeInBed
INTO Bellabeat..SleepDay
FROM Bellabeat..DailyActivity dai
JOIN Bellabeat..baseSleepDay slp
	ON dai.id = slp.id AND activitydate = SleepDay
Where dai.ID in (
	SELECT ID
	FROM CTE_Sleep
	)
		
		
--Preview New Table	
Select * 
FROM Bellabeat..SleepDay


--Count rows in new table
Select COUNT(*) 
FROM Bellabeat..SleepDay
