SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

-- Select the data that we'll be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%kenya%'
ORDER BY 1,2

--Looking at the Total Cases vs Population
-- Shows what percentage of the population got COVID

SELECT location, date, population, total_cases, (total_cases/population)*100 as CasePercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%kenya%'
ORDER BY 1,2

--Looking at the Total Cases vs Population in Kenya, Uganda, Tanzania
-- Shows what percentage of the population got COVID in Kenya, Uganda, Tanzania

SELECT location, 
       date, 
       population, 
       total_cases, 
       (total_cases / population) * 100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%kenya%' 
   OR location LIKE '%tanzania%' 
   OR location LIKE '%uganda%'
ORDER BY 1, 2;

--Looking at Countries with Highest Infection Rate Compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%Kenya%'
Group by Location, Population
order by PercentPopulationInfected desc

--Looking at Countries with Highest Infection Rate Compared to Population // Version 2

SELECT 
    Location, 
    Population, 
    MAX(total_cases) AS HighestInfectionCount, 
    MAX((total_cases * 100.0 / Population)) AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
WHERE 
     Population > 0 -- Avoid division by zero
--AND Location LIKE '%Kenya%'
GROUP BY 
    Location, Population
ORDER BY 
    PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- Countries with Highest Death Count per Population // Version 2

SELECT 
    Location, 
    Population, 
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    Population > 0 -- Exclude invalid or missing population data
    AND Continent IS NOT NULL -- Ensure valid continent data
GROUP BY 
    Location, Population
ORDER BY 
    TotalDeathCount DESC;

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

SELECT 
    Continent, 
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    Continent IS NOT NULL -- Ensure valid continent data
GROUP BY 
    Continent
ORDER BY 
    TotalDeathCount DESC;




-- GLOBAL NUMBERS

SELECT 
    Date,
	SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    Continent IS NOT NULL 
GROUP BY Date
ORDER BY 
    1, 2;


--Merging the two tables

SELECT *
FROM 
	PortfolioProject..CovidDeaths DEA
JOIN 
	PortfolioProject..CovidVaccinations VAC
	ON DEA.Location = VAC.Location
	AND DEA.DATE = VAC.DATE



-- Total Population vs Vaccinations

SELECT 
    dea.Continent, 
    dea.Location, 
    dea.Date, 
    dea.Population, 
    vac.New_Vaccinations
FROM 
    PortfolioProject..CovidDeaths AS dea
JOIN 
    PortfolioProject..CovidVaccinations AS vac
    ON dea.Location = vac.Location
    AND dea.Date = vac.Date
WHERE 
    dea.Continent IS NOT NULL
ORDER BY 
    dea.Location, 
    dea.Date;

-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(int, vac.new_vaccinations)) 
            OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
    --ORDER BY 2, 3 -- Uncommented or Removed for final execution
)

SELECT 
    *, 
    (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM 
    PopvsVac;



-- Using Temp Table to perform Calculation on Partition By in previous query

-- Drop the temp table if it exists
DROP Table if exists #PercentPopulationVaccinated;

-- Create a new temp table to store results
Create Table #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

-- Insert data with rolling sum of vaccinations
Insert into #PercentPopulationVaccinated
Select 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location
    And dea.date = vac.date
Where dea.continent IS NOT NULL;

-- Select data with vaccination percentage
Select 
    *, 
    (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
From #PercentPopulationVaccinated;




-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated,
    (SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) / dea.population) * 100 AS VaccinationPercentage
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;
 



