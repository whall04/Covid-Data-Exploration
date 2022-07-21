
																							--------------------------
																							-- Bellabeat Case Study --
																							--------------------------


-------------------
-- Data Cleaning --
-------------------


-- Preview activity dataset
SELECT TOP 100 *
FROM Bellabeat..baseDailyActivity;


-- Check for duplicate rows
SELECT *, COUNT(*) AS numRow
FROM Bellabeat..baseDailyActivity
GROUP BY Id, ActivityDate, TotalSteps, TotalDistance, TrackerDistance, 
	LoggedActivitiesDistance, VeryActiveDistance, ModeratelyActiveDistance,
	LightActiveDistance, SedentaryActiveDistance, VeryActiveMinutes, FairlyActiveMinutes, LightlyActiveMinutes, SedentaryMinutes, Calories
HAVING COUNT(*) > 1;
-- No duplicate rows found 


-- Check for NULL values
SELECT *
FROM Bellabeat..baseDailyActivity
WHERE ID is null OR  ActivityDate is null OR TotalSteps is null OR TotalDistance is null OR 
	TrackerDistance is null OR LoggedActivitiesDistance is null OR VeryActiveDistance is null OR
	ModeratelyActiveDistance is null OR LightActiveDistance is null OR SedentaryActiveDistance is null OR 
	VeryActiveMinutes is null OR FairlyActiveMinutes is null OR LightlyActiveMinutes is null OR
	SedentaryMinutes is null OR Calories is null;
-- No NULL values found


-- Count total rows
SELECT COUNT(*)	as TotalRows
FROM Bellabeat..baseDailyActivity;
-- 940 total rows 


-- Count unique user IDs
SELECT COUNT(DISTINCT Id) AS TotalUsers
from Bellabeat..baseDailyActivity;
-- 33 unique user IDs found


-- Verify user ID concistency
select distinct idLength, count(idlength)
from (Select id, len(Id) as idLength
	from Bellabeat..baseDailyActivity
	) sub
group by idLength;
-- 909 entries with 12 characters; 31 entries with 11. Review of data shows only 10 characters in ID


-- Check for and remove any extra space from IDs
with CTE_Trim as (
Select ID, trimID, len(trimID) as idlength
from (
	select ID, TRIM(str(ID)) as trimID 
	from Bellabeat..baseDailyActivity
	) sub )
select distinct idlength
from cte_trim;
-- IDs have extra spaces. These will be removed during creation of clean table


-- Count total number of days
SELECT COUNT(DISTINCT ActivityDate) AS Duration
FROM Bellabeat..baseDailyActivity;
-- 31 DAYS TOTAL

-- Find start and end dates
SELECT MIN(ActivityDate) AS StartDate, MAX(ActivityDate) AS EndDate
FROM Bellabeat..baseDailyActivity;
-- Start Date: 4/12/2016	End Date: 5/12/2016


-- Check for activity during each day
SELECT *
FROM Bellabeat..baseDailyActivity
WHERE TotalSteps < 1;
-- 77 entries with no recorded steps. These entries will be removed during creation of clean table


-- Count number of entries with activity per ID
SELECT ID, COUNT(*) AS num_entries
FROM (
	SELECT *
	FROM Bellabeat..baseDailyActivity
	WHERE TotalSteps > 1
	) sub
GROUP BY Id
ORDER BY 2;
-- 8 users have less than 3 weeks of activity data. These will be removed during creation of clean table


-- Create Temp Table
-- Remove IDs with few entries or no steps
-- Add column calculating day of week
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
SELECT TRIM(STR(Id)) AS Id, CAST(ActivityDate AS date) AS ActivityDate, DATENAME(WEEKDAY, ActivityDate) AS day_of_week,
	TotalSteps, VeryActiveMinutes, FairlyActiveMinutes, 
	LightlyActiveMinutes, SedentaryMinutes, Calories
INTO #functional_table
FROM Bellabeat..baseDailyActivity
WHERE id in (
	SELECT ID
	FROM CTE_lowact
	WHERE num_entries > 20)
	AND TotalSteps > 1;


-- Count total rows in temp table
SELECT COUNT(*)
FROM #functional_table;
-- 206 Rows removed due to insufficient data samples


--Create new table containijng only active users and cleaned data 
--Inlude column for total activity time
DROP TABLE IF exists Bellabeat..DailyActivity;
WITH CTE_Total_Time AS
(
	SELECT Id, ActivityDate, SUM(VeryActiveMinutes + FairlyActiveMinutes + 
		LightlyActiveMinutes + SedentaryMinutes) AS TotalTime
	FROM #functional_table
	GROUP BY  ID, ActivityDate	
)
SELECT TRIM(STR(fun.Id)) AS Id, CAST(fun.activitydate AS DATE) as ActivityDate, fun.day_of_week, fun.VeryActiveMinutes,
	fun.FairlyActiveMinutes, fun.LightlyActiveMinutes, fun.SedentaryMinutes,
	tt.TotalTime, fun.TotalSteps, fun.Calories
INTO Bellabeat..DailyActivity
FROM #functional_table AS fun
JOIN CTE_Total_Time AS tt
	ON fun.id = tt.id and fun.ActivityDate = tt.ActivityDate;
-- IDs trimmed to 10 characters. ActivityDate converted to date format


-- Preview new table
SELECT TOP 100 *
FROM Bellabeat..DailyActivity;
-- This data is ready for analysis 


-- Preview sleep data set --
SELECT TOP 100 *
FROM Bellabeat..baseSleepDay;


-- Check for duplicate rows
SELECT *, COUNT(*) AS numRow
FROM Bellabeat..baseSleepDay
GROUP BY Id, SleepDay, TotalSleepRecords, TotalMinutesAsleep, TotalTimeInBed
HAVING COUNT(*) > 1;
-- 3 duplicate rows found 


-- Remove Duplicates 
WITH DUPE_CTE AS (
Select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ID, Sleepday, TotalSleepRecords, TotalMinutesAsleep, TotalTimeInBed
				 ORDER BY
					ID
					) row_num
FROM Bellabeat..baseSleepDay
)
DELETE 
FROM DUPE_CTE
WHERE row_num > 1;


-- Check for NULL values
SELECT *
FROM Bellabeat..baseSleepDay
WHERE  ID IS NULL OR Sleepday IS NULL OR TotalSleepRecords IS NULL OR TotalMinutesAsleep IS NULL OR TotalTimeInBed IS NULL;
-- No NULL values found


-- Count total rows
SELECT COUNT(*)
FROM Bellabeat..baseSleepDay;
-- 410 total rows


-- Count total number of days
SELECT COUNT(DISTINCT SleepDay) AS Duration
FROM Bellabeat..baseSleepDay;
-- 31 DAYS TOTAL


-- Find start and end dates
SELECT MIN(SleepDay) AS StartDate, MAX(SleepDay) AS EndDate
FROM Bellabeat..baseSleepDay;
-- Start Date: 4/12/2016	End Date: 5/12/2016


-- Count number of unique IDs
SELECT COUNT(DISTINCT ID)
FROM Bellabeat..baseSleepDay;
-- 24 unique user IDs found


-- Verify user ID consistency
select distinct idLength, count(idlength)
from (Select id, len(Id) as idLength
	from Bellabeat..baseSleepDay
	) sub
group by idLength;
-- All IDs have 10 characters

-- Count number of unique IDs included in both data sets
SELECT COUNT(DISTINCT dai.ID)
FROM Bellabeat..DailyActivity dai
JOIN Bellabeat..baseSleepDay slp
	on dai.Id = slp.id AND ActivityDate=SleepDay;
-- 19 users have data recorded in both data sets


--Count number of entries for each ID included in both data sets
SELECT dai.ID, COUNT(*) AS num_entries
FROM Bellabeat..DailyActivity dai
JOIN Bellabeat..baseSleepDay slp
	on dai.Id = slp.id AND ActivityDate=SleepDay
GROUP BY dai.Id
ORDER BY 2; 
-- 6 users have less than a week of data. These will be removed when creating clean table


--Create new table by joining with activity table
--Remove users with fewer than 2 weeks of data
DROP TABLE IF EXISTS Bellabeat..SleepDay;
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
	);


-- Preview new table
SELECT TOP 100 *
FROM Bellabeat..SleepDay
-- This data is ready for analysis




-------------------
-- Data Analysis --
-------------------


-- Calculate average steps per day
SELECT day_of_week, CAST(AVG(TotalSteps) AS int) AS AvgSteps
FROM Bellabeat..DailyActivity
GROUP BY day_of_week
ORDER BY 2 DESC;


-- Comparing active and sedentary time each day
SELECT day_of_week, CAST(AVG(VeryActiveMinutes) AS int) AS AvgActiveTime, CAST(AVG(SedentaryMinutes) AS int) AS SedentaryTime
FROM Bellabeat..DailyActivity
GROUP BY day_of_week;


--Calculate time device is worn each day
SELECT day_of_week, CAST(AVG(TotalTime) AS INT) AS TotalTime, CAST((AVG(TotalTime)/1440)*100 AS int) AS percent_day_worn 
FROM Bellabeat..DailyActivity
GROUP BY day_of_week
ORDER BY 3 DESC;


-- Compare usage to calories burned by user
SELECT Id, ActivityDate, TotalTime, CAST(TotalTime/1440*100 AS int) As PercentDayWorn, Calories
FROM Bellabeat..DailyActivity
ORDER BY 1, 2;


-- Compare daily usage to calories burned per user
SELECT id, CAST(AVG(TotalTime) AS int) AS average_time_worn,
	CAST((AVG(TotalTime)/1440)*100 AS int) AS percent_day_worn,
	CAST(AVG(Calories) AS int) AS average_calories_burned
FROM Bellabeat..DailyActivity
GROUP BY Id
ORDER BY 4 DESC;


-- Calculate average sedentary time when not in bed
WITH DIF_CTE AS (
	SELECT CAST(AVG(SedentaryMinutes) AS int) AS AvgSed, CAST(AVG(TotalTimeInBed) AS int) AvgBed
	FROM Bellabeat..SleepDay
	)
Select SUM(AvgSed - AvgBed) AS RealSedentary 
FROM DIF_CTE;


-- Calculate average sedentary time when not in bed by day
WITH DIF_CTE AS (
	SELECT day_of_week, CAST(AVG(SedentaryMinutes) AS int) AS AvgSed, CAST(AVG(TotalTimeInBed) AS int) AvgBed
	FROM Bellabeat..SleepDay
	GROUP BY day_of_week)
Select day_of_week, SUM(AvgSed - AvgBed) AS RealSedentary 
FROM DIF_CTE
GROUP BY day_of_week;


--Calculate time spent per activity on average (excludes sleep from sedentary time)
CREATE VIEW pieChart AS
WITH DIF_CTE AS (
	SELECT CAST(AVG(VeryActiveMinutes) AS int) AS AvgVAct, CAST(AVG(FairlyActiveMinutes) AS int) AS AvgFAct, CAST(AVG(LightlyActiveMinutes) AS int) AS AvgLAct, CAST(AVG(SedentaryMinutes) AS int) AS AvgSed, CAST(AVG(TotalTimeInBed) AS int) AvgBed
	FROM Bellabeat..SleepDay
	)
Select AvgVAct, AvgFAct, AvgLAct, SUM(AvgSed - AvgBed) AS RealSedentary 
FROM DIF_CTE
GROUP BY AvgVAct, AvgFAct, AvgLAct;


--Pivot columns for proper formatting
SELECT *
FROM   
   (SELECT AvgVAct, AvgFAct, AvgLAct, RealSedentary
   FROM pieChart) p  
UNPIVOT  
   (TimeSpent FOR Category IN   
      (AvgVAct, AvgFAct, AvgLAct, RealSedentary)  
)AS unpvt; 


-- Calculate average time to fall asleep each day
SELECT day_of_week, SUM(TotalTimeInBed - TotalMinutesAsleep) AS AwakeInBed
FROM (
	SELECT day_of_week, CAST(AVG(TotalTimeInBed) AS int) AS TotalTimeInBed, CAST(AVG(TotalMinutesAsleep) AS int) AS TotalMinutesAsleep
	FROM Bellabeat..SleepDay
	GROUP BY day_of_week
	) sub
GROUP BY day_of_week
ORDER BY 2 DESC;


-- Compare active and sedentary time to total sleep
SELECT VeryActiveMinutes, SedentaryMinutes, TotalMinutesAsleep
FROM Bellabeat..SleepDay
ORDER BY 3 DESC;


-- Compare total steps to calories burned
SELECT TotalSteps, Calories
FROM Bellabeat..DailyActivity
ORDER BY 2 DESC;


-- Look at all activity types and calories burned
SELECT VeryActiveMinutes, FairlyActiveMinutes, LightlyActiveMinutes, SedentaryMinutes, Calories
FROM Bellabeat..DailyActivity
ORDER BY 5 DESC;


-- Compare total active time to calories burned
SELECT SUM(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) AS ActiveTime, Calories
FROM Bellabeat..DailyActivity
GROUP BY Calories
ORDER BY 2 DESC;

