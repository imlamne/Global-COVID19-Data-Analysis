/* GLOBAL COVID-19 | FINAL DASHBOARD EXPORT PACK
   SQL Server / SSMS | Existing dbo.CovidDeaths + dbo.CovidVaccinations
   Source: historical Alex/OWID Excel snapshot. Data ends 2021-04-30 currently.
   Run each EXPORT separately. Save each result as CSV WITH COLUMN NAMES.
   Do NOT change original tables. No INSERT, UPDATE, DELETE, DROP.

   Scope = records with continent IS NOT NULL (includes some territories).
   KPI/continent snapshot = same latest observed date and same eligibility:
        total_cases > 0 AND total_deaths >= 0.
   Mortality = valid population > 0 and deaths >= 0, at same snapshot date.
   Monthly trend = SUM(source new_cases) including negative reported corrections.
        Do NOT call this gross incidence. NULL means unreported/unknown.
   Use data-as-of date shown on dashboard. CSV/Tableau Public extracts do NOT
   automatically refresh when SQL Server changes.
*/
USE PortfolioProject;
GO

/* EXPORT 01 -> 01_global_kpis_final.csv (1 row)
   All three main KPI metrics use identical eligible location set. */
;WITH cutoff AS (
 SELECT MAX([date]) reporting_date FROM dbo.CovidDeaths WHERE continent IS NOT NULL
), eligible AS (
 SELECT c.reporting_date,d.location,d.total_cases,d.total_deaths
 FROM dbo.CovidDeaths d CROSS JOIN cutoff c
 WHERE d.continent IS NOT NULL AND d.[date]=c.reporting_date
   AND d.total_cases > 0 AND d.total_deaths >= 0
)
SELECT MAX(reporting_date) AS Reporting_Date,
 COUNT(*) AS Included_Locations,
 SUM(CAST(total_cases AS DECIMAL(28,2))) AS Reported_Cases,
 SUM(CAST(total_deaths AS DECIMAL(28,2))) AS Reported_Deaths,
 CAST(100.0*SUM(CAST(total_deaths AS DECIMAL(28,2))) /
      NULLIF(SUM(CAST(total_cases AS DECIMAL(28,2))),0) AS DECIMAL(15,6)) AS Reported_Case_Fatality_Pct
FROM eligible;
GO

/* EXPORT 02 -> 02_monthly_reported_case_change.csv (one row per observed month)
   new_cases follows historical snapshot as stored (may include corrections <0).
   A source change is not necessarily gross new infections. */
;WITH base AS (
 SELECT DATEFROMPARTS(YEAR([date]),MONTH([date]),1) AS Month_Start,
        [date],location,new_cases
 FROM dbo.CovidDeaths WHERE continent IS NOT NULL AND [date] IS NOT NULL
)
SELECT Month_Start,MIN([date]) AS First_Observed_Date,
 MAX([date]) AS Last_Observed_Date,
 COUNT_BIG(*) AS Location_Date_Rows,
 COUNT(DISTINCT location) AS Observed_Locations,
 COUNT(new_cases) AS Available_Daily_Rows,
 SUM(CASE WHEN new_cases IS NULL THEN 1 ELSE 0 END) AS Missing_Daily_Rows,
 SUM(CASE WHEN new_cases<0 THEN 1 ELSE 0 END) AS Negative_Adjustment_Rows,
 SUM(CASE WHEN new_cases<0 THEN CAST(new_cases AS DECIMAL(28,2)) ELSE CAST(0 AS DECIMAL(28,2)) END) AS Negative_Adjustment_Amount,
 SUM(CAST(new_cases AS DECIMAL(28,2))) AS Monthly_Net_Reported_Case_Change,
 CAST(100.0*COUNT(new_cases)/NULLIF(COUNT_BIG(*),0) AS DECIMAL(9,2)) AS Daily_Field_Availability_Pct
FROM base GROUP BY Month_Start ORDER BY Month_Start;
GO

/* EXPORT 03 -> 03_continent_snapshot.csv (one row per observed continent)
   Note: ABSOLUTE burden by continent, not continent infection risk. */
;WITH cutoff AS (
 SELECT MAX([date]) AS Reporting_Date FROM dbo.CovidDeaths WHERE continent IS NOT NULL
), scoped AS (
 SELECT DISTINCT continent,location FROM dbo.CovidDeaths WHERE continent IS NOT NULL
), obs AS (
 SELECT s.continent,s.location,c.Reporting_Date,d.[date] AS Observed_Date,
        d.total_cases,d.total_deaths,d.population
 FROM scoped s CROSS JOIN cutoff c LEFT JOIN dbo.CovidDeaths d
   ON d.location=s.location AND d.[date]=c.Reporting_Date
)
SELECT MAX(Reporting_Date) AS Reporting_Date,continent,
 COUNT(*) AS Scoped_Locations,
 SUM(CASE WHEN Observed_Date IS NULL THEN 1 ELSE 0 END) AS Missing_Cutoff_Locations,
 SUM(CASE WHEN total_cases>0 AND total_deaths>=0 THEN 1 ELSE 0 END) AS KPI_Eligible_Locations,
 SUM(CASE WHEN total_cases>0 AND total_deaths>=0 THEN CAST(total_cases AS DECIMAL(28,2)) END) AS Reported_Cases,
 SUM(CASE WHEN total_cases>0 AND total_deaths>=0 THEN CAST(total_deaths AS DECIMAL(28,2)) END) AS Reported_Deaths,
 SUM(CASE WHEN total_cases>0 AND total_deaths>=0 AND population>0 THEN 1 ELSE 0 END) AS Population_Eligible_Locations,
 CAST(100000.0*SUM(CASE WHEN total_cases>0 AND total_deaths>=0 AND population>0 THEN CAST(total_deaths AS DECIMAL(28,2)) END) /
 NULLIF(SUM(CASE WHEN total_cases>0 AND total_deaths>=0 AND population>0 THEN CAST(population AS DECIMAL(28,2)) END),0)
 AS DECIMAL(18,4)) AS Deaths_Per_100K_Eligible_Population
FROM obs GROUP BY continent ORDER BY Reported_Deaths DESC;
GO

/* EXPORT 04 -> 04_mortality_map_and_ranking.csv (all locations in scope)
   NULL metric for invalid or missing reporting; do not render NULL as zero. */
;WITH cutoff AS (
 SELECT MAX([date]) AS Reporting_Date FROM dbo.CovidDeaths WHERE continent IS NOT NULL
), scoped AS (
 SELECT DISTINCT continent,location FROM dbo.CovidDeaths WHERE continent IS NOT NULL
), obs AS (
 SELECT s.continent,s.location,c.Reporting_Date,d.[date] AS Observed_Date,
        d.total_cases,d.total_deaths,d.population
 FROM scoped s CROSS JOIN cutoff c LEFT JOIN dbo.CovidDeaths d
   ON d.location=s.location AND d.[date]=c.Reporting_Date
)
SELECT Reporting_Date,continent AS Continent,location AS Location,population AS Population,
 total_cases AS Total_Cases,total_deaths AS Total_Deaths,
 CASE WHEN Observed_Date IS NULL THEN 'No cutoff record'
      WHEN total_deaths IS NULL THEN 'Missing deaths'
      WHEN population IS NULL THEN 'Missing population'
      WHEN total_deaths < 0 THEN 'Invalid negative deaths'
      WHEN population <= 0 THEN 'Invalid population'
      ELSE 'Valid' END AS Data_Status,
 CAST(CASE WHEN Observed_Date IS NOT NULL AND population>0 AND total_deaths>=0
      THEN CAST(total_deaths AS DECIMAL(28,4))*100000.0/CAST(population AS DECIMAL(28,4)) END
      AS DECIMAL(18,6)) AS Deaths_Per_100K
FROM obs ORDER BY Deaths_Per_100K DESC,Location;
GO

/* EXPORT 05 -> 05_vaccination_quality.csv (1 row)
   Availability over historical location-date rows (not unique locations).
   Source metric total_vaccinations counts administered doses, NOT people. */
SELECT COUNT_BIG(*) AS Observed_Rows,
 COUNT(new_vaccinations) AS Daily_Non_Null_Rows,
 COUNT(total_vaccinations) AS Cumulative_Non_Null_Rows,
 SUM(CASE WHEN new_vaccinations IS NULL AND total_vaccinations IS NULL THEN 1 ELSE 0 END) AS Neither_Available_Rows,
 SUM(CASE WHEN new_vaccinations IS NOT NULL AND total_vaccinations IS NOT NULL THEN 1 ELSE 0 END) AS Both_Available_Rows,
 CAST(100.0*COUNT(new_vaccinations)/NULLIF(COUNT_BIG(*),0) AS DECIMAL(9,2)) AS Daily_Availability_Pct,
 CAST(100.0*COUNT(total_vaccinations)/NULLIF(COUNT_BIG(*),0) AS DECIMAL(9,2)) AS Cumulative_Availability_Pct
FROM dbo.CovidVaccinations WHERE continent IS NOT NULL;
GO

/* EXPORT 06 -> 06_reporting_anomalies.csv (one row per location)
   Compare to prior NON-NULL cumulative observation. Screening only; doesn't
   establish that the underlying cause was a confirmed source revision. */
;WITH history AS (
 SELECT location,[date],total_cases,total_deaths,
 MAX(CASE WHEN total_cases IS NOT NULL THEN [date] END) OVER
 (PARTITION BY location ORDER BY [date] ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS Prior_Case_Date,
 MAX(CASE WHEN total_deaths IS NOT NULL THEN [date] END) OVER
 (PARTITION BY location ORDER BY [date] ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS Prior_Death_Date
 FROM dbo.CovidDeaths WHERE continent IS NOT NULL
), pairs AS (
 SELECT h.location,h.total_cases,h.total_deaths,
        pc.total_cases AS Prior_Cases,pd.total_deaths AS Prior_Deaths
 FROM history h
 LEFT JOIN dbo.CovidDeaths pc ON pc.location=h.location AND pc.[date]=h.Prior_Case_Date
 LEFT JOIN dbo.CovidDeaths pd ON pd.location=h.location AND pd.[date]=h.Prior_Death_Date
)
SELECT Location,
 SUM(CASE WHEN total_cases<Prior_Cases THEN 1 ELSE 0 END) AS Cases_Decrease_Events,
 SUM(CASE WHEN total_deaths<Prior_Deaths THEN 1 ELSE 0 END) AS Deaths_Decrease_Events
FROM pairs GROUP BY Location ORDER BY Cases_Decrease_Events DESC,Deaths_Decrease_Events DESC;
GO

/* VALIDATION 01 (DO NOT EXPORT) -> coverage at common cutoff */
;WITH c AS (SELECT MAX([date]) AS cutoff FROM dbo.CovidDeaths WHERE continent IS NOT NULL),
s AS (SELECT DISTINCT location FROM dbo.CovidDeaths WHERE continent IS NOT NULL),
o AS (SELECT s.location,d.[date] observed_date,d.total_cases,d.total_deaths,d.population
FROM s CROSS JOIN c LEFT JOIN dbo.CovidDeaths d ON d.location=s.location AND d.[date]=c.cutoff)
SELECT (SELECT cutoff FROM c) AS Reporting_Date,COUNT(*) AS Scoped_Locations,
 SUM(CASE WHEN observed_date IS NULL THEN 1 ELSE 0 END) AS No_Cutoff_Record,
 SUM(CASE WHEN total_cases>0 AND total_deaths>=0 THEN 1 ELSE 0 END) AS KPI_Eligible,
 SUM(CASE WHEN observed_date IS NOT NULL AND total_deaths>=0 AND population>0 THEN 1 ELSE 0 END) AS Mortality_Eligible
FROM o;
GO

/* VALIDATION 02 (DO NOT EXPORT) -> monthly correction profile */
SELECT COUNT(*) AS Negative_New_Cases_Rows,
 SUM(CASE WHEN new_cases<0 THEN 1 ELSE 0 END) AS Location_Level_Negative_New_Cases_Rows,
 MIN([date]) AS First_Observed_Date,MAX([date]) AS Last_Observed_Date
FROM dbo.CovidDeaths WHERE continent IS NOT NULL AND new_cases<0;
GO

/* VALIDATION 03 (DO NOT EXPORT) -> continent totals must equal KPI totals */
;WITH cutoff AS (SELECT MAX([date]) dt FROM dbo.CovidDeaths WHERE continent IS NOT NULL),
a AS (SELECT continent,CAST(total_cases AS DECIMAL(28,2)) cases,CAST(total_deaths AS DECIMAL(28,2)) deaths
FROM dbo.CovidDeaths d CROSS JOIN cutoff c WHERE d.continent IS NOT NULL AND d.[date]=c.dt AND total_cases>0 AND total_deaths>=0)
SELECT SUM(cases) AS All_Eligible_Cases,SUM(deaths) AS All_Eligible_Deaths,COUNT(*) AS All_Eligible_Locations FROM a;
GO
