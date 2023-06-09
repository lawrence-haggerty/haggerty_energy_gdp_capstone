-- haggerty_energy_gdp_capstone questions:

-- 1. How does energy production and consumption compare to GDP per capita at the state and national level?

-- 2. What differences in the mix of energy (fossil fuels, nuclear, and renewable energy) and consumption rates can be identified across the states. What contributes to these differences?

-- 3. What states have seen the greatest and least amount of growth in GDP per capita when compared to corresponding years for production and consumption of energy (considering all energy sources combined and fossil fuels, nuclear, and renewable energy separately)?

-- 4. What has been the growth rate at the state and national level for GDP per capita and production and consumption of energy (considering all energy sources combined and fossil fuels, nuclear, and renewable energy separately)?

-- 5. Where have negative impacts been observed. Can additional contributing factors be identified?

-- 6. What technological advances are spurring the most growth in non-fossil fuel energy and can an economic impact be determined?

-- 7. Stretch Question: What are the projections for continued growth in non-fossil fuels and does this appear to have a positive impact on the future economy?

--notes:
--GDP per capita is a country's gross domestic product divided by its population

--WINDOWS FUNCTIONS (RANGE w/ PARTITION BY)....VERY USEFUL
--https://www.postgresqltutorial.com/postgresql-window-function/postgresql-rank-function/

--review tables and validate data types
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'bea_gdp_63_97';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'bea_gdp_97_22';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'census_res_pop_10_20';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'eia_consumption_mix';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'eia_production_mix';

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'eia_expenditures_total';

--view gdp chart
SELECT *
FROM bea_gdp_63_97;

--review gdp by decade 1970-1990
SELECT state_code, state_name, description, unit, "1970", "1980", "1990"
FROM bea_gdp_63_97
WHERE description = 'All industry total';

--view gdp table
SELECT *
FROM bea_gdp_97_22;

--review gdp by decade 2000-2020
SELECT state_code, description, unit, "2000", "2010", "2020"
FROM bea_gdp_97_22
WHERE description = 'All industry total';

--view census table
SELECT *
FROM census_res_pop_10_20;

--review resident  pop from 1970-2020
SELECT state_code, description, "1970", "1980", "1990", "2000", "2010", "2020"   
FROM census_res_pop_10_20
--WHERE state_code = 'US';

--review w/o region data...adjust column names for use in other queries
SELECT state_code, 'Population' AS category, 'Individual Person' AS unit,
"1970", "1980", "1990", "2000", "2010", "2020"   
FROM census_res_pop_10_20
WHERE geo_type = 'Nation' OR geo_type = 'State' AND state_code <> 'PR';

--review consumption mix table
SELECT * 
FROM eia_consumption_mix;

--review national consumption numbers
SELECT state_code, category, type, unit, "1970", "1980", "1990", "2000", "2010", "2020"
FROM eia_consumption_mix
WHERE state_code = 'US';


--review production mix table
SELECT * 
FROM eia_production_mix;


--review national production numbers
SELECT state_code, category, type, unit, "1970", "1980", "1990", "2000", "2010", "2020"
FROM eia_production_mix
WHERE state_code = 'US';


--review expenditures table
SELECT *
FROM eia_expenditures_total;

--review national expenditures numbers
SELECT state_code, description, unit, "1970", "1980", "1990", "2000", "2010", "2020"
FROM eia_expenditures_total
WHERE state_code = 'US';


--##
--Question 1. How does energy production and consumption compare to GDP per capita at the state and national level?

--state/national production and consumption metrics 1970-2020
--Add Upper Case for Production: https://stackoverflow.com/questions/15290754/sql-capitalize-first-letter-only...INITCAP()
SELECT state_code, INITCAP(category) AS description, type, unit, "1970", "1980", "1990", "2000", "2010", "2020"
FROM eia_production_mix 
WHERE type = 'Total energy'  
UNION
SELECT state_code, category, type, unit, "1970", "1980", "1990", "2000", "2010", "2020"
FROM eia_consumption_mix
WHERE type = 'Total energy'
ORDER BY state_code;

--extract state_code and state_name 
--export to csv for use in power bi 'st_code_st_name_reference'
SELECT state_code, state_name
FROM eia_production_mix 
WHERE type = 'Total energy' AND state_code != 'DC'

--prep for gdp per capita calculation
--start with calculation for total dolars...multiply amount by 1M to convert from "Millions of current dollars". Conversion required for GDP per Capita calc.
--Union to add gdp and pop info same view
SELECT state_code, description, "2000"*1000000 AS "2000", "2010"*1000000 AS "2010", "2020"*1000000 AS "2020"
FROM bea_gdp_97_22 AS g1
WHERE state_code = 'US' AND description = 'All industry total'
UNION
SELECT state_code, description, "2000", "2010", "2020"  
FROM census_res_pop_10_20 AS c1
WHERE state_code = 'US';


--consolidated gdp query 1970-2020
--use for gdp per capita calculation
--export to csv to include with additional analysis and visualization 'q1_us_50st_gdp_total'
with CTE1 AS
	(SELECT state_code, description, "2000"*1000000 AS "2000", "2010"*1000000 AS "2010", "2020"*1000000 AS "2020"
	FROM bea_gdp_97_22 AS g1
	WHERE description = 'All industry total'),
CTE2 AS 
	(SELECT state_code, description, "1970"*1000000 AS "1970", "1980"*1000000 AS "1980", "1990"*1000000 AS "1990"
	FROM bea_gdp_63_97 AS g1
	WHERE description = 'All industry total'),
CTE3 AS
	(SELECT state_code, description, "1970", "1980", "1990", "2000", "2010", "2020"  
	FROM census_res_pop_10_20 AS c1
	)
SELECT CTE1.state_code, 'GDP' AS category, 'Dollars' AS unit,
	ROUND(CTE2."1970") AS "1970", ROUND(CTE2."1980") AS "1980", ROUND(CTE2."1990") AS "1990", ROUND(CTE1."2000") AS "2000", 
	ROUND(CTE1."2010") AS "2010", ROUND(CTE1."2020") AS "2020"
FROM CTE1
JOIN CTE2
USING (state_code)
JOIN CTE3
USING (state_code)


--using JOIN (defaults to inner join)
--test query for gdp per capita w/ national gdp & pop numbers
with CTE1 AS
	(SELECT state_code, description, "2000"*1000000 AS "2000", "2010"*1000000 AS "2010", "2020"*1000000 AS "2020"
	FROM bea_gdp_97_22 AS g1
	WHERE state_code = 'US' AND description = 'All industry total'),
CTE2 AS
	(SELECT state_code, description, "2000", "2010", "2020"  
	FROM census_res_pop_10_20 AS c1
	WHERE state_code = 'US')
SELECT CTE1.state_code, 'gdp per capita' AS value, ROUND(CTE1."2000"/CTE2."2000") AS "2000", ROUND(CTE1."2010"/CTE2."2010") AS "2010", ROUND(CTE1."2020"/CTE2."2020") AS "2020"
FROM CTE1
JOIN CTE2
USING (state_code);

--gdp per capita review for states/nation 1970-2020 (by decade)
--using JOIN (defaults to inner join)
with CTE1 AS
	(SELECT state_code, description, "2000"*1000000 AS "2000", "2010"*1000000 AS "2010", "2020"*1000000 AS "2020"
	FROM bea_gdp_97_22 AS g1
	WHERE description = 'All industry total'),
CTE2 AS 
	(SELECT state_code, description, "1970"*1000000 AS "1970", "1980"*1000000 AS "1980", "1990"*1000000 AS "1990"
	FROM bea_gdp_63_97 AS g1
	WHERE description = 'All industry total'),
CTE3 AS
	(SELECT state_code, description, "1970", "1980", "1990", "2000", "2010", "2020"  
	FROM census_res_pop_10_20 AS c1
	)
SELECT CTE1.state_code, 'GDP per Capita' AS category, 'Dollars' AS unit,
	ROUND(CTE2."1970"/CTE3."1970") AS "1970", ROUND(CTE2."1980"/CTE3."1980") AS "1980", ROUND(CTE2."1990"/CTE3."1990") AS "1990", 				 	 ROUND(CTE1."2000"/CTE3."2000") AS "2000", ROUND(CTE1."2010"/CTE3."2010") AS "2010", ROUND(CTE1."2020"/CTE3."2020") AS "2020"
FROM CTE1
JOIN CTE2
USING (state_code)
JOIN CTE3
USING (state_code)

--consumption & production combined review for states/nation 1970-2020 (by decade)
SELECT state_code, INITCAP(category) AS category, unit, "1970", "1980", "1990", "2000", "2010", "2020"
FROM eia_production_mix 
WHERE type = 'Total energy'  
UNION
SELECT state_code, category, unit, "1970", "1980", "1990", "2000", "2010", "2020"
FROM eia_consumption_mix
WHERE type = 'Total energy'
ORDER BY state_code;


--combined gdp per capita, population, production, consumption review for states/nation 1970-2020 (by decade)
--single table
with CTE1 AS
	(SELECT state_code, description, "2000"*1000000 AS "2000", "2010"*1000000 AS "2010", "2020"*1000000 AS "2020"
	FROM bea_gdp_97_22 AS g1
	WHERE description = 'All industry total'),
CTE2 AS 
	(SELECT state_code, description, "1970"*1000000 AS "1970", "1980"*1000000 AS "1980", "1990"*1000000 AS "1990"
	FROM bea_gdp_63_97 AS g1
	WHERE description = 'All industry total'),
CTE3 AS
	(SELECT state_code, description, "1970", "1980", "1990", "2000", "2010", "2020"  
	FROM census_res_pop_10_20 AS c1
	)
SELECT CTE1.state_code, 'GDP per Capita' AS category, 'Dollars' AS unit,
	ROUND(CTE2."1970"/CTE3."1970") AS "1970", ROUND(CTE2."1980"/CTE3."1980") AS "1980", ROUND(CTE2."1990"/CTE3."1990") AS "1990", 				 	 ROUND(CTE1."2000"/CTE3."2000") AS "2000", ROUND(CTE1."2010"/CTE3."2010") AS "2010", ROUND(CTE1."2020"/CTE3."2020") AS "2020"
FROM CTE1
JOIN CTE2
USING (state_code)
JOIN CTE3
USING (state_code)
UNION 
SELECT state_code, INITCAP(category) AS category, unit, "1970", "1980", "1990", "2000", "2010", "2020"
	FROM eia_production_mix 
	WHERE type = 'Total energy'  
	UNION
SELECT state_code, category, unit, "1970", "1980", "1990", "2000", "2010", "2020"
	FROM eia_consumption_mix
	WHERE type = 'Total energy'
ORDER BY state_code, category;

--'VIEW' of above query built in question 3 / utilize for additional analysis of gdp, production, and consumption
SELECT *
FROM gdp_prod_consump_1;


--REMOVE BEFORE PUBLISH to GITHUB
/*
--MAX Consumption 1970
SELECT state_code, category, unit, "1970" 
FROM gdp_prod_consump_1
WHERE category = 'Consumption'  AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY state_code, category, unit, "1970" 
ORDER BY "1970" DESC
LIMIT 10

--MIN Consumption 1970
SELECT state_code, category, unit, "1970" 
FROM gdp_prod_consump_1
WHERE category = 'Consumption'  AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY state_code, category, unit, "1970" 
ORDER BY "1970" ASC
LIMIT 10

--MAX Production 1970
SELECT state_code, category, unit, "1970" 
FROM gdp_prod_consump_1
WHERE category = 'Production'  AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY state_code, category, unit, "1970" 
ORDER BY "1970" DESC
LIMIT 10

--MIN Production 1970
SELECT state_code, category, unit, "1970" 
FROM gdp_prod_consump_1
WHERE category = 'Production'  AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY state_code, category, unit, "1970" 
ORDER BY "1970" ASC
LIMIT 10

--MAX GDP per Capita 1970
SELECT state_code, category, unit, "1970" 
FROM gdp_prod_consump_1
WHERE category = 'GDP per Capita'  AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY state_code, category, unit, "1970" 
ORDER BY "1970" DESC
LIMIT 10

--MIN GDP per Capita 1970
SELECT state_code, category, unit, "1970" 
FROM gdp_prod_consump_1
WHERE category = 'GDP per Capita'  AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY state_code, category, unit, "1970" 
ORDER BY "1970" ASC
LIMIT 10

--WINDOWS FUNCTION  / RANK() for consumption 
SELECT state_code, category, unit, "1970",
	RANK() OVER (ORDER BY "1970" DESC) AS consumption_rank
FROM gdp_prod_consump_1
WHERE category = 'Consumption' AND state_code <> 'US' AND state_code <> 'DC';

--WINDOWS FUNCTION  / RANK() for production 
SELECT state_code, category, unit, "1970",
	RANK() OVER (ORDER BY "1970" DESC) AS production_rank
FROM gdp_prod_consump_1
WHERE category = 'Production' AND state_code <> 'US' AND state_code <> 'DC';

--WINDOWS FUNCTION  / RANK() for gdp per capita 
SELECT state_code, category, unit, "1970",
	RANK() OVER (ORDER BY "1970" DESC) AS production_rank
FROM gdp_prod_consump_1
WHERE category = 'GDP per Capita' AND state_code <> 'US' AND state_code <> 'DC';

--WINDOWS FUNCTION  / RANK() for consumption 1970-2020
SELECT state_code, category, unit, 
	"1970", RANK() OVER (ORDER BY "1970" DESC) AS rank_1970,
	"1980", RANK() OVER (ORDER BY "1980" DESC) AS rank_1980,
	"1990", RANK() OVER (ORDER BY "1990" DESC) AS rank_1990,
	"2000", RANK() OVER (ORDER BY "2000" DESC) AS rank_2000,
	"2010", RANK() OVER (ORDER BY "2010" DESC) AS rank_2010,
	"2020", RANK() OVER (ORDER BY "2020" DESC) AS rank_2020
FROM gdp_prod_consump_1
WHERE category = 'Consumption' AND state_code <> 'US' AND state_code <> 'DC';

--WINDOWS FUNCTION  / RANK() for production 1970-2020
SELECT state_code, category, unit, 
	"1970", RANK() OVER (ORDER BY "1970" DESC) AS rank_1970,
	"1980", RANK() OVER (ORDER BY "1980" DESC) AS rank_1980,
	"1990", RANK() OVER (ORDER BY "1990" DESC) AS rank_1990,
	"2000", RANK() OVER (ORDER BY "2000" DESC) AS rank_2000,
	"2010", RANK() OVER (ORDER BY "2010" DESC) AS rank_2010,
	"2020", RANK() OVER (ORDER BY "2020" DESC) AS rank_2020
FROM gdp_prod_consump_1
WHERE category = 'Production' AND state_code <> 'US' AND state_code <> 'DC';

----WINDOWS FUNCTION  / RANK() for gdp per capita 1970-2020
SELECT state_code, category, unit, 
	"1970", RANK() OVER (ORDER BY "1970" DESC) AS rank_1970,
	"1980", RANK() OVER (ORDER BY "1980" DESC) AS rank_1980,
	"1990", RANK() OVER (ORDER BY "1990" DESC) AS rank_1990,
	"2000", RANK() OVER (ORDER BY "2000" DESC) AS rank_2000,
	"2010", RANK() OVER (ORDER BY "2010" DESC) AS rank_2010,
	"2020", RANK() OVER (ORDER BY "2020" DESC) AS rank_2020
FROM gdp_prod_consump_1
WHERE category = 'GDP per Capita' AND state_code <> 'US' AND state_code <> 'DC';

--UNION above WINDOWS FUNCTION  / RANK() to create consolidated table with ranks for each category and decade
SELECT state_code, category, unit, 
	"1970", RANK() OVER (ORDER BY "1970" DESC) AS rank_1970,
	"1980", RANK() OVER (ORDER BY "1980" DESC) AS rank_1980,
	"1990", RANK() OVER (ORDER BY "1990" DESC) AS rank_1990,
	"2000", RANK() OVER (ORDER BY "2000" DESC) AS rank_2000,
	"2010", RANK() OVER (ORDER BY "2010" DESC) AS rank_2010,
	"2020", RANK() OVER (ORDER BY "2020" DESC) AS rank_2020
FROM gdp_prod_consump_1
WHERE category = 'Consumption' AND state_code <> 'US' AND state_code <> 'DC'
UNION
SELECT state_code, category, unit, 
	"1970", RANK() OVER (ORDER BY "1970" DESC) AS rank_1970,
	"1980", RANK() OVER (ORDER BY "1980" DESC) AS rank_1980,
	"1990", RANK() OVER (ORDER BY "1990" DESC) AS rank_1990,
	"2000", RANK() OVER (ORDER BY "2000" DESC) AS rank_2000,
	"2010", RANK() OVER (ORDER BY "2010" DESC) AS rank_2010,
	"2020", RANK() OVER (ORDER BY "2020" DESC) AS rank_2020
FROM gdp_prod_consump_1
WHERE category = 'Production' AND state_code <> 'US' AND state_code <> 'DC'
UNION
SELECT state_code, category, unit, 
	"1970", RANK() OVER (ORDER BY "1970" DESC) AS rank_1970,
	"1980", RANK() OVER (ORDER BY "1980" DESC) AS rank_1980,
	"1990", RANK() OVER (ORDER BY "1990" DESC) AS rank_1990,
	"2000", RANK() OVER (ORDER BY "2000" DESC) AS rank_2000,
	"2010", RANK() OVER (ORDER BY "2010" DESC) AS rank_2010,
	"2020", RANK() OVER (ORDER BY "2020" DESC) AS rank_2020
FROM gdp_prod_consump_1
WHERE category = 'GDP per Capita' AND state_code <> 'US' AND state_code <> 'DC';
*/

--WINDOWS FUNCTION  / RANK() w/ PARTITION BY 1970-2020
--This function ranks each state by category for each decade column
--RANK() w/ PARTITION BY creates a single table that replaces the need for multiple RANK() queries and consolidating tables with UNION
SELECT state_code, category, unit, 
	"1970", RANK() OVER (PARTITION BY category ORDER BY "1970" DESC) AS rank_1970,
	"1980", RANK() OVER (PARTITION BY category ORDER BY "1980" DESC) AS rank_1980,
	"1990", RANK() OVER (PARTITION BY category ORDER BY "1990" DESC) AS rank_1990,
	"2000", RANK() OVER (PARTITION BY category ORDER BY "2000" DESC) AS rank_2000,
	"2010", RANK() OVER (PARTITION BY category ORDER BY "2010" DESC) AS rank_2010,
	"2020", RANK() OVER (PARTITION BY category ORDER BY "2020" DESC) AS rank_2020
FROM gdp_prod_consump_1
WHERE state_code <> 'US' AND state_code <> 'DC';

--create 'VIEW' of WINDOWS FUNCTION  / RANK() w/ PARTITION BY to enable additional filtering and analysis
CREATE VIEW gdp_prod_consump_ranks AS
SELECT state_code, category, unit, 
	"1970", RANK() OVER (PARTITION BY category ORDER BY "1970" DESC) AS rank_1970,
	"1980", RANK() OVER (PARTITION BY category ORDER BY "1980" DESC) AS rank_1980,
	"1990", RANK() OVER (PARTITION BY category ORDER BY "1990" DESC) AS rank_1990,
	"2000", RANK() OVER (PARTITION BY category ORDER BY "2000" DESC) AS rank_2000,
	"2010", RANK() OVER (PARTITION BY category ORDER BY "2010" DESC) AS rank_2010,
	"2020", RANK() OVER (PARTITION BY category ORDER BY "2020" DESC) AS rank_2020
FROM gdp_prod_consump_1
WHERE state_code <> 'US' AND state_code <> 'DC';

--review gdp_prod_consump_ranks 'VIEW'
SELECT *
FROM gdp_prod_consump_ranks;

--create 'VIEW' that includes population data 
--combine gdp per capita, population, production, consumption for states/nation 1970-2020 (by decade) in single table
--utilize to re-execute WINDOWS FUNCTION  / RANK() w/ PARTITION that includes population info 1970-2020
CREATE VIEW consump_gdp_pop_prod AS
with CTE1 AS
	(SELECT state_code, description, "2000"*1000000 AS "2000", "2010"*1000000 AS "2010", "2020"*1000000 AS "2020"
	FROM bea_gdp_97_22 AS g1
	WHERE description = 'All industry total'),
CTE2 AS 
	(SELECT state_code, description, "1970"*1000000 AS "1970", "1980"*1000000 AS "1980", "1990"*1000000 AS "1990"
	FROM bea_gdp_63_97 AS g1
	WHERE description = 'All industry total'),
CTE3 AS
	(SELECT state_code, description, "1970", "1980", "1990", "2000", "2010", "2020"  
	FROM census_res_pop_10_20 AS c1
	)
SELECT CTE1.state_code, 'GDP per Capita' AS category, 'Dollars' AS unit,
	ROUND(CTE2."1970"/CTE3."1970") AS "1970", ROUND(CTE2."1980"/CTE3."1980") AS "1980", ROUND(CTE2."1990"/CTE3."1990") AS "1990", 				 	 	
	ROUND(CTE1."2000"/CTE3."2000") AS "2000", ROUND(CTE1."2010"/CTE3."2010") AS "2010", ROUND(CTE1."2020"/CTE3."2020") AS "2020"
FROM CTE1
JOIN CTE2
USING (state_code)
JOIN CTE3
USING (state_code)
UNION 
SELECT state_code, INITCAP(category) AS category, unit, "1970", "1980", "1990", "2000", "2010", "2020"
FROM eia_production_mix 
WHERE type = 'Total energy'  
UNION
SELECT state_code, category, unit, "1970", "1980", "1990", "2000", "2010", "2020"
FROM eia_consumption_mix
WHERE type = 'Total energy'
UNION
SELECT state_code, 'Population' AS category, 'Individual Person' AS unit, "1970", "1980", "1990", "2000", "2010", "2020"   
FROM census_res_pop_10_20
WHERE geo_type = 'Nation' OR geo_type = 'State' AND state_code <> 'PR'
ORDER BY state_code, category;

--review consump_gdp_pop_prod 'VIEW'
SELECT *
FROM consump_gdp_pop_prod;

--US National consump_gdp_pop_prod 
--export to csv for additional analysis and visualization 'q1_us_consump_gdp_pop_prod'
SELECT *
FROM consump_gdp_pop_prod
WHERE state_code = 'US'
ORDER BY state_code, category;


--***********************************************************************
--***********************************************************************
--Primary Data View for Additional Analysis and Visualization
--Question 1. How does energy production and consumption compare to GDP per capita at the state and national level?
--***********************************************************************
--***********************************************************************

--re-execute WINDOWS FUNCTION  / RANK() w/ PARTITION that includes population info 1970-2020 to enable additional filtering and analysis
CREATE VIEW consump_gdp_pop_prod_ranks AS
SELECT state_code, category, unit, 
	"1970", RANK() OVER (PARTITION BY category ORDER BY "1970" DESC) AS rank_1970,
	"1980", RANK() OVER (PARTITION BY category ORDER BY "1980" DESC) AS rank_1980,
	"1990", RANK() OVER (PARTITION BY category ORDER BY "1990" DESC) AS rank_1990,
	"2000", RANK() OVER (PARTITION BY category ORDER BY "2000" DESC) AS rank_2000,
	"2010", RANK() OVER (PARTITION BY category ORDER BY "2010" DESC) AS rank_2010,
	"2020", RANK() OVER (PARTITION BY category ORDER BY "2020" DESC) AS rank_2020
FROM consump_gdp_pop_prod
WHERE state_code <> 'US' AND state_code <> 'DC';

--review consump_gdp_pop_prod_ranks 'VIEW'
--export to csv for data visualization 'q1_consump_gdp_pop_prod'
SELECT *
FROM consump_gdp_pop_prod_ranks;

--align eia_expenditures_total in same format as queries / tables above
--creat 'VIEW' for additional analysis

SELECT *
FROM eia_expenditures_total;

CREATE VIEW eia_50st_us_expenditures_total_view AS
SELECT state_code, INITCAP(description) AS category, 'Dollars' AS unit, "1970"*1000000 AS "1970", "1980"*1000000 AS "1980", "1990"*1000000 AS "1990", 
	"2000"*1000000 AS "2000", "2010"*1000000 AS "2010", "2020"*1000000 AS "2020"
FROM eia_expenditures_total
WHERE state_code <> 'DC'
ORDER BY state_code, category;



--##
--Question 2. What differences in the mix of energy (fossil fuels, nuclear, and renewable energy) and consumption rates can be identified across the states. What contributes to these differences?

--table review / prep for question 2 queries 
SELECT state_code, category, type, unit, "1970", "1980", "1990", "2000", "2010", "2020"
FROM eia_consumption_mix
--WHERE state_code = 'US' OR state_code = 'AZ' OR state_code = 'OK'
ORDER BY state_code, type;

--query to filter/consolidate info for energy type: fossil fuel
SELECT state_code, category, SUM("1970") AS "1970-FF", SUM("1980") AS "1980-FF", SUM("1990") AS "1990-FF", SUM("2000") AS "2000-FF", 
	SUM("2010") AS "2010-FF", SUM("2020") AS "2020-FF"
FROM eia_consumption_mix
WHERE type = 'Coal' OR type = 'Natural Gas' OR type = 'Petroleum' 
GROUP BY state_code, category
ORDER BY state_code;

--query to filter/consolidate info for energy type: nuclear
SELECT state_code, category, unit, SUM("1970") AS "1970-NUC", SUM("1980") AS "1980-NUC", SUM("1990") AS "1990-NUC", SUM("2000") AS "2000-NUC", 
	SUM("2010") AS "2010-NUC", SUM("2020") AS "2020-NUC"
FROM eia_consumption_mix
WHERE type = 'Nuclear' 
GROUP BY state_code, category, unit
ORDER BY state_code;

--query to consolidate info for energy type: renewable
SELECT state_code, category, unit, SUM("1970") AS "1970-RNW", SUM("1980") AS "1980-RNW", SUM("1990") AS "1990-RNW", SUM("2000") AS "2000-RNW", 
	SUM("2010") AS "2010-RNW", SUM("2020") AS "2020-RNW"
FROM eia_consumption_mix
WHERE type = 'Biomass' OR type = 'Geothermal' OR type = 'Hydropower' OR type = 'Solar' OR type = 'Wind'
GROUP BY state_code, category, unit
ORDER BY state_code;
--OR
SELECT state_code, category, unit, "1970" AS "1970-RNW", "1980" AS "1980-RNW", "1990" AS "1990-RNW", "2000" AS "2000-RNW", 
	"2010" AS "2010-RNW", "2020" AS "2020-RNW"
FROM eia_consumption_mix
WHERE type = 'Renewable'
GROUP BY state_code, category, unit, "1970", "1980", "1990", "2000", "2010", "2020"
ORDER BY state_code;


--##CONSUMPTION##...create consolidated chart for fossil fuel, nuclear, and renewable consumption by state/nation
--NOTE: eia tables for production and consumption use the same information for nuclear "Nuclear energy consumed for electricity generation" (same values both tables)
--union queries adjust column titles and category
SELECT state_code, 'Fossil Fuel-Consumption' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_consumption_mix
WHERE type = 'Coal' OR type = 'Natural Gas' OR type = 'Petroleum' 
GROUP BY state_code, category, unit
UNION
SELECT state_code, 'Nuclear-Consumption' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_consumption_mix
WHERE type = 'Nuclear' 
GROUP BY state_code, category, unit
UNION
SELECT state_code, 'Renewable-Consumption' AS category, unit, SUM("1970") AS "1970-RNW", SUM("1980") AS "1980-RNW", SUM("1990") AS "1990-RNW", SUM("2000") AS "2000-RNW", 
	SUM("2010") AS "2010-RNW", SUM("2020") AS "2020-RNW"
FROM eia_consumption_mix
WHERE type = 'Biomass' OR type = 'Geothermal' OR type = 'Hydropower' OR type = 'Solar' OR type = 'Wind'
GROUP BY state_code, category, unit
UNION
SELECT state_code, 'Total Energy-Consumption' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_consumption_mix
WHERE type = 'Total energy' 
GROUP BY state_code, category, unit
ORDER BY state_code, category;


--##PRODUCTION##...create consolidated chart for fossil fuel, nuclear, and renewable production by state/nation
--NOTE: eia tables for production and consumption use the same information for nuclear "Nuclear energy consumed for electricity generation" (same values both tables)
--union queries adjust column titles and category
SELECT state_code, 'Fossil Fuel-Production' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_production_mix
WHERE type = 'Coal' OR type = 'Natural Gas' OR type = 'Crude Oil'  
GROUP BY state_code, category, unit
/*
--REMOVE: NOT NEEDED
UNION
SELECT state_code, 'Nuclear*Consumed for Electrical Generation*' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_production_mix
WHERE type = 'Nuclear' 
GROUP BY state_code, category, unit
*/
UNION
SELECT state_code, 'Renewable-Production' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_production_mix
WHERE type = 'Biomass' OR type = 'Wood and Waste' OR type = 'Other renewable'
GROUP BY state_code, category, unit
UNION
SELECT state_code, 'Total Energy-Production' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_production_mix
WHERE type = 'Total energy' 
GROUP BY state_code, category, unit
ORDER BY state_code, category;


--##PRODUCTION & CONSUMPTION##...create consolidated 'VIEW' for fossil fuel, nuclear, and renewable production & consumption by state/nation
--union queries adjust column titles and category
--NOTE: eia tables for production and consumption use the same information for nuclear "Nuclear energy consumed for electricity generation" (same values both tables)
--'CREATE VIEW' to utilize as base table for additional analysis
CREATE VIEW pc_consolidated_energy_mix AS
SELECT state_code, 'Fossil Fuel-Consumption' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_consumption_mix
WHERE type = 'Coal' OR type = 'Natural Gas' OR type = 'Petroleum' 
GROUP BY state_code, category, unit
UNION
SELECT state_code, 'Nuclear-Consumption' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_consumption_mix
WHERE type = 'Nuclear'
GROUP BY state_code, category, unit
UNION
SELECT state_code, 'Renewable-Consumption' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
 	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_consumption_mix
WHERE type = 'Renewable' 
GROUP BY state_code, category, unit
UNION
SELECT state_code, 'Fossil Fuel-Production' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_production_mix
WHERE type = 'Coal' OR type = 'Natural Gas' OR type = 'Crude Oil'  
GROUP BY state_code, category, unit
UNION
SELECT state_code, 'Renewable-Production' AS category, unit, SUM("1970") AS "1970", SUM("1980") AS "1980", SUM("1990") AS "1990", SUM("2000") AS "2000", 
 	SUM("2010") AS "2010", SUM("2020") AS "2020"
FROM eia_production_mix
WHERE type = 'Renewable' OR type = 'Wood and Waste' OR type = 'Other renewable'
GROUP BY state_code, category, unit
ORDER BY state_code, category;

--review pc_consolidated_energy_mix 'VIEW'
--NOTE: eia tables for production and consumption use the same information for nuclear "Nuclear energy consumed for electricity generation" (same values both tables)
SELECT *
FROM pc_consolidated_energy_mix;

--review us energy mix
--export to csv for additional analysis and visualization
SELECT *
FROM pc_consolidated_energy_mix
WHERE state_code = 'US'
ORDER BY state_code, category;

--***********************************************************************
--***********************************************************************
--Primary Data View for Additional Analysis and Visualization
--Question 2. What differences in the mix of energy (fossil fuels, nuclear, and renewable energy) and consumption rates can be identified across the states. 
--What contributes to these differences?
--***********************************************************************
--***********************************************************************

--WINDOWS FUNCTION  / RANK() w/ PARTITION BY rank consumption and production by state for energy mix 1970-2020
--This function ranks each state by category for each decade column
CREATE VIEW consump_prod_consolidated_energy_mix_ranks AS
SELECT state_code, category, unit, 
	"1970", RANK() OVER (PARTITION BY category ORDER BY "1970" DESC) AS "rank_1970",
	"1980", RANK() OVER (PARTITION BY category ORDER BY "1980" DESC) AS "rank_1980",
	"1990", RANK() OVER (PARTITION BY category ORDER BY "1990" DESC) AS "rank_1990",
	"2000", RANK() OVER (PARTITION BY category ORDER BY "2000" DESC) AS "rank_2000",
	"2010", RANK() OVER (PARTITION BY category ORDER BY "2010" DESC) AS "rank_2010",
	"2020", RANK() OVER (PARTITION BY category ORDER BY "2020" DESC) AS "rank_2020"
FROM pc_consolidated_energy_mix
WHERE state_code <> 'US' AND state_code <> 'DC';

--review consump_prod_consolidated_energy_mix_ranks 'VIEW'
--export to csv for data visualization
SELECT *
FROM consump_prod_consolidated_energy_mix_ranks;

--##
--Question 3. What states have seen the greatest and least amount of growth in GDP per capita when compared to corresponding years for production and consumption of energy (considering all energy sources combined and fossil fuels, nuclear, and renewable energy separately)?

--combined gdp per capita, production, consumption review for states/nation 1970-2020 (by decade)
--single table
--'CREATE VIEW' to utilize as base table for additional analysis
--original query developed in question 1
CREATE VIEW gdp_prod_consump_1 AS
with CTE1 AS
	(SELECT state_code, description, "2000"*1000000 AS "2000", "2010"*1000000 AS "2010", "2020"*1000000 AS "2020"
	FROM bea_gdp_97_22 AS g1
	WHERE description = 'All industry total'),
CTE2 AS 
	(SELECT state_code, description, "1970"*1000000 AS "1970", "1980"*1000000 AS "1980", "1990"*1000000 AS "1990"
	FROM bea_gdp_63_97 AS g1
	WHERE description = 'All industry total'),
CTE3 AS
	(SELECT state_code, description, "1970", "1980", "1990", "2000", "2010", "2020"  
	FROM census_res_pop_10_20 AS c1
	)
SELECT CTE1.state_code, 'GDP per Capita' AS category, 'Dollars' AS unit,
	ROUND(CTE2."1970"/CTE3."1970") AS "1970", ROUND(CTE2."1980"/CTE3."1980") AS "1980", ROUND(CTE2."1990"/CTE3."1990") AS "1990", 				 	 ROUND(CTE1."2000"/CTE3."2000") AS "2000", ROUND(CTE1."2010"/CTE3."2010") AS "2010", ROUND(CTE1."2020"/CTE3."2020") AS "2020"
FROM CTE1
JOIN CTE2
USING (state_code)
JOIN CTE3
USING (state_code)
UNION 
SELECT state_code, INITCAP(category) AS category, unit, "1970", "1980", "1990", "2000", "2010", "2020"
	FROM eia_production_mix 
	WHERE type = 'Total energy'  
	UNION
SELECT state_code, category, unit, "1970", "1980", "1990", "2000", "2010", "2020"
	FROM eia_consumption_mix
	WHERE type = 'Total energy'
ORDER BY state_code, category;

--review created view
SELECT *
FROM gdp_prod_consump_1;

--calculate amount of change between decades for consumption, production, and gdp per capita
SELECT state_code, category, unit,
	"1980"-"1970" AS chg_70_80,
	"1990"-"1980" AS chg_80_90,
	"2000"-"1990" AS chg_90_00,
	"2010"-"2000" AS chg_00_10,
	"2020"-"2010" AS chg_10_20
FROM gdp_prod_consump_1;

--calculate percentage of change between decades for consumption, production, and gdp per capita
SELECT state_code, category, unit,
	ROUND((("1980"-"1970") / ("1980"+"1970"/2))*100,2) AS pct_chg_70_80,
	ROUND((("1990"-"1980") / ("1990"+"1980"/2))*100,2) AS pct_chg_80_90,
	ROUND((("2000"-"1990") / ("2000"+"1990"/2))*100,2) AS pct_chg_90_00,
	ROUND((("2010"-"2000") / ("2010"+"2000"/2))*100,2) AS pct_chg_00_10,
	ROUND((("2020"-"2010") / ("2020"+"2010"/2))*100,2) AS pct_chg_10_20
FROM gdp_prod_consump_1;

--utilize 'VIEW' pc_consolidated_energy_mix from Question 2 to review change in consumption/production across the decades
--review consolidated_energy_mix view
--NOTE: eia tables for production and consumption use the same information for nuclear "Nuclear energy consumed for electricity generation" (same values both tables)
SELECT *
FROM pc_consolidated_energy_mix;

--calculate amount of change between decades for consolidated_energy_mix (consumption/production) mix 
--NOTE: eia tables for production and consumption use the same information for nuclear "Nuclear energy consumed for electricity generation" (same values both tables)
--remove 'category Nuclear-Production' from view
--'Total Energy-Production & Total Energy-Consumption' captured in previously captured...remove from view
SELECT state_code, category, unit,
	"1980"-"1970" AS chg_70_80,
	"1990"-"1980" AS chg_80_90,
	"2000"-"1990" AS chg_90_00,
	"2010"-"2000" AS chg_00_10,
	"2020"-"2010" AS chg_10_20
FROM pc_consolidated_energy_mix;

--create 'VIEW' to replace for additional analysis
CREATE VIEW amt_chg_70_20 AS
SELECT state_code, category, unit,
	"1980"-"1970" AS chg_70_80,
	"1990"-"1980" AS chg_80_90,
	"2000"-"1990" AS chg_90_00,
	"2010"-"2000" AS chg_00_10,
	"2020"-"2010" AS chg_10_20
FROM pc_consolidated_energy_mix;


--review 'VIEW' amt_chg_70_20
SELECT *
FROM amt_chg_70_20;

--***********************************************************************
--***********************************************************************
----Primary Data View for Additional Analysis and Visualization
--Question 3. What states have seen the greatest and least amount of growth in GDP per capita when compared to corresponding years for production and consumption of energy (considering all energy sources combined and fossil fuels, nuclear, and renewable energy separately)?
--***********************************************************************
--***********************************************************************

--WINDOWS FUNCTION  / RANK() w/ PARTITION BY review change in amount of consumption and production for energy mix 1970-2020
--This function ranks each state by category for each decade column
CREATE VIEW chg_consump_prod_consolidated_energy_mix_ranks AS
SELECT state_code, category, unit, 
	"chg_70_80", RANK() OVER (PARTITION BY category ORDER BY "chg_70_80" DESC) AS rank_chg_70_80,
	"chg_80_90", RANK() OVER (PARTITION BY category ORDER BY "chg_80_90" DESC) AS rank_chg_80_90,
	"chg_90_00", RANK() OVER (PARTITION BY category ORDER BY "chg_90_00" DESC) AS rank_chg_90_00,
	"chg_00_10", RANK() OVER (PARTITION BY category ORDER BY "chg_00_10" DESC) AS rank_chg_00_10,
	"chg_10_20", RANK() OVER (PARTITION BY category ORDER BY "chg_10_20" DESC) AS rank_chg_10_20
FROM amt_chg_70_20
WHERE state_code <> 'US' AND state_code <> 'DC';

--review chg_consump_prod_consolidated_energy_mix_ranks 'VIEW'
--export to csv for data visualization
SELECT *
FROM chg_consump_prod_consolidated_energy_mix_ranks;

--query for avg amount of change for FOSSIL FUEL CONSUMPTION across the decades
SELECT category, unit, ROUND(AVG(chg_70_80),2) AS avg_amt_chg_70_80, ROUND(AVG(chg_80_90),2) AS avg_amt_chg_80_90, 
	ROUND(AVG(chg_90_00),2) AS avg_amt_chg_90_00, ROUND(AVG(chg_00_10),2) AS avg_amt_chg_00_10, ROUND(AVG(chg_10_20),2) AS avg_amt_chg_10_20
FROM amt_chg_70_20
WHERE category = 'Fossil Fuel-Consumption' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit

--query for avg amount of change for FOSSIL FUEL PRODUCTION across the decades
SELECT category, unit, ROUND(AVG(chg_70_80),2) AS avg_amt_chg_70_80, ROUND(AVG(chg_80_90),2) AS avg_amt_chg_80_90, 
	ROUND(AVG(chg_90_00),2) AS avg_amt_chg_90_00, ROUND(AVG(chg_00_10),2) AS avg_amt_chg_00_10, ROUND(AVG(chg_10_20),2) AS avg_amt_chg_10_20
FROM amt_chg_70_20
WHERE category = 'Fossil Fuel-Production' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit

--query for avg amount of change for NUCLEAR CONSUMPTION across the decades
SELECT category, unit, ROUND(AVG(chg_70_80),2) AS avg_amt_chg_70_80, ROUND(AVG(chg_80_90),2) AS avg_amt_chg_80_90, 
	ROUND(AVG(chg_90_00),2) AS avg_amt_chg_90_00, ROUND(AVG(chg_00_10),2) AS avg_amt_chg_00_10, ROUND(AVG(chg_10_20),2) AS avg_amt_chg_10_20
FROM amt_chg_70_20
WHERE category = 'Nuclear-Consumption' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit

--query for avg amount of change for RENEWABLE CONSUMPTION across the decades
SELECT category, unit, ROUND(AVG(chg_70_80),2) AS avg_amt_chg_70_80, ROUND(AVG(chg_80_90),2) AS avg_amt_chg_80_90, 
	ROUND(AVG(chg_90_00),2) AS avg_amt_chg_90_00, ROUND(AVG(chg_00_10),2) AS avg_amt_chg_00_10, ROUND(AVG(chg_10_20),2) AS avg_amt_chg_10_20
FROM amt_chg_70_20
WHERE category = 'Renewable-Consumption' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit

--query for avg amount of change for RENEWABLE PRODUCTION across the decades
SELECT category, unit, ROUND(AVG(chg_70_80),2) AS avg_amt_chg_70_80, ROUND(AVG(chg_80_90),2) AS avg_amt_chg_80_90, 
	ROUND(AVG(chg_90_00),2) AS avg_amt_chg_90_00, ROUND(AVG(chg_00_10),2) AS avg_amt_chg_00_10, ROUND(AVG(chg_10_20),2) AS avg_amt_chg_10_20
FROM amt_chg_70_20
WHERE category = 'Renewable-Production' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit

--***********************************************************************
--***********************************************************************
--Average Amount of Change in Energy Mix: 50 State & National Average Consolidated in 5 Rows
--Question 3. What states have seen the greatest and least amount of growth in GDP per capita when compared to corresponding years for production and consumption of energy (considering all energy sources combined and fossil fuels, nuclear, and renewable energy separately)?
--***********************************************************************
--***********************************************************************

--UNION avg amount of change queries to create consolidated table for 50 STATE AVERAGE
--export to csv '50_state_avg_amt_chg_consump_prod_consolidated_energy_mix_ranks'
SELECT '50 State Average' AS description, category, unit, ROUND(AVG(chg_70_80),2) AS avg_amt_chg_70_80, ROUND(AVG(chg_80_90),2) AS avg_amt_chg_80_90, 
	ROUND(AVG(chg_90_00),2) AS avg_amt_chg_90_00, ROUND(AVG(chg_00_10),2) AS avg_amt_chg_00_10, ROUND(AVG(chg_10_20),2) AS avg_amt_chg_10_20
FROM amt_chg_70_20
WHERE category = 'Fossil Fuel-Consumption' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit
UNION
SELECT '50 State Average' AS description, category, unit, ROUND(AVG(chg_70_80),2) AS avg_amt_chg_70_80, ROUND(AVG(chg_80_90),2) AS avg_amt_chg_80_90, 
	ROUND(AVG(chg_90_00),2) AS avg_amt_chg_90_00, ROUND(AVG(chg_00_10),2) AS avg_amt_chg_00_10, ROUND(AVG(chg_10_20),2) AS avg_amt_chg_10_20
FROM amt_chg_70_20
WHERE category = 'Fossil Fuel-Production' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit
UNION
SELECT '50 State Average' AS description, category, unit, ROUND(AVG(chg_70_80),2) AS avg_amt_chg_70_80, ROUND(AVG(chg_80_90),2) AS avg_amt_chg_80_90, 
	ROUND(AVG(chg_90_00),2) AS avg_amt_chg_90_00, ROUND(AVG(chg_00_10),2) AS avg_amt_chg_00_10, ROUND(AVG(chg_10_20),2) AS avg_amt_chg_10_20
FROM amt_chg_70_20
WHERE category = 'Nuclear-Consumption' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit
UNION
SELECT '50 State Average' AS description, category, unit, ROUND(AVG(chg_70_80),2) AS avg_amt_chg_70_80, ROUND(AVG(chg_80_90),2) AS avg_amt_chg_80_90, 
	ROUND(AVG(chg_90_00),2) AS avg_amt_chg_90_00, ROUND(AVG(chg_00_10),2) AS avg_amt_chg_00_10, ROUND(AVG(chg_10_20),2) AS avg_amt_chg_10_20
FROM amt_chg_70_20
WHERE category = 'Renewable-Consumption' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit
UNION
SELECT '50 State Average' AS description, category, unit, ROUND(AVG(chg_70_80),2) AS avg_amt_chg_70_80, ROUND(AVG(chg_80_90),2) AS avg_amt_chg_80_90, 
	ROUND(AVG(chg_90_00),2) AS avg_amt_chg_90_00, ROUND(AVG(chg_00_10),2) AS avg_amt_chg_00_10, ROUND(AVG(chg_10_20),2) AS avg_amt_chg_10_20
FROM amt_chg_70_20
WHERE category = 'Renewable-Production' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit
ORDER BY category ASC;

--filter amount of change for US NATIONAL 
--export csv 'us_amt_chg_consump_prod_consolidated_energy_mix'
SELECT state_code AS description, category, unit, 
	chg_70_80 AS amt_chg_70_80 , chg_80_90 AS amt_chg_80_90 , chg_90_00 AS amt_chg_90_00, chg_00_10 AS amt_chg_00_10, chg_10_20 AS amt_chg_10_20
FROM amt_chg_70_20
WHERE state_code = 'US' 
GROUP BY category, unit, state_code, chg_70_80, chg_80_90, chg_90_00, chg_00_10, chg_10_20
ORDER BY category ASC;

--Question 4. What has been the growth rate at the state and national level for GDP per capita and production and consumption of energy (considering all energy sources combined and fossil fuels, nuclear, and renewable energy separately)?


--calculate percentage of change between decades for for consolidated_energy_mix (consumption/production) mix
--NOTE: eia tables for production and consumption use the same information for nuclear "Nuclear energy consumed for electricity generation" (same values both tables)
--remove 'category Nuclear-Production' from view
--'Total Energy-Production & Total Energy-Consumption' captured in prior query 
--ADDED NULLIF() to correct divide by zero error
SELECT state_code, category, unit,
	ROUND((NULLIF(("1980"-"1970"),0) / ("1980"+"1970"/2))*100,2) AS pct_chg_70_80,
	ROUND((NULLIF(("1990"-"1980"),0) / ("1990"+"1980"/2))*100,2) AS pct_chg_80_90,
	ROUND((NULLIF(("2000"-"1990"),0) / ("2000"+"1990"/2))*100,2) AS pct_chg_90_00,
	ROUND((NULLIF(("2010"-"2000"),0) / ("2010"+"2000"/2))*100,2) AS pct_chg_00_10,
	ROUND((NULLIF(("2020"-"2010"),0) / ("2020"+"2010"/2))*100,2) AS pct_chg_10_20
FROM pc_consolidated_energy_mix;

--create 'VIEW' to replace NULL w/ ZERO (0) and conduct additional analysis
CREATE VIEW pct_chg_70_20_1 AS
SELECT state_code, category, unit,
	ROUND((NULLIF(("1980"-"1970"),0) / ("1980"+"1970"/2))*100,2) AS pct_chg_70_80,
	ROUND((NULLIF(("1990"-"1980"),0) / ("1990"+"1980"/2))*100,2) AS pct_chg_80_90,
	ROUND((NULLIF(("2000"-"1990"),0) / ("2000"+"1990"/2))*100,2) AS pct_chg_90_00,
	ROUND((NULLIF(("2010"-"2000"),0) / ("2010"+"2000"/2))*100,2) AS pct_chg_00_10,
	ROUND((NULLIF(("2020"-"2010"),0) / ("2020"+"2010"/2))*100,2) AS pct_chg_10_20
FROM pc_consolidated_energy_mix;

--create 'VIEW' use COALESCE to replace NULL values
CREATE VIEW pct_chg_70_20_cln AS
SELECT state_code, category, unit, 
	COALESCE(pct_chg_70_80,0) AS pct_chg_70_80, COALESCE(pct_chg_80_90,0) AS pct_chg_80_90, COALESCE(pct_chg_90_00,0) pct_chg_90_00, 
	COALESCE(pct_chg_00_10,0) AS pct_chg_00_10, COALESCE(pct_chg_10_20,0) AS pct_chg_10_20
FROM pct_chg_70_20_1;

--review 'VIEW' pct_chg_70_20_cln
SELECT *
FROM pct_chg_70_20_cln;

/*
--REMOVE BEFORE PUBLISHING TO GITHUB
--top 10 / bottom 10 percent of change FOSSIL FUEL CONSUMPTION 70-80
SELECT state_code, category, pct_chg_70_80
FROM pct_chg_70_20_cln
WHERE category = 'Fossil Fuel-Consumption'  AND state_code <> 'US' AND state_code <> 'DC'
ORDER BY pct_chg_70_80 DESC
LIMIT 10;

SELECT state_code, category, pct_chg_70_80
FROM pct_chg_70_20_cln
WHERE category = 'Fossil Fuel-Consumption'  AND state_code <> 'US' AND state_code <> 'DC'
ORDER BY pct_chg_70_80 ASC
LIMIT 10;

--HIGH to LOW percent of change FOSSIL FUEL CONSUMPTION 70-80
SELECT state_code, category, pct_chg_70_80
FROM pct_chg_70_20_cln
WHERE category = 'Fossil Fuel-Consumption'  AND state_code <> 'US' AND state_code <> 'DC'
ORDER BY pct_chg_70_80 DESC;
--LIMIT 10;
--****checking individual HIGH/LOW stats for each category and decade would result in 25 separate queries...figure out a better way to calc/display**** 
*/

--query for avg percent of change for FOSSIL FUEL CONSUMPTION across the decades
SELECT category, ROUND(AVG(pct_chg_70_80),2) AS avg_pct_chg_70_80, ROUND(AVG(pct_chg_80_90),2) AS avg_pct_chg_80_90, ROUND(AVG(pct_chg_90_00),2) AS avg_pct_chg_90_00,
	ROUND(AVG(pct_chg_00_10),2) AS avg_pct_chg_00_10, ROUND(AVG(pct_chg_10_20),2) AS avg_pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE category = 'Fossil Fuel-Consumption'  AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category;

--query for avg percent of change for FOSSIL FUEL PRODUCTION across the decades
SELECT category, ROUND(AVG(pct_chg_70_80),2) AS avg_pct_chg_70_80, ROUND(AVG(pct_chg_80_90),2) AS avg_pct_chg_80_90, ROUND(AVG(pct_chg_90_00),2) AS avg_pct_chg_90_00,
	ROUND(AVG(pct_chg_00_10),2) AS avg_pct_chg_00_10, ROUND(AVG(pct_chg_10_20),2) AS avg_pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE category = 'Fossil Fuel-Production' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category;

--query for avg percent of change for NUCLEAR CONSUMPTION across the decades
SELECT category, ROUND(AVG(pct_chg_70_80),2) AS avg_pct_chg_70_80, ROUND(AVG(pct_chg_80_90),2) AS avg_pct_chg_80_90, ROUND(AVG(pct_chg_90_00),2) AS avg_pct_chg_90_00,
	ROUND(AVG(pct_chg_00_10),2) AS avg_pct_chg_00_10, ROUND(AVG(pct_chg_10_20),2) AS avg_pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE category = 'Nuclear-Consumption' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category;

--query for avg percent of change for RENEWABLE CONSUMPTION across the decades
SELECT category, ROUND(AVG(pct_chg_70_80),2) AS avg_pct_chg_70_80, ROUND(AVG(pct_chg_80_90),2) AS avg_pct_chg_80_90, ROUND(AVG(pct_chg_90_00),2) AS avg_pct_chg_90_00,
	ROUND(AVG(pct_chg_00_10),2) AS avg_pct_chg_00_10, ROUND(AVG(pct_chg_10_20),2) AS avg_pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE category = 'Renewable-Consumption' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category;

--query for avg percent of change for RENEWABLE PRODUCTION across the decades  
SELECT category, ROUND(AVG(pct_chg_70_80),2) AS avg_pct_chg_70_80, ROUND(AVG(pct_chg_80_90),2) AS avg_pct_chg_80_90, ROUND(AVG(pct_chg_90_00),2) AS avg_pct_chg_90_00,
	ROUND(AVG(pct_chg_00_10),2) AS avg_pct_chg_00_10, ROUND(AVG(pct_chg_10_20),2) AS avg_pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE category = 'Renewable-Production' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category;

--***********************************************************************
--***********************************************************************
--Average Percent of Change in Energy Mix: 50 State & National Average Consolidated in 5 Rows
--Question 4. What has been the growth rate at the state and national level for GDP per capita and production and consumption of energy 
--(considering all energy sources combined and fossil fuels, nuclear, and renewable energy separately)?
--***********************************************************************
--***********************************************************************

--UNION avg percent of change queries to create consolidated table for 50 STATE AVERAGE
--export to csv '50_state_avg_pct_chg_consump_prod_consolidated_energy_mix_ranks'
SELECT '50 State Average' AS description, category, unit, ROUND(AVG(pct_chg_70_80),2) AS avg_pct_chg_70_80, ROUND(AVG(pct_chg_80_90),2) AS avg_pct_chg_80_90, 
	ROUND(AVG(pct_chg_90_00),2) AS avg_pct_chg_90_00, ROUND(AVG(pct_chg_00_10),2) AS avg_pct_chg_00_10, ROUND(AVG(pct_chg_10_20),2) AS avg_pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE category = 'Fossil Fuel-Consumption' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit
UNION
SELECT '50 State Average' AS description, category, unit, ROUND(AVG(pct_chg_70_80),2) AS avg_pct_chg_70_80, ROUND(AVG(pct_chg_80_90),2) AS avg_pct_chg_80_90, 
	ROUND(AVG(pct_chg_90_00),2) AS avg_pct_chg_90_00, ROUND(AVG(pct_chg_00_10),2) AS avg_pct_chg_00_10, ROUND(AVG(pct_chg_10_20),2) AS avg_pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE category = 'Fossil Fuel-Production' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit
UNION
SELECT '50 State Average' AS description, category, unit, ROUND(AVG(pct_chg_70_80),2) AS avg_pct_chg_70_80, ROUND(AVG(pct_chg_80_90),2) AS avg_pct_chg_80_90, 
	ROUND(AVG(pct_chg_90_00),2) AS avg_pct_chg_90_00, ROUND(AVG(pct_chg_00_10),2) AS avg_pct_chg_00_10, ROUND(AVG(pct_chg_10_20),2) AS avg_pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE category = 'Nuclear-Consumption' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit
UNION
SELECT '50 State Average' AS description, category, unit, ROUND(AVG(pct_chg_70_80),2) AS avg_pct_chg_70_80, ROUND(AVG(pct_chg_80_90),2) AS avg_pct_chg_80_90, 
	ROUND(AVG(pct_chg_90_00),2) AS avg_pct_chg_90_00, ROUND(AVG(pct_chg_00_10),2) AS avg_pct_chg_00_10, ROUND(AVG(pct_chg_10_20),2) AS avg_pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE category = 'Renewable-Consumption' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit
UNION
SELECT '50 State Average' AS description, category, unit, ROUND(AVG(pct_chg_70_80),2) AS avg_pct_chg_70_80, ROUND(AVG(pct_chg_80_90),2) AS avg_pct_chg_80_90, 
	ROUND(AVG(pct_chg_90_00),2) AS avg_pct_chg_90_00, ROUND(AVG(pct_chg_00_10),2) AS avg_pct_chg_00_10, ROUND(AVG(pct_chg_10_20),2) AS avg_pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE category = 'Renewable-Production' AND state_code <> 'US' AND state_code <> 'DC'
GROUP BY category, unit
ORDER BY category ASC;

--filter percent of change for US NATIONAL
--export to csv for data visualization 'us_pct_chg_consump_prod_consolidated_energy_mix_ranks'
SELECT state_code AS description, category, unit, pct_chg_70_80, pct_chg_80_90, pct_chg_90_00, pct_chg_00_10, pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE state_code = 'US' 
GROUP BY category, unit, state_code, pct_chg_70_80, pct_chg_80_90, pct_chg_90_00, pct_chg_00_10, pct_chg_10_20
ORDER BY category ASC;

--***********************************************************************
--***********************************************************************
--Primary Data View for Additional Analysis and Visualization
--Question 4. What has been the growth rate at the state and national level for GDP per capita and production and consumption of energy 
--(considering all energy sources combined and fossil fuels, nuclear, and renewable energy separately)?
--***********************************************************************
--***********************************************************************

--WINDOWS FUNCTION  / RANK() w/ PARTITION BY review percent change in consumption and production for energy mix 1970-2020
--This function ranks each state by category for each decade column
CREATE VIEW pct_chg_consump_prod_consolidated_energy_mix_ranks AS
SELECT state_code, category, unit, 
	"pct_chg_70_80", RANK() OVER (PARTITION BY category ORDER BY "pct_chg_70_80" DESC) AS rank_pct_chg_70_80,
	"pct_chg_80_90", RANK() OVER (PARTITION BY category ORDER BY "pct_chg_80_90" DESC) AS rank_pct_chg_80_90,
	"pct_chg_90_00", RANK() OVER (PARTITION BY category ORDER BY "pct_chg_90_00" DESC) AS rank_pct_chg_90_00,
	"pct_chg_00_10", RANK() OVER (PARTITION BY category ORDER BY "pct_chg_00_10" DESC) AS rank_pct_chg_00_10,
	"pct_chg_10_20", RANK() OVER (PARTITION BY category ORDER BY "pct_chg_10_20" DESC) AS rank_pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE state_code <> 'US' AND state_code <> 'DC';

--review pct_chg_consump_prod_consolidated_energy_mix_ranks 'VIEW'
--export to csv for data visualization 'q4_pct_chg_consump_prod_consolidated_energy_mix_ranks'
SELECT *
FROM pct_chg_consump_prod_consolidated_energy_mix_ranks;

--Question 5. Where have negative impacts been observed. Can additional contributing factors be identified?

--Question 6. What technological advances are spurring the most growth in non-fossil fuel energy and can an economic impact be determined?

--Question 7. Stretch Question: What are the projections for continued growth in non-fossil fuels and does this appear to have a positive impact on the future economy?


--***********************************************************************
--***********************************************************************
--Queries Adjusted to re-align columns and data for better Power BI Ingest and Visualizations
--Adjusting to 'STACKED DISPLAY / UNION' columns 1970 - 2020 and and column that assigns year to each row. 
--Utilize 'VIEW's to create FACT and AGGREGATION Tables for POWER BI
--***********************************************************************
--***********************************************************************


--***********************************************************************
--Question 1 Queries for Export
--***********************************************************************

--UNION queries to create stacked display of info (state_code, category, year, unit, amount)...ORDER BY state_code, category
--export to csv q1_us_50st_gdp_total_stacked
--CREATE VIEW q1_us_50st_gdp_total_stacked_view....use for consolidated POWER BI FACT table

CREATE VIEW q1_us_50st_gdp_total_stacked_view AS
SELECT state_code, description AS category,'1970' AS year, 'Dollars' as unit, "1970"*1000000 AS amount
FROM bea_gdp_63_97 
WHERE description = 'All industry total' AND state_code <> 'DC' AND state_code <> 'NWE' AND state_code <> 'MDE' AND state_code <> 'GL' AND state_code <> 'PL'
	AND state_code <> 'SE' AND state_code <> 'SW' AND state_code <> 'RK' AND state_code <> 'FW'
UNION
SELECT state_code, description AS category,'1980' AS year, 'Dollars' as unit, "1980"*1000000 AS amount
FROM bea_gdp_63_97 
WHERE description = 'All industry total' AND state_code <> 'DC' AND state_code <> 'NWE' AND state_code <> 'MDE' AND state_code <> 'GL' AND state_code <> 'PL'
	AND state_code <> 'SE' AND state_code <> 'SW' AND state_code <> 'RK' AND state_code <> 'FW'
UNION
SELECT state_code, description AS category,'1990' AS year, 'Dollars' as unit, "1990"*1000000 AS amount
FROM bea_gdp_63_97 
WHERE description = 'All industry total' AND state_code <> 'DC' AND state_code <> 'NWE' AND state_code <> 'MDE' AND state_code <> 'GL' AND state_code <> 'PL'
	AND state_code <> 'SE' AND state_code <> 'SW' AND state_code <> 'RK' AND state_code <> 'FW'
UNION
SELECT state_code, description AS category,'2000' AS year, 'Dollars' as unit, "2000"*1000000 AS amount 
FROM bea_gdp_97_22 
WHERE description = 'All industry total' AND state_code <> 'DC' AND state_code <> 'NWE' AND state_code <> 'MDE' AND state_code <> 'GL' AND state_code <> 'PL'
	AND state_code <> 'SE' AND state_code <> 'SW' AND state_code <> 'RK' AND state_code <> 'FW'
UNION
SELECT state_code, description AS category,'2010' AS year, 'Dollars' as unit, "2010"*1000000 AS amount 
FROM bea_gdp_97_22 
WHERE description = 'All industry total' AND state_code <> 'DC' AND state_code <> 'NWE' AND state_code <> 'MDE' AND state_code <> 'GL' AND state_code <> 'PL'
	AND state_code <> 'SE' AND state_code <> 'SW' AND state_code <> 'RK' AND state_code <> 'FW'
UNION
SELECT state_code, description AS category,'2020' AS year, 'Dollars' as unit, "2020"*1000000 AS amount 
FROM bea_gdp_97_22 AS g1
WHERE description = 'All industry total' AND state_code <> 'DC' AND state_code <> 'NWE' AND state_code <> 'MDE' AND state_code <> 'GL' AND state_code <> 'PL'
	AND state_code <> 'SE' AND state_code <> 'SW' AND state_code <> 'RK' AND state_code <> 'FW'
ORDER BY state_code, category;

--review 'VIEW'....Use for FACT Table Power BI
SELECT *
FROM q1_us_50st_gdp_total_stacked_view;

 
--export to csv 'q1_us_consump_gdp_pop_prod_stacked'
--UNION queries to create stacked display of info (state_code, category, year, unit, amount)...ORDER BY state_code, category
--export to csv 'q1_us_consump_gdp_pop_prod_stacked'
--CREATE VIEW q1_us_consump_gdp_pop_prod_stacked_view....use for consolidated POWER BI FACT table

--base query / national - US
SELECT *
FROM consump_gdp_pop_prod
WHERE state_code = 'US'
ORDER BY state_code, category;

CREATE VIEW q1_us_consump_gdp_pop_prod_stacked_view AS
SELECT state_code, category, '1970' AS year, unit, "1970" AS amount
FROM consump_gdp_pop_prod
WHERE state_code = 'US'
UNION
SELECT state_code, category, '1980' AS year, unit, "1980" AS amount
FROM consump_gdp_pop_prod
WHERE state_code = 'US'
UNION
SELECT state_code, category, '1990' AS year, unit, "1990" AS amount
FROM consump_gdp_pop_prod
WHERE state_code = 'US'
UNION
SELECT state_code, category, '2000' AS year, unit, "2000" AS amount
FROM consump_gdp_pop_prod
WHERE state_code = 'US'
UNION
SELECT state_code, category, '2010' AS year, unit, "2010" AS amount
FROM consump_gdp_pop_prod
WHERE state_code = 'US'
UNION
SELECT state_code, category, '2020' AS year, unit, "2020" AS amount
FROM consump_gdp_pop_prod
WHERE state_code = 'US'
ORDER BY state_code, category;

--review 'VIEW'....Use for FACT Table Power BI
SELECT *
FROM q1_us_consump_gdp_pop_prod_stacked_view;



--UNION queries to create stacked display of info (state_code, category, year, unit, amount, rank)...ORDER BY state_code, category
--export to csv 'q1_consump_gdp_pop_prod_ranks_stacked'...remove rank column after export
--CREATE VIEW q1_50st_consump_gdp_pop_prod_stacked_view....use for consolidated POWER BI FACT table

--base 'VIEW' / 50 states
SELECT *
FROM consump_gdp_pop_prod_ranks;

CREATE VIEW q1_50st_consump_gdp_pop_prod_stacked_view AS
SELECT state_code, category, '1970' AS year, unit, "1970" AS amount 
FROM consump_gdp_pop_prod_ranks
UNION
SELECT state_code, category, '1980' AS year, unit, "1980" AS amount 
FROM consump_gdp_pop_prod_ranks
UNION
SELECT state_code, category, '1990' AS year, unit, "1990" AS amount 
FROM consump_gdp_pop_prod_ranks
UNION
SELECT state_code, category, '2000' AS year, unit, "2000" AS amount 
FROM consump_gdp_pop_prod_ranks
UNION
SELECT state_code, category, '2010' AS year, unit, "2010" AS amount 
FROM consump_gdp_pop_prod_ranks
UNION
SELECT state_code, category, '2020' AS year, unit, "2020" AS amount 
FROM consump_gdp_pop_prod_ranks
ORDER BY state_code, category;

--review 'VIEW'....Use for FACT Table Power BI
SELECT *
FROM q1_50st_consump_gdp_pop_prod_stacked_view;


--create expenditure stacked view
--UNION queries to create stacked display of info (state_code, category, year, unit, amount, rank)...ORDER BY state_code, category
--CREATE VIEW q1_eia_50st_us_expenditures_total_stacked_view....use for consolidated POWER BI FACT table

--review 'VIEW'
SELECT *
FROM eia_50st_us_expenditures_total_view;

CREATE VIEW q1_eia_50st_us_expenditures_total_stacked_view AS
SELECT state_code, category, '1970' AS year, unit, "1970" AS amount
FROM eia_50st_us_expenditures_total_view
UNION
SELECT state_code, category, '1980' AS year, unit, "1980" AS amount
FROM eia_50st_us_expenditures_total_view
UNION
SELECT state_code, category, '1990' AS year, unit, "1990" AS amount
FROM eia_50st_us_expenditures_total_view
UNION
SELECT state_code, category, '2000' AS year, unit, "2000" AS amount
FROM eia_50st_us_expenditures_total_view
UNION
SELECT state_code, category, '2010' AS year, unit, "2010" AS amount
FROM eia_50st_us_expenditures_total_view
UNION
SELECT state_code, category, '2020' AS year, unit, "2020" AS amount
FROM eia_50st_us_expenditures_total_view
ORDER BY state_code, category;

--review 'VIEW'....Use for FACT Table Power BI
SELECT *
FROM q1_eia_50st_us_expenditures_total_stacked_view;

--***********************************************************************
--Question 2 Queries for Export
--***********************************************************************

--base 'VIEW' / 50 states
SELECT *
FROM consump_prod_consolidated_energy_mix_ranks;


--UNION queries to create stacked display of info (state_code, category, year, unit, amount, rank)...ORDER BY state_code, category
--export to csv 'q2_consump_prod_energy_mix_ranks_stacked'...remove rank column after export
--CREATE VIEW q2_50st_consump_prod_energy_mix_stacked_view....use for consolidated POWER BI FACT table

CREATE VIEW q2_50st_consump_prod_energy_mix_stacked_view AS
SELECT state_code, category, '1970' AS year, unit, "1970" AS amount 
FROM consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, '1980' AS year, unit, "1980" AS amount 
FROM consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, '1990' AS year, unit, "1990" AS amount 
FROM consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, '2000' AS year, unit, "2000" AS amount 
FROM consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, '2010' AS year, unit, "2010" AS amount 
FROM consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, '2020' AS year, unit, "2020" AS amount 
FROM consump_prod_consolidated_energy_mix_ranks
ORDER BY state_code, category;

--review 'VIEW'....Use for FACT Table Power BI
SELECT *
FROM q2_50st_consump_prod_energy_mix_stacked_view;


----base query / national - US
SELECT *
FROM pc_consolidated_energy_mix
WHERE state_code = 'US'
ORDER BY state_code, category;


--UNION queries to create stacked display of info (state_code, category, year, unit, amount)...ORDER BY state_code, category
--export to csv 'q2_us_consump_prod_consolidated_energy_mix_stacked'
--CREATE VIEW q2_us_consump_prod_consolidated_energy_mix_stacked_view....use for consolidated POWER BI FACT table

CREATE VIEW q2_us_consump_prod_consolidated_energy_mix_stacked_view AS
SELECT state_code, category, '1970' AS year, unit, "1970" AS amount
FROM pc_consolidated_energy_mix
WHERE state_code = 'US'
UNION
SELECT state_code, category, '1980' AS year, unit, "1980" AS amount
FROM pc_consolidated_energy_mix
WHERE state_code = 'US'
UNION
SELECT state_code, category, '1990' AS year, unit, "1990" AS amount
FROM pc_consolidated_energy_mix
WHERE state_code = 'US'
UNION
SELECT state_code, category, '2000' AS year, unit, "2000" AS amount
FROM pc_consolidated_energy_mix
WHERE state_code = 'US'
UNION
SELECT state_code, category, '2010' AS year, unit, "2010" AS amount
FROM pc_consolidated_energy_mix
WHERE state_code = 'US'
UNION
SELECT state_code, category, '2020' AS year, unit, "2020" AS amount
FROM pc_consolidated_energy_mix
WHERE state_code = 'US'
ORDER BY state_code, category;

--review 'VIEW'....Use for FACT Table Power BI
SELECT *
FROM q2_us_consump_prod_consolidated_energy_mix_stacked_view;

--***********************************************************************
--Question 3 Queries for Export
--***********************************************************************

--base 'VIEW' / 50 states
SELECT *
FROM chg_consump_prod_consolidated_energy_mix_ranks;

--UNION queries to create stacked display of info (state_code, category, description, unit, amount, rank)...ORDER BY state_code, category
--export to csv 'q3_chg_consump_prod_consolidated_energy_mix_ranks_stacked'...remove rank column after export
--CREATE VIEW q3_50st_chg_consump_prod_consolidated_energy_mix_stacked_view....use for consolidated POWER BI AGGREGATION table

CREATE VIEW q3_50st_chg_consump_prod_consolidated_energy_mix_stacked_view AS
SELECT state_code, category, 'Change 1970-1980' AS description, unit, chg_70_80 AS amount 
FROM chg_consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, 'Change 1980-1990' AS description, unit, chg_80_90 AS amount 
FROM chg_consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, 'Change 1990-2000' AS description, unit, chg_90_00 AS amount 
FROM chg_consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, 'Change 2000-2010' AS description, unit, chg_00_10 AS amount 
FROM chg_consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, 'Change 2010-2020' AS description, unit, chg_10_20 AS amount 
FROM chg_consump_prod_consolidated_energy_mix_ranks
ORDER BY state_code, category;

--review 'VIEW'....Use for AGGREGATION Table Power BI
SELECT *
FROM q3_50st_chg_consump_prod_consolidated_energy_mix_stacked_view;


--base query / national - US
--filtered amount of change for US NATIONAL 
SELECT state_code AS description, category, unit, 
	chg_70_80 AS amt_chg_70_80 , chg_80_90 AS amt_chg_80_90 , chg_90_00 AS amt_chg_90_00, chg_00_10 AS amt_chg_00_10, chg_10_20 AS amt_chg_10_20
FROM amt_chg_70_20
WHERE state_code = 'US'; 



--UNION queries to create stacked display of info (state_code, category, year, unit, amount)...ORDER BY state_code, category
--export to csv 'q3_us_chg_consump_prod_consolidated_energy_mix_ranks_stacked' 
--CREATE VIEW q3_us_chg_consump_prod_consolidated_energy_mix_stacked_view....use for consolidated POWER BI AGGREGATION table

CREATE VIEW q3_us_chg_consump_prod_consolidated_energy_mix_stacked_view AS
SELECT state_code, category,'Change 1970-1980' AS description, unit, chg_70_80 AS amount
FROM amt_chg_70_20
WHERE state_code = 'US' 
UNION
SELECT state_code, category,'Change 1980-1990' AS description, unit, chg_80_90 AS amount
FROM amt_chg_70_20
WHERE state_code = 'US' 
UNION
SELECT state_code, category,'Change 1990-2000' AS description, unit, chg_90_00 AS amount
FROM amt_chg_70_20
WHERE state_code = 'US' 
UNION
SELECT state_code, category,'Change 2000-2010' AS description, unit, chg_00_10 AS amount
FROM amt_chg_70_20
WHERE state_code = 'US' 
UNION
SELECT state_code, category,'Change 2010-2020' AS description, unit, chg_10_20 AS amount
FROM amt_chg_70_20
WHERE state_code = 'US' 
ORDER BY state_code, category;

--review 'VIEW'....Use for AGGREGATION Table Power BI
SELECT *
FROM q3_us_chg_consump_prod_consolidated_energy_mix_stacked_view;

--***********************************************************************
--Question 4 Queries for Export
--***********************************************************************

--base 'VIEW' / 50 states
SELECT *
FROM pct_chg_consump_prod_consolidated_energy_mix_ranks;

--UNION queries to create stacked display of info (state_code, category, description, unit, amount, rank)...ORDER BY state_code, category
--export to csv 'q4_pct_chg_consump_prod_consolidated_energy_mix_ranks_stacked'...remove rank column after export
--CREATE VIEW q4_50st_pct_chg_consump_prod_consolidated_energy_mix_stacked_view....use for consolidated POWER BI AGGREGATION table

CREATE VIEW q4_50st_pct_chg_consump_prod_consolidated_energy_mix_stacked_view AS
SELECT state_code, category, 'Percent Change 1970-1980' AS description, unit, pct_chg_70_80 AS amount 
FROM pct_chg_consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, 'Percent Change 1980-1990' AS description, unit, pct_chg_80_90 AS amount 
FROM pct_chg_consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, 'Percent Change 1990-2000' AS description, unit, pct_chg_90_00 AS amount 
FROM pct_chg_consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, 'Percent Change 2000-2010' AS description, unit, pct_chg_00_10 AS amount 
FROM pct_chg_consump_prod_consolidated_energy_mix_ranks
UNION
SELECT state_code, category, 'Percent Change 2010-2020' AS description, unit, pct_chg_10_20 AS amount 
FROM pct_chg_consump_prod_consolidated_energy_mix_ranks
ORDER BY state_code, category;


--review 'VIEW'....Use for AGGREGATION Table Power BI
SELECT *
FROM q4_50st_pct_chg_consump_prod_consolidated_energy_mix_stacked_view;

--base query / national - US
--filtered amount of change for US NATIONAL 
SELECT state_code AS description, category, unit, pct_chg_70_80, pct_chg_80_90, pct_chg_90_00, pct_chg_00_10, pct_chg_10_20
FROM pct_chg_70_20_cln
WHERE state_code = 'US' 


--UNION queries to create stacked display of info (state_code, category, year, unit, amount)...ORDER BY state_code, category
--export to csv 'q4_us_pct_chg_consump_prod_consolidated_energy_mix_ranks_stacked'
--CREATE VIEW q4_us_pct_chg_consump_prod_consolidated_energy_mix_stacked_view....use for consolidated POWER BI AGGREGATION table

CREATE VIEW q4_us_pct_chg_consump_prod_consolidated_energy_mix_stacked_view AS
SELECT state_code, category,'Percent Change 1970-1980' AS description, unit, pct_chg_70_80 AS amount
FROM pct_chg_70_20_cln
WHERE state_code = 'US' 
UNION
SELECT state_code, category,'Percent Change 1980-1990' AS description, unit, pct_chg_80_90 AS amount
FROM pct_chg_70_20_cln
WHERE state_code = 'US' 
UNION
SELECT state_code, category,'Percent Change 1990-2000' AS description, unit, pct_chg_90_00 AS amount
FROM pct_chg_70_20_cln
WHERE state_code = 'US' 
UNION
SELECT state_code, category,'Percent Change 2000-2010' AS description, unit, pct_chg_00_10 AS amount
FROM pct_chg_70_20_cln
WHERE state_code = 'US' 
UNION
SELECT state_code, category,'Percent Change 2010-2020' AS description, unit, pct_chg_10_20 AS amount
FROM pct_chg_70_20_cln
WHERE state_code = 'US' 
ORDER BY state_code, category;

--review 'VIEW'....Use for AGGREGATION Table Power BI
SELECT *
FROM q4_us_pct_chg_consump_prod_consolidated_energy_mix_stacked_view;

--***********************************************************************
--Consolidate 'VIEW's for Export --- Utilize for FACT Table in Power BI
--***********************************************************************

--export to csv as 'fact_table_q1_q2_sql_consolidated'
SELECT *
FROM q1_us_50st_gdp_total_stacked_view
UNION
SELECT *
FROM q1_50st_consump_gdp_pop_prod_stacked_view
UNION
SELECT *
FROM q1_eia_50st_us_expenditures_total_stacked_view
UNION
SELECT *
FROM q2_50st_consump_prod_energy_mix_stacked_view
UNION
SELECT *
FROM q1_us_consump_gdp_pop_prod_stacked_view
UNION
SELECT *
FROM q2_us_consump_prod_consolidated_energy_mix_stacked_view
ORDER BY state_code, category;

--fix capitalization in category column 
--export to csv as 'fact_table_q1_q2_sql_consolidated_1'
SELECT state_code, INITCAP(category) AS category, year, unit, amount
FROM q1_us_50st_gdp_total_stacked_view
UNION
SELECT state_code, INITCAP(category) AS category, year, unit, amount
FROM q1_50st_consump_gdp_pop_prod_stacked_view
UNION
SELECT state_code, INITCAP(category) AS category, year, unit, amount
FROM q1_eia_50st_us_expenditures_total_stacked_view
UNION
SELECT state_code, INITCAP(category) AS category, year, unit, amount
FROM q2_50st_consump_prod_energy_mix_stacked_view
UNION
SELECT state_code, INITCAP(category) AS category, year, unit, amount
FROM q1_us_consump_gdp_pop_prod_stacked_view
UNION
SELECT state_code, INITCAP(category) AS category, year, unit, amount
FROM q2_us_consump_prod_consolidated_energy_mix_stacked_view
ORDER BY state_code, category;



--***********************************************************************
--Consolidate 'VIEW's for Export --- Utilize for AGGREGATION Table in Power BI
--***********************************************************************

--export to csv as 'aggregation_table_q3_q4_sql_consolidated'
SELECT *
FROM q3_50st_chg_consump_prod_consolidated_energy_mix_stacked_view
UNION
SELECT *
FROM q4_50st_pct_chg_consump_prod_consolidated_energy_mix_stacked_view
UNION
SELECT *
FROM q3_us_chg_consump_prod_consolidated_energy_mix_stacked_view
UNION
SELECT *
FROM q4_us_pct_chg_consump_prod_consolidated_energy_mix_stacked_view
ORDER BY state_code, category;