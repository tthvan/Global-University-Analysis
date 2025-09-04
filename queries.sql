-- Q1. What are the top 10 universities worldwide?
SELECT * FROM general_view
ORDER BY rank 
LIMIT 10;

-- Q2. What is the ratio of public vs private universities by country?
SELECT 
	country_id, 
	status, 
	COUNT(*) AS uni_count,
	ROUND(COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY country_id)*100,2) AS ratio
FROM general_view
WHERE status IS NOT NULL
GROUP BY country_id, status
ORDER BY country_id, status;

-- Q3. What are the top 5 universities in each country?
SELECT 
	uni_name,
	country_name,
	rank AS world_rank,
	country_rank
FROM (
	SELECT 
		uni_name,
		country_id,
		country_name,
		rank,
		row_number() OVER (PARTITION BY country_id ORDER BY rank) AS country_rank	
	FROM general_view
) 
WHERE country_rank <= 5
ORDER BY country_id;

-- Q4. For each country, what is the 3 universities with the most international students?
SELECT 
	uni_name,
	country_name,
	num_international
FROM (
	SELECT 
		g.uni_name,
		g.country_name,
		(p.student_population * p.percent_international_population) AS num_international,
		ROW_NUMBER() OVER (PARTITION BY country_name ORDER BY (p.student_population * p.percent_international_population) DESC) AS ri 
	FROM general_view g
	JOIN uni_populations p ON g.id = p.uni_id
	WHERE p.year=2024
)
WHERE ri <=3
ORDER BY country_name, num_international DESC;

-- Q5. Which 10 countries have the highest cost of living index?
SELECT DISTINCT /*because the general_view set is university-level, not country-level*/
	g.country_name,
	c.cost_living_index
FROM general_view g 
JOIN country_stats c ON g.country_id = c.country_id
WHERE c.year = 2024
ORDER BY c.cost_living_index DESC
LIMIT 10;
--- Interestingly, the USA is not within TOP 5 

-- Q6. Find info on a UNI name is somewhat 'Dundee'
SELECT * FROM general_view
WHERE uni_name LIKE '%Dundee%';

-- Q7. Find list of schools in the USA, ranked by ranking and tuition
SELECT * FROM general_view
WHERE country_name = 'United States'
ORDER BY rank ASC, fee_usd_avg DESC;

-- Q8. Find UNIs: tuition < 20,000 USD, in Canada, ranking < 500 
SELECT * FROM general_view
WHERE country_name = 'Canada'
AND fee_usd_avg < 20000
AND rank < 500;

-- Q9. Find the evaluations (scores) for York University
SELECT * FROM scoring_stats
WHERE uni_id = (
	SELECT id FROM general_view
	WHERE uni_name = 'York University');

-- Q10. Find the evaluations (scores) for University of British Columbia and University of Alberta 
-- (2 TOP Uni in Canada) for comparison 
SELECT 
	g.id,
	g.uni_name,
	g.fee_usd_avg,
	g.rank,
	s.name AS metric,
	s.score
FROM general_view g
JOIN scoring_stats s
ON g.id = s.uni_id
WHERE g.uni_name = 'University of British Columbia' 
OR g.uni_name = 'University of Alberta'
AND s.year = 2024
ORDER BY s.name;

-- Q11. Compute annual total costs for a year to study in Germany vs France, by UNI
SELECT 
	u.name AS uni_name,
	c.name AS country_name,
	g.fee_usd_avg AS tuition,
	s.rent_discounted AS rent,
	(g.fee_usd_avg + s.rent_discounted*12) AS total_cost
FROM universities u
JOIN country_stats s ON u.country_id = s.id
JOIN countries c ON c.id = u.country_id
JOIN general_view g ON u.id = g.id
WHERE c.name = 'Germany'
OR c.name = 'France'
ORDER BY total_cost ASC;

-- Q12. Rank annual total costs in different countries, aggregated
SELECT 
	c.name AS country_name,
	ROUND(AVG(g.fee_usd_avg),2) AS avg_tuition,
	ROUND(AVG(s.rent_discounted),2) AS avg_rent,
	ROUND((AVG(g.fee_usd_avg) + AVG(s.rent_discounted)*12),2) AS annual_total_cost
FROM country_stats s
JOIN countries c ON c.id = s.country_id
JOIN general_view g ON g.country_id = c.id
GROUP BY c.name
ORDER BY annual_total_cost ASC;

SELECT * FROM scoring_stats ORDER BY uni_id;
WHERE name LIKE '%'

-- Q13. Find the best affordable Uni <20000USD with a high Employment score in Canada
SELECT 
	g.uni_name,
	g.country_name,
	g.fee_usd_avg,
	g.rank,
	s.name AS metric,
	s.score
FROM general_view g 
JOIN scoring_stats s ON g.id = s.uni_id
WHERE s.year = 2024
AND g.fee_usd_avg < 20000
AND g.country_name = 'Canada'
AND s.name = 'Employer Reputation'
ORDER BY s.score DESC;

-- Q14. What is the average QS ranking of universities per country?
SELECT 
	country_name,
	ROUND(AVG(rank)) AS avg_rank
FROM general_view
GROUP BY country_name
ORDER BY avg_rank;

select * from tuitions;
select * from exchange_to_usd;
select * from general_view;

-- Q15. What is the min, max, and average tuition for universities in Canada?
SELECT 
	uni_name, 
	ROUND((fee_min * rate),2) AS fee_min_usd,
	ROUND((fee_max * rate),2) AS fee_max_usd,
	fee_usd_avg
FROM general_view g
JOIN tuitions t ON g.id = t.uni_id
JOIN (
	SELECT 
		currency, 
		rate, 
		ROW_NUMBER() OVER (PARTITION BY currency ORDER BY record_date DESC) AS newest
	FROM exchange_to_usd
	ORDER BY currency, record_date DESC
) e 
ON e.currency = t.currency
AND newest=1;