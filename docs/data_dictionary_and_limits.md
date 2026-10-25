# Metric definitions and limits

- **Reported Cases / Deaths:** SUM of cumulative country/location totals at the fixed cutoff **2021-04-30**, over the same **182 eligible** location records (source criteria: cases > 0, deaths >= 0). Not the universe of 210 scoped locations.
- **Reported CFR:** SUM(deaths) / SUM(cases) × 100 among the *same* eligible location set. It is not IFR or causal mortality probability.
- **Monthly Net Reported Case Change:** SUM(source `new_cases`) by calendar month from the historical stored snapshot, including **61 negative daily entries** interpreted as net reporting adjustments. A negative change does not imply negative gross infections. Source NULLs are not zero. First/last calendar months may be partial; check `First_Observed_Date`, `Last_Observed_Date`, coverage fields.
- **Reported deaths per 100K:** Total reported deaths / population × 100,000 on one reporting date, restricted to valid denominator and source inputs. Do not compare with cumulative deaths at different cutoffs.
- **Deaths by continent:** SUM of eligible location-level cumulative deaths at cutoff; geographic classification follows dataset. It is an absolute total, not a per-capita rate. Continent sums reconcile to global KPI.
- **Daily vaccine availability:** non-NULL `new_vaccinations` / 81,060 rows = 8.63%; **cumulative** `total_vaccinations` non-NULL / rows = 10.37%. These are row-level availability shares, not proportions of countries vaccinated.
- **Reported decrease events:** historical `new_cases` contains 61 negative rows and `new_deaths` 80 in this snapshot. These are reporting changes, not a confirmed cause-classification of each revision. The final flag dataset contains 68 locations with one or more cumulative decrease events.
- **Data geography:** The `continent IS NOT NULL` filter leaves 210 location-like entities, including territories. Do not label all as sovereign nations.
- **Version drift:** OWID's current documentation and live dataset must not be conflated with this archived 2021 extraction; re-verify definitions if changing source/version.
- **Refresh:** SQL date selection is dynamic, but local CSVs/Tableau Public extracts do not auto-refresh from SQL Server.
