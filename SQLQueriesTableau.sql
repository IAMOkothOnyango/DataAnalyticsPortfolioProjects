/* 
SQL Queries for Tableau COVID Analysis Project
*/

/* Global Summary: Total Cases, Total Deaths, and Death Percentage */
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL -- Exclude records with missing continent data
ORDER BY 
    total_cases, total_deaths;

/* Notes:
- The above query calculates global numbers based on provided data.
- Ensures only valid continent data is included.
*/

/* Double-Check on "World" Location */
-- Uncomment to verify if global totals align with the "World" location
-- SELECT 
--     SUM(new_cases) AS total_cases, 
--     SUM(CAST(new_deaths AS INT)) AS total_deaths, 
--     (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS DeathPercentage
-- FROM 
--     PortfolioProject..CovidDeaths
-- WHERE 
--     location = 'World';

/* Exclude Non-Country Records (e.g., 'World', 'European Union') */
SELECT 
    location, 
    SUM(CAST(new_deaths AS INT)) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NULL -- Exclude continent-associated records
    AND location NOT IN ('World', 'European Union', 'International') -- Exclude aggregated/global locations
GROUP BY 
    location
ORDER BY 
    TotalDeathCount DESC;

/* Country Analysis: Highest Infection Rate Compared to Population */
SELECT 
    Location, 
    Population, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX((total_cases * 100.0 / population)) AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
GROUP BY 
    Location, Population
ORDER BY 
    PercentPopulationInfected DESC;

/* Breaking Down Data by Location and Date */
SELECT 
    Location, 
    Population, 
    date, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX((total_cases * 100.0 / population)) AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
GROUP BY 
    Location, Population, date
ORDER BY 
    PercentPopulationInfected DESC;

/* Vaccination Data: Total Vaccinations by Location */
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population,
    MAX(vac.total_vaccinations) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL -- Ensure valid continent data
GROUP BY 
    dea.continent, dea.location, dea.date, dea.population
ORDER BY 
    dea.continent, dea.location, dea.date;

/* Vaccination Percentage Using CTE */
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(INT, vac.new_vaccinations)) 
            OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL -- Ensure valid data for analysis
)
SELECT 
    *, 
    (RollingPeopleVaccinated * 100.0 / Population) AS PercentPeopleVaccinated
FROM 
    PopvsVac
ORDER BY 
    Location, Date;

/* Country Analysis with Daily Records */
SELECT 
    Location, 
    Population, 
    date, 
    MAX(total_cases) AS HighestInfectionCount,  
    MAX((total_cases * 100.0 / population)) AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
GROUP BY 
    Location, Population, date
ORDER BY 
    PercentPopulationInfected DESC;

/* Cleaned Queries with Explanations */
-- The above queries have been refined for clarity, performance, and consistency.
-- Use the provided queries to create insightful Tableau visualizations.
-- Ensure population and vaccination data align for accurate calculations.
