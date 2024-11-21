-- ****************************************************************
-- Query 1: View All Records Ordered by Specific Columns
-- ****************************************************************
-- Retrieves all columns from the CovidDeaths table.
-- Orders the results by the 3rd and 4th columns.
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3, 4;


-- ****************************************************************
-- Query 2: View Selected Columns with Date Sorting
-- ****************************************************************
-- Retrieves key columns (location, date, total cases, etc.) for further analysis.
-- Orders the data by location and date.
SELECT 
    location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    population
FROM 
    PortfolioProject..CovidDeaths
ORDER BY 
    location, 
    date;


-- ****************************************************************
-- Query 3: Calculate Death Percentage
-- ****************************************************************
-- Shows the percentage of deaths compared to total cases for Kenya.
-- Ensures accurate floating-point division for percentage calculation.
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths * 100.0 / total_cases) AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    location LIKE '%kenya%'
ORDER BY 
    location, 
    date;


-- ****************************************************************
-- Query 4: Infection Rate vs Population
-- ****************************************************************
-- Calculates the percentage of the population infected with COVID in Kenya.
SELECT 
    location, 
    date, 
    population, 
    total_cases, 
    (total_cases * 100.0 / population) AS CasePercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    location LIKE '%kenya%'
ORDER BY 
    location, 
    date;


-- ****************************************************************
-- Query 5: Infection Rate for Multiple Countries
-- ****************************************************************
-- Calculates infection rates for Kenya, Tanzania, and Uganda.
-- Uses `IN` for cleaner filtering in the WHERE clause.
SELECT 
    location, 
    date, 
    population, 
    total_cases, 
    (total_cases * 100.0 / population) AS CasePercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    location IN ('Kenya', 'Tanzania', 'Uganda')
ORDER BY 
    location, 
    date;


-- ****************************************************************
-- Query 6: Countries with the Highest Infection Rate
-- ****************************************************************
-- Identifies countries with the highest infection rates relative to population.
-- Grouped by location and population for accurate aggregation.
SELECT 
    location, 
    population, 
    MAX(total_cases) AS HighestInfectionCount, 
    MAX(total_cases * 100.0 / population) AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
GROUP BY 
    location, 
    population
ORDER BY 
    PercentPopulationInfected DESC;


-- ****************************************************************
-- Query 7: Highest Total Death Count
-- ****************************************************************
-- Finds the countries with the highest total death counts.
-- Filters out invalid continent data and ensures integer casting for accuracy.
SELECT 
    location, 
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    location
ORDER BY 
    TotalDeathCount DESC;


-- ****************************************************************
-- Query 8: Highest Death Count by Continent
-- ****************************************************************
-- Shows the highest total death count by continent.
SELECT 
    continent, 
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    continent
ORDER BY 
    TotalDeathCount DESC;


-- ****************************************************************
-- Query 9: Global Numbers for Cases and Deaths
-- ****************************************************************
-- Calculates total cases, total deaths, and death percentage globally by date.
-- Groups data by date for a time-series perspective.
SELECT 
    date,
    SUM(new_cases) AS TotalCases, 
    SUM(CAST(new_deaths AS INT)) AS TotalDeaths, 
    SUM(CAST(new_deaths AS INT)) * 100.0 / SUM(new_cases) AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    date
ORDER BY 
    date;


-- ****************************************************************
-- Query 10: Merging Death and Vaccination Data
-- ****************************************************************
-- Joins CovidDeaths and CovidVaccinations tables on location and date.
-- Provides a combined view of deaths and vaccinations.
SELECT *
FROM 
    PortfolioProject..CovidDeaths DEA
JOIN 
    PortfolioProject..CovidVaccinations VAC
    ON DEA.Location = VAC.Location
    AND DEA.DATE = VAC.DATE;


-- ****************************************************************
-- Query 11: Vaccination Data by Population
-- ****************************************************************
-- Analyzes vaccination data against total population, grouped by location and date.
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations
FROM 
    PortfolioProject..CovidDeaths AS dea
JOIN 
    PortfolioProject..CovidVaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
ORDER BY 
    dea.location, 
    dea.date;


-- ****************************************************************
-- Query 12: Rolling Vaccination Count with Percentage
-- ****************************************************************
-- Uses a rolling sum of vaccinations to calculate the cumulative count for each country.
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(int, vac.new_vaccinations)) 
            OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)

-- Calculate percentage of population vaccinated
SELECT 
    *, 
    (RollingPeopleVaccinated * 100.0 / Population) AS VaccinationPercentage
FROM 
    PopvsVac;


-- ****************************************************************
-- Query 13: Create Temporary Table for Vaccination Analysis
-- ****************************************************************
-- Drops the temporary table if it exists, creates it, and populates it with rolling vaccination data.
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;

-- Retrieve data from the temporary table with calculated vaccination percentage.
SELECT 
    *, 
    (RollingPeopleVaccinated * 100.0 / Population) AS VaccinationPercentage
FROM 
    #PercentPopulationVaccinated;


-- ****************************************************************
-- Query 14: Create View for Vaccination Analysis
-- ****************************************************************
-- Creates a view for easier access to rolling vaccination data and vaccination percentage.
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated,
    (SUM(CONVERT(int, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.Location ORDER BY dea.Date) * 100.0 / dea.population) AS VaccinationPercentage
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;
