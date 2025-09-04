-- CREATE MAIN TABLES
DROP TABLE IF EXISTS universities CASCADE;
DROP TABLE IF EXISTS scoring_metrics CASCADE;
DROP TABLE IF EXISTS scoring_stats CASCADE;
DROP TABLE IF EXISTS ranking_metrics CASCADE;
DROP TABLE IF EXISTS ranking_stats CASCADE;
DROP TABLE IF EXISTS tuitions CASCADE;
DROP TABLE IF EXISTS countries CASCADE;
DROP TABLE IF EXISTS country_stats CASCADE;
DROP TABLE IF EXISTS exchange_to_usd CASCADE;
DROP TABLE IF EXISTS uni_populations CASCADE;

CREATE TYPE status_enum AS ENUM('public', 'private');
CREATE TYPE research_output_enum AS ENUM('Very High', 'High', 'Medium', 'Low');
CREATE TYPE size_enum AS ENUM('S', 'M', 'L', 'XL');
CREATE TYPE scholarship_enum AS ENUM('Yes', 'No');

ALTER TYPE status_enum RENAME VALUE 'public' to 'Public';
ALTER TYPE status_enum RENAME VALUE 'private' to 'Private';

-- countries
Create table countries (
  id SERIAL PRIMARY KEY,
  name varchar(255) not null unique
);

-- country_stats
Create table country_stats (
  id SERIAL PRIMARY KEY,
  country_id integer not null,
  rent_discounted NUMERIC,
  cost_living_index NUMERIC,
  year SMALLINT DEFAULT 2024,
  FOREIGN KEY (country_id) REFERENCES countries(id)
);

-- universities
CREATE TABLE universities (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  location TEXT,
  country_id INTEGER,
  scholarship scholarship_enum,
  status status_enum,
  research_output research_output_enum,
  size size_enum,
  admission TEXT,
  link VARCHAR(1000),
  FOREIGN KEY (country_id) REFERENCES countries(id)
);

-- uni_populations
CREATE TABLE uni_populations (
  id SERIAL PRIMARY KEY,
  uni_id INTEGER NOT NULL,
  student_population NUMERIC,
  percent_international_population NUMERIC,
  student_staff_ratio NUMERIC,
  year SMALLINT DEFAULT 2024,
  FOREIGN KEY (uni_id) REFERENCES universities(id)
);

-- scoring_stats
CREATE TABLE scoring_stats (
    id SERIAL PRIMARY KEY,
    uni_id INTEGER,
	name VARCHAR(500),
    score NUMERIC,
  year SMALLINT DEFAULT 2024,
    FOREIGN KEY (uni_id) REFERENCES universities(id)
);

-- ranking_stats
CREATE TABLE ranking_stats (
  id SERIAL PRIMARY KEY,
    uni_id INTEGER,
	name VARCHAR(500),
    rank NUMERIC,
  year SMALLINT DEFAULT 2024,
    FOREIGN KEY (uni_id) REFERENCES universities(id)
);

-- exchange_to_usd
CREATE TABLE exchange_to_usd (
  id SERIAL PRIMARY KEY,
    currency VARCHAR(10),
    record_date DATE DEFAULT CURRENT_DATE,
    rate NUMERIC
);

-- tuitions
CREATE TABLE tuitions (
    id SERIAL PRIMARY KEY,
    uni_id INTEGER NOT NULL,
    currency VARCHAR(10),
    fee_min NUMERIC,
    fee_max NUMERIC,
    fee_avg NUMERIC,
    FOREIGN KEY (uni_id) REFERENCES universities (id)
);

-- CREATE STAGING TABLES (RAW DATA TABLES LOADING)
DROP TABLE IF EXISTS staging.universities_staging CASCADE;
DROP TABLE IF EXISTS staging.scores_staging CASCADE;
DROP TABLE IF EXISTS staging.rank_staging CASCADE;
DROP TABLE IF EXISTS staging.populations_staging CASCADE;
DROP TABLE IF EXISTS staging.countries_staging CASCADE;
DROP TABLE IF EXISTS staging.currencies CASCADE;

CREATE TABLE staging.universities_staging (
    ID VARCHAR(255),
    name VARCHAR(255),
    loc TEXT,
    country VARCHAR(255),
    country_id VARCHAR(255),
    rank_raw VARCHAR(255),
    rank VARCHAR(255),
    scholarship VARCHAR(255),
    status VARCHAR(255),
    research_output VARCHAR(255),
    student_faculty_ratio VARCHAR(255),
    int_students VARCHAR(255),
    size VARCHAR(255),
    total_faculty VARCHAR(255),
    link VARCHAR(1000),
    admission_raw TEXT,
    city TEXT,
    tuition_fee_raw VARCHAR(255),
    currency VARCHAR(255),
    exchange_rate VARCHAR(255),
    fee_min VARCHAR(255),
    fee_max VARCHAR(255),
    fee_avg VARCHAR(255),
    fee_min_usd VARCHAR(255),
    fee_max_usd VARCHAR(255),
    fee_avg_usd VARCHAR(255)
);

CREATE TABLE staging.scores_staging (
    ID VARCHAR(255),
    name VARCHAR(255),
    score VARCHAR(255),
	year VARCHAR(20)
);

CREATE TABLE staging.rank_staging (
    ID VARCHAR(255),
    name VARCHAR(255),
    rank VARCHAR(255),
	year VARCHAR(10)
);

CREATE TABLE staging.populations_staging (
    Rank VARCHAR(255),
    Name VARCHAR(255),
    uni_id VARCHAR(255),
    Country VARCHAR(255),
    country_id VARCHAR(255),
    Student_Population VARCHAR(255),
    Students_to_Staff_Ratio VARCHAR(255),
    International_Students VARCHAR(255),
    Int_Students VARCHAR(255),
    Female_to_Male_Ratio VARCHAR(255),
    Overall_Score VARCHAR(255),
    Teaching VARCHAR(255),
    Research_Environment VARCHAR(255),
    Research_Quality VARCHAR(255),
    Industry_Impact VARCHAR(255),
    International_Outlook VARCHAR(255),
    Year VARCHAR(255)
);

CREATE TABLE staging.countries_staging (
    id VARCHAR(255),
    country_livingcost VARCHAR(255),
    name VARCHAR(255),
    country_THE VARCHAR(255),
    country_id VARCHAR(255),
    rent_raw VARCHAR(255),
    rent_discounted VARCHAR(255),
    living_cost_index_raw VARCHAR(255),
    generated VARCHAR(255),
    cost_living_index VARCHAR(255)
);

CREATE TABLE staging.currencies (
	name VARCHAR(10),
	rate VARCHAR(255),
	record_date DATE DEFAULT CURRENT_DATE
);


-- INSERT DATA INTO MAIN TABLES
INSERT INTO countries (name)
SELECT name
FROM staging.countries_staging;


INSERT INTO country_stats (country_id, rent_discounted, cost_living_index)
SELECT
	id::NUMERIC::INTEGER,
	NULLIF(rent_discounted, 'N/A')::NUMERIC,
	NULLIF(cost_living_index, 'N/A')::NUMERIC
FROM staging.countries_staging
WHERE cost_living_index IS NOT NULL
AND rent_discounted IS NOT NULL;


INSERT INTO universities (id, name, location, country_id, scholarship, status, research_output, size, admission, link)
SELECT
	id::NUMERIC::INTEGER,
	name,
	NULLIF(loc, 'N/A'),
	NULLIF(country_id, 'N/A')::NUMERIC::INTEGER,
	NULLIF(scholarship, 'N/A')::scholarship_enum,
	NULLIF(status, 'N/A')::status_enum,
	NULLIF(research_output, 'N/A')::research_output_enum,
	NULLIF(size, 'N/A')::size_enum,
	NULLIF(admission_raw, 'N/A'),
	NULLIF(link, 'N/A')
FROM staging.universities_staging;


INSERT INTO uni_populations(uni_id, student_population, percent_international_population, student_staff_ratio,year)
SELECT
	uni_id::NUMERIC::INTEGER,
	NULLIF(Student_Population, 'N/A')::NUMERIC,
	NULLIF(International_Students, 'N/A')::NUMERIC,
	NULLIF(Students_to_Staff_Ratio, 'N/A')::NUMERIC,
	NULLIF(Year, 'N/A')::SMALLINT
FROM staging.populations_staging;


INSERT INTO scoring_stats (uni_id, name, score, year)
SELECT
	id::NUMERIC::INTEGER,
	name,
	score::NUMERIC,
	year::SMALLINT
FROM staging.scores_staging;


INSERT INTO ranking_stats (uni_id, name, rank, year)
SELECT
	id::NUMERIC::INTEGER,
	name,
	rank::NUMERIC,
	year::SMALLINT
FROM staging.rank_staging;


INSERT INTO exchange_to_usd (currency, rate)
SELECT
	name,
	rate::NUMERIC
FROM staging.currencies;


INSERT INTO tuitions(uni_id, currency, fee_min, fee_max, fee_avg)
SELECT
	id::NUMERIC::INTEGER,
	currency,
	fee_min:: NUMERIC,
	fee_max::NUMERIC,
	fee_avg::NUMERIC
FROM staging.universities_staging;



-- CREATE VIEWS
DROP VIEW IF EXISTS top20_int_population;
DROP VIEW IF EXISTS general_view;
DROP VIEW IF EXISTS tuitions_usd;

-- 1. Convert local tuition fees to USD for easy comparison
CREATE MATERIALIZED VIEW tuitions_usd AS
SELECT
	t.uni_id,
	t.currency,
	t.fee_avg,
	ROUND((t.fee_avg * e.rate),2) AS fee_usd_avg
FROM tuitions t
JOIN (SELECT DISTINCT ON (currency) currency, rate, record_date --Select only 1 row per 1 currency record, then shows its currency,rate,record_date
	FROM exchange_to_usd
	ORDER BY currency, record_date DESC) e
ON t.currency = e.currency;

-- 2. For parents & students who want to have a general view of top-ranking UNIs and their basic information
CREATE VIEW general_view AS
SELECT
	u.id,
	u.name AS uni_name,
	u.country_id,
	c.name AS country_name,
	r.rank,
	f.fee_usd_avg,
	u.scholarship,
	u.status,
	u.research_output,
	u.size
FROM universities u
JOIN countries c
ON u.country_id = c.id
JOIN tuitions_usd f
ON f.uni_id = u.id
JOIN ranking_stats r
ON r.uni_id = u.id
WHERE r.name = 'QS World University Rankings';

-- 3. For agency: View those countries with an increasing trend of accepting international students
CREATE VIEW top20_int_population AS
SELECT
	p.uni_id,
	u.name AS uni_name,
	c.name AS country_name,
	p.percent_international_population,
	p.student_population,
	p.year
FROM uni_populations p
JOIN universities u
ON u.id = p.uni_id
JOIN countries c
ON c.id = u.country_id
WHERE p.uni_id IN (
	SELECT uni_id
	FROM uni_populations
	WHERE year = 2024
	ORDER BY percent_international_population DESC
	LIMIT 20)
ORDER BY uni_id;



-- CREATE INDEXES
CREATE INDEX uni_name ON universities (name);
CREATE INDEX country_name ON countries (name);
CREATE INDEX ranking ON ranking_stats (rank);
CREATE INDEX rank_by_nameyear ON ranking_stats (uni_id, year);
CREATE INDEX rent ON country_stats (country_id, rent_discounted);
CREATE INDEX fee_under20k ON tuitions_usd (uni_id, fee_usd_avg);



-- CREATE TRIGGERS
-- 1. Because materialized views need to be refreshed every time, so I created an auto-refresh trigger whenever there's a change
CREATE OR REPLACE FUNCTION refresh_usd_tuition_view()
RETURNS TRIGGER AS $$
BEGIN
	REFRESH MATERIALIZED VIEW CONCURRENTLY tuitions_usd;
	RETURN NULL;
END;
$$ language plpgsql;

CREATE TRIGGER trg_refresh_usd_tuition_view
AFTER INSERT OR UPDATE OR DELETE ON tuitions
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_usd_tuition_view();

-- 2. To avoid overload the exchange rate table, only record daily rates -> prevent duplicated rates of the same currency in a same day
CREATE OR REPLACE FUNCTION prevent_dups_exchange_rate()
RETURNS TRIGGER AS $$
BEGIN
	IF EXISTS (
		SELECT 1 FROM exchange_to_usd
		WHERE currency = NEW.currency
		AND record_date = NEW.record_date)
	THEN
		RAISE EXCEPTION 'Duplicated exchange rate in same day';
	END IF;

	RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER trg_exchange_to_usd
BEFORE INSERT ON exchange_to_usd
FOR EACH ROW
EXECUTE FUNCTION prevent_dups_exchange_rate();

-- 3. Log history of rankings: Parents usually ask about schools and their rankings history
CREATE OR REPLACE FUNCTION log_history_ranking()
RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO ranking_history (uni_id, old_rank, new_rank, year)
	VALUES (NEW.uni_id, OLD.rank, NEW.rank, CURRENT_DATE);

	RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER trg_log_history_ranking
AFTER UPDATE ON ranking_stats --when update on the rows (the ranking of the UNI)
FOR EACH ROW
WHEN (OLD.rank IS DISTINCT FROM NEW.rank) --when updated but new rank is different than old rank
EXECUTE FUNCTION log_history_ranking(); -- then log history

