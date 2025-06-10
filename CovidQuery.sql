-- Checking death rate from Covid infection per day in Nigeria 
SELECT location, date, total_deaths, total_cases, ROUND((total_deaths/total_cases) * 100, 2) AS DeathRatePercentage
FROM "CovidDeaths"
WHERE location = 'Nigeria'
ORDER BY date;

-- Checking countries with the highest death count, offset 28 as they are null values
SELECT location, SUM(new_deaths) AS TotalDeathCount, SUM(new_cases) AS TotalCaseCount, ROUND((SUM(new_deaths)/SUM(new_cases)) * 100, 2) AS PercentageDeathRate
FROM "CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location 
ORDER BY TotalDeathCount DESC
OFFSET 28;

-- Checking Global numbers 
SELECT date, SUM(new_deaths) AS TotalDeathCount, SUM(new_cases) AS TotalCaseCount, COALESCE(ROUND(NULLIF(SUM(new_deaths), 0)/NULLIF(SUM(new_cases), 0) * 100, 2), 0)
AS PercentageDeathRate
FROM "CovidDeaths"
GROUP BY date
ORDER BY date;

-- Total world death count and rate
SELECT SUM(new_deaths) AS TotalDeathCount, SUM(new_cases) AS TotalCaseCount, COALESCE(ROUND(NULLIF(SUM(new_deaths), 0)/NULLIF(SUM(new_cases), 0) * 100, 2), 0)
AS PercentageDeathRate
FROM "CovidDeaths";

-- Reviewing our other Table CovidVacination before joining
SELECT * FROM "CovidVacination";

-- Converting data types from VarChar
ALTER TABLE "CovidVacination"
ALTER COLUMN date TYPE DATE
USING to_date(date, 'DD/MM/YYYY');

ALTER TABLE "CovidVacination"
ALTER COLUMN new_vaccinations TYPE INT
USING new_vaccinations::INT;


-- Join tables on location and date
SELECT * FROM "CovidDeaths" AS CD
JOIN "CovidVacination" AS VAC
ON CD.location = VAC.location 
AND CD.date = VAC.date;

-- Checking each country's population vs vaccination
SELECT CD.continent, CD.location, CD.date, CD.population, 
SUM(VAC.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVac 
FROM "CovidDeaths" AS CD
JOIN "CovidVacination" AS VAC
ON CD.location = VAC.location 
AND CD.date = VAC.date
WHERE CD.continent IS NOT NULL
ORDER BY 2,3;

-- Creating a CTE table to check vaccination rates per day

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVac) AS
	(
		SELECT CD.continent, CD.location, CD.date, CD.population, VAC.new_vaccinations,
		SUM(VAC.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVac 
		FROM "CovidDeaths" AS CD
		JOIN "CovidVacination" AS VAC
		ON CD.location = VAC.location 
		AND CD.date = VAC.date
		WHERE CD.continent IS NOT NULL
	)

SELECT *, ROUND((RollingPeopleVac/population) * 100, 2) AS PercentageVacRate FROM PopVsVac;

-- Creating view for visualization 
CREATE VIEW PopVsVac AS
SELECT CD.continent, CD.location, CD.date, CD.population, VAC.new_vaccinations,
		SUM(VAC.new_vaccinations) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVac 
		FROM "CovidDeaths" AS CD
		JOIN "CovidVacination" AS VAC
		ON CD.location = VAC.location 
		AND CD.date = VAC.date
		WHERE CD.continent IS NOT NULL;

CREATE VIEW HighestDeath AS 
SELECT location, SUM(new_deaths) AS TotalDeathCount, SUM(new_cases) AS TotalCaseCount, ROUND((SUM(new_deaths)/SUM(new_cases)) * 100, 2) AS PercentageDeathRate
FROM "CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location 
ORDER BY TotalDeathCount DESC;
