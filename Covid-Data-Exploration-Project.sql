-- Selecting a section of the data that I want to explore

SELECT location
		, date
		, total_cases
		, new_cases
		, total_deaths
		, population
FROM [covid-deaths]
ORDER BY 1,2

-- Looking at total cases versus total deaths across the world

SELECT location
		, date
		, total_cases
		, total_deaths
		, ROUND((total_deaths / total_cases) * 100, 2) AS percent_death 
FROM [covid-deaths]
ORDER BY 1,2

-- Looking at total cases versus total deaths in the United States
-- Shows the percentage of people that contracted Covid that then died in the US

SELECT location
		, date
		, total_cases
		, total_deaths
		, ROUND((total_deaths / total_cases) * 100, 2) AS percent_death 
FROM [covid-deaths]
WHERE location = 'United States'
ORDER BY 1,2

-- Looking at total cases versus the population in the US
-- Shows the percentage of the population that contracted Covid
-- As of April 21, 2024 30.58% of the US population has gotten Covid

SELECT location
		, date
		, total_cases
		, population
		, ROUND((total_cases / population) * 100, 2) AS percent_infected
FROM [covid-deaths]
WHERE location = 'United States'
ORDER BY 1,2

-- Looking at countries with the highest infection rate compared to population
-- Cyprus has the highest infection rate with 77.1% of their population having been infected

SELECT location
		, MAX(total_cases) AS highest_infection_count
		, population
		, ROUND((MAX(total_cases) / population) * 100, 2) AS percent_infected
FROM [covid-deaths]
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

-- Showing the countries with the highest death count
-- The United States has the highest death count of all countries with 1,186,079 deaths

SELECT location
		, MAX(total_deaths) AS total_death_count
FROM [covid-deaths]
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

-- Showing the continents and income brackets with the highest death count
-- By income the "High Income" bracket has the highest number of deaths at 2,985,572
-- By continent Europe has the highest number of deaths at 2,100,197

SELECT location
		, MAX(total_deaths) AS total_death_count
FROM [covid-deaths]
WHERE continent IS NULL AND location <> 'World'
GROUP BY location
ORDER BY 2 DESC

-- Showing the total number of deaths across the entire world
-- 7,046,320 people have died of Covid-19 worldwide

SELECT location
		, MAX(total_deaths) AS total_death_count
FROM [covid-deaths]
WHERE continent IS NULL AND location = 'World'
GROUP BY location

-- Looking at total cases, total deaths, and percent of people that died by country with a rollup for the worldwide totals

SELECT COALESCE(location, 'Worldwide Total') AS location
		, SUM(new_cases) AS total_cases
		, SUM(new_deaths) AS total_deaths
		, CASE 
			WHEN SUM(new_cases) = 0 THEN 0
			ELSE ROUND(SUM(new_deaths) / NULLIF(SUM(new_cases), 0) * 100, 2)
		END AS percent_death
FROM [covid-deaths]
WHERE continent IS NOT NULL
GROUP BY GROUPING SETS ((location), ())
ORDER BY 2 DESC

-- Looking at the population versus vaccinations worldwide

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_total_vaccinations)
AS
(
SELECT deaths.continent
		, deaths.location
		, deaths.date
		, deaths.population
		, vaccs.new_vaccinations
		, SUM(vaccs.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_total_vaccinations
FROM [covid-deaths] AS deaths
JOIN [covid-vaccinations] AS vaccs
	ON deaths.location = vaccs.location
	AND deaths.date = vaccs.date
	AND deaths.iso_code = vaccs.iso_code
WHERE deaths.continent IS NOT NULL
)
SELECT *, ROUND((rolling_total_vaccinations / population) * 100, 2) AS percent_vaccinated
FROM pop_vs_vac

-- Creating a view to store data for later visualizations

CREATE VIEW population_vs_vaccinations_view AS
WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_total_vaccinations)
AS
(
SELECT deaths.continent
		, deaths.location
		, deaths.date
		, deaths.population
		, vaccs.new_vaccinations
		, SUM(vaccs.new_vaccinations) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_total_vaccinations
FROM [covid-deaths] AS deaths
JOIN [covid-vaccinations] AS vaccs
	ON deaths.location = vaccs.location
	AND deaths.date = vaccs.date
	AND deaths.iso_code = vaccs.iso_code
WHERE deaths.continent IS NOT NULL
)
SELECT *, ROUND((rolling_total_vaccinations / population) * 100, 2) AS percent_vaccinated
FROM pop_vs_vac