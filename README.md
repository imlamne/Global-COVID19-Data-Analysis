# Global COVID-19 Data Analysis

**SQL Server | Tableau Public**  
**Period:** January 2020 to April 2021  
**[View interactive dashboard](https://public.tableau.com/app/profile/lam.nguyen2038/viz/Global_COVID19_Executive_Dashboard/COVID-19ExecutiveDashboard)**

## About the Project

This project examines historical COVID-19 reporting across countries and regions, focusing on changes in reported cases, differences in mortality, and the reliability of vaccination data. SQL Server was used to analyze and validate the records, with the results presented in Tableau.

## Key Findings

**Reported cases and deaths.** As of April 30, 2021, the 182 locations eligible for the headline calculation recorded **151.40 million cases** and **3.18 million deaths**, resulting in a **2.10% reported case fatality ratio**. This is a ratio of reported deaths to reported cases, not the risk of death among all infected people.

**Trends and geographic differences.** Monthly net reported case change is shown across 16 months. At the cutoff, Europe recorded **1,016,750 deaths**, followed by North America with **847,942** and South America with **672,415**. After adjusting for population, Hungary had **285.08 reported deaths per 100,000 residents**, followed by Czechia at **273.29**. Absolute totals and population adjusted rates answer different questions and are presented separately.

**Vaccination data gaps.** Among **81,060 location and date records**, `new_vaccinations` was available in **8.63%** and `total_vaccinations` in **10.37%**. Running totals reconstructed from the available daily values did not consistently match the reported cumulative totals, so they were not treated as interchangeable.

## Analytical Approach

The analysis uses a consistent reporting cutoff and eligibility criteria for global and continent totals. Geographic aggregate rows were excluded from location level calculations to avoid double counting.

Data quality checks distinguish missing values from zero and missing reporting dates from valid observations. Of **210 locations** in scope, **182** had valid inputs for mortality analysis, **13** had missing death values, and **15** had no record on April 30, 2021. The scope includes territories and should not be interpreted as 210 sovereign countries.

The historical source includes negative daily changes to reported cases and deaths. These were retained as reporting adjustments, not interpreted as negative infections. A targeted comparison of **136 affected source rows** with the SQL Server records found **no mismatches**. Continent totals were also reconciled with the global headline figures. These checks do not constitute a complete audit of every source value.

## Reporting Implications

The dashboard separates monthly net changes, absolute deaths, and deaths per 100,000 residents to avoid misleading comparisons. Headline figures should always be accompanied by their reporting date and coverage. Incomplete vaccination observations should not be filled with zero or used to infer a complete cumulative series without further validation.

## Project Files

| File | Contents |
|---|---|
| [SQL Analysis & Validation](sql/dashboard_final_exports.sql) | SQL queries for data analysis, aggregation, and validation |
| [Dashboard Datasets](data_outputs/) | Six validated datasets used in Tableau |
| [Interactive Tableau Dashboard](https://public.tableau.com/app/profile/lam.nguyen2038/viz/Global_COVID19_Executive_Dashboard/COVID-19ExecutiveDashboard) | Published executive dashboard |
| [Data Dictionary & Limitations](docs/data_dictionary_and_limits.md) | Metric definitions, assumptions, and data limitations |
| [Executive Presentation](presentation/Global_COVID19_Executive_Presentation.pptx) | Presentation of key findings and recommendations |

The analysis uses historical Excel files from [Alex The Analyst's portfolio project](https://github.com/AlexTheAnalyst/PortfolioProjects), based on [Our World in Data](https://ourworldindata.org/coronavirus) records. Building on the tutorial, this version adds source reconciliation, explicit coverage checks, consistent metric definitions, and a dashboard organized around trends, geography, and reporting reliability.

**Reproducibility:** Import the historical Excel files into SQL Server, run the SQL exports and checks, and refresh the Tableau extracts. The published dashboard is static until refreshed.
