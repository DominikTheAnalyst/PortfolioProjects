---
--- QUERY THE DATABASE OLYMPIC GAMES (athlete_events AND noc_regions)
---
SELECT *
FROM athlete_events
ORDER BY NOC ASC
---
SELECT *
FROM noc_regions
ORDER BY region DESC

----------------------------------------------------------------------
--- IDENTIFY SPORT WHICH WAS PLAYED IN ALL SUMMER OLYMPICS
----------------------------------------------------------------------

with 
T1 AS 
	(SELECT COUNT(DISTINCT Games) AS Total_Summer_Games
	FROM athlete_events
	WHERE Season = 'Summer'),
T2 AS 
	(SELECT  DISTINCT Sport, Games
	FROM athlete_events
	WHERE Season = 'Summer'),
T3 AS
	(SELECT Sport, COUNT(Games) AS no_of_games
	FROM T2 
	GROUP BY Sport
)
SELECT *
FROM T3
JOIN T1 ON T1.Total_Summer_Games = T3.no_of_games;	

-------------------------------------------------------------------------
--- FETCH THE TOP 5 ATHLETES WHO HAVE WON THE MOST GOLD MEDALS.
-------------------------------------------------------------------------

-- 1) Narrow Table to 'Gold' Medal
-- 2) Group the data based on name. How many each of them won Gold medals?
SELECT name, count(1) AS total_medals
FROM athlete_events
WHERE Medal = 'Gold'
GROUP BY Name
ORDER BY total_medals DESC;
-- 3) We can't take first 5 as some of them have the same amount of gold medals
-- 4) We need to Rank them, Dens_Rank
-- 5) We use WITH CLOSE 
WITH T1 AS
	(SELECT name, count(1) AS total_medals
	FROM athlete_events
	WHERE Medal = 'Gold'
	GROUP BY Name
	ORDER BY COUNT(1) DESC),
T2 AS 
	(SELECT *, RANK() OVER(ORDER BY total_medals DESC) AS RNK
	FROM T1)
SELECT *
FROM T2; ---- !!! syntax will not work with out closing ORDER BY
----------------
WITH T1 AS (
    SELECT name, COUNT(1) AS total_medals
    FROM athlete_events
    WHERE Medal = 'Gold'
    GROUP BY Name
),
T2 AS (
    SELECT *, RANK() OVER (ORDER BY total_medals DESC) AS RNK,
	DENSE_RANK() OVER (ORDER BY total_medals DESC) AS DRNK
    FROM T1
)
SELECT *
FROM T2
WHERE DRNK <= 5
ORDER BY DRNK;

-----------------------------------------------------------------------
--- LIST DOWN TOTAL GOLD, SILVER AND BRONZE MEDALS WON BY EACH COUNTRY.
-----------------------------------------------------------------------

-- 1) Column: Country, Gold, Silver, Bronze
-- 2) Join the table
-- 3) How many Total G, S, B medal: SUM each, and emlimintate NA
SELECT region AS Country, Medal, COUNT(1) AS Total_medals
FROM athlete_events AS AE
JOIN noc_regions AS NR ON AE.NOC = NR.NOC
WHERE Medal <> 'NA'
GROUP BY region, Medal
ORDER BY region, Medal;
-- 5) We need cross table - PivotTable operation
SELECT
    Country,
    ISNULL([Gold], 0) AS Gold,
    ISNULL([Silver], 0) AS Silver,
    ISNULL([Bronze], 0) AS Bronze
FROM
	(SELECT region AS Country, Medal, COUNT(1) AS Total_medals
    FROM athlete_events AS AE
    JOIN noc_regions AS NR ON AE.NOC = NR.NOC
    WHERE Medal <> 'NA'
    GROUP BY region, Medal
) AS SourceTable
PIVOT
	(SUM(Total_medals)
    FOR Medal IN ([Gold], [Silver], [Bronze])
	) AS PivotTable
ORDER BY Country;

-------------------------------------------------------
