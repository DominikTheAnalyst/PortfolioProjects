-- Quick view for data in Excel. 
-- Upload files into SQL smss via Import and Export wizard flat file with adjusting the column Data_Type
-- Quick view for both Tables we are going to work with
SELECT * 
FROM covidDeaths
--
SELECT *
FROM covidVaccination
-- Removing the continent from PortfolioProject
SELECT *
FROM PortfolioProject..covidDeaths
WHERE continent is not null -- We need to add this to every script
ORDER BY 3, 4
-- Checking the column DATA_TYPE for covidDeaths
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_NAME = 'covidDeaths'; 
-- Checking the column DATA_TYPE for covidVaccination
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_NAME = 'covidVaccination'; 
-- Create Database Diagrams for both Tables for visualisation purpuse
-- Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covidDeaths
WHERE continent is not null
ORDER BY 1,2;

--- Looking at Total Cases vs Total Deaths
--- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 as DeathPercentage
FROM covidDeaths
WHERE location LIKE '%United Kingdom%'
ORDER BY 1, 2;

-- Looking the Total Cases vs Population 
-- Shows what percentage of population got Covid
SELECT location, date, population, total_cases, (total_cases/population) * 100 as PopulationPercentageInfected
FROM covidDeaths
WHERE location LIKE '%United Kingdom%'
ORDER BY 1, 2;

-- Looking for countries with Highest Infection Rate compared to Population
SELECT location, Population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PopulationPercentageInfected
FROM covidDeaths
GROUP BY location, population
ORDER BY 4 DESC

-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) AS TotalDeathsCount
FROM covidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathsCount DESC

-- Let's break things down by continent (using location and where continent is null)
-- Seems to be very accurate

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM covidDeaths
WHERE continent is null
GROUP BY location
ORDER BY 1, TotalDeathCount desc

-- The same statement as above just with Continent
-- Showing the continents with the highest death count per population
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM covidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

--- Global numbers (monthly by Continent and Income)
SELECT 
    DATEFROMPARTS(YEAR(date), MONTH(date), 1) AS month,
    SUM(new_cases) AS total_new_cases,
    location
FROM 
    covidDeaths
WHERE 
    continent IS NULL AND location NOT IN ('High income', 'Low income', 'Upper Middle Income', 'Lower Middle Income') 
GROUP BY 
    DATEFROMPARTS(YEAR(date), MONTH(date), 1), location
ORDER BY 
    month, location;
--- Global numbers (monthly by Income)
SELECT 
    DATEFROMPARTS(YEAR(date), MONTH(date), 1) AS month,
    SUM(new_cases) AS total_new_cases,
    location
FROM 
    covidDeaths
WHERE 
    continent IS NULL AND location IN ('High income', 'Low income', 'Upper Middle Income', 'Lower Middle Income')
GROUP BY 
    DATEFROMPARTS(YEAR(date), MONTH(date), 1), location
ORDER BY 
    month, location;
-- Global numbers
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths) / SUM(new_cases) * 100 AS DeathPercentage
FROM   covidDeaths
WHERE continent is not null

-- Joining the covidDeath with covidVaccination via location and date
-- Looking at Total Population vs Vaccination (for Europe)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS Vaccination_Progress
FROM   covidDeaths AS dea INNER JOIN
           covidVaccination AS vac ON dea.date = vac.date AND dea.location = vac.location
WHERE (dea.continent IS NOT NULL) AND (dea.continent IN ('Europe')) AND (vac.new_vaccinations IS NOT NULL)
ORDER BY dea.date, dea.location
-- Total Population to Vaccination_Progress Ration (use CTE) (Europe)
WITH CTE_POPvsVAC_PRO (continent, location, date, population, new_vaccinations, Vaccination_Progress)
AS 
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS Vaccination_Progress
FROM   covidDeaths AS dea 
INNER JOIN covidVaccination AS vac 
ON dea.date = vac.date 
AND dea.location = vac.location
WHERE (dea.continent IS NOT NULL) AND (dea.continent IN ('Europe')) AND (vac.new_vaccinations IS NOT NULL)
)
SELECT continent, location, date, population, new_vaccinations, Vaccination_Progress
	, Vaccination_Progress / population * 100 AS Population_Percentage_Vacinned_Progress
FROM CTE_POPvsVAC_PRO
ORDER BY location, date;

-- Temp Table - THE SAME AS ABOVE -  DIFFERENT METHOD
CREATE TABLE #PercentagePopulationVaccinated
(
continent NVARCHAR(255), 
location NVARCHAR(255), 
date DATETIME, 
population NUMERIC, 
new_vaccinations NUMERIC,
RollingpPeopleVaccinated NUMERIC
);
-- INSERT DATA into temp table
INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS Vaccination_Progress
FROM   covidDeaths AS dea 
INNER JOIN covidVaccination AS vac 
ON dea.date = vac.date 
AND dea.location = vac.location
WHERE (dea.continent IS NOT NULL) AND (dea.continent IN ('Europe')) AND (vac.new_vaccinations IS NOT NULL)
-- select * temp table #PercentagePopulationVaccinated
SELECT continent, location, date, population, new_vaccinations, RollingpPeopleVaccinated
	, RollingpPeopleVaccinated / population * 100 AS Population_Percentage_Vacinned_Progress
FROM #PercentagePopulationVaccinated
ORDER BY 2, 6

-- Creating View to store data for later visualisation
CREATE VIEW PercentagePopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS Vaccination_Progress
	, (SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date)) / dea.population * 100 AS PercentagePopulationVaccinated
FROM   covidDeaths AS dea 
INNER JOIN covidVaccination AS vac 
ON dea.date = vac.date 
AND dea.location = vac.location
WHERE (dea.continent IS NOT NULL) AND (dea.continent IN ('Europe')) AND (vac.new_vaccinations IS NOT NULL);
--- 
select *
from dbo.PopulationVaccinated

---
Select *
FROM dbo.PercentagePopulationVaccinated

---