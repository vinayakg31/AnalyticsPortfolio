-- Switching to the database 'world_layoffs'
USE world_layoffs;

-- Selecting all records from 'layoffs_staging' table
SELECT *
FROM layoffs_staging;

-- Getting the maximum 'total_laid_off' where it is not 'NULL' or NULL
SELECT MAX(total_laid_off)
FROM layoffs_staging
WHERE total_laid_off != 'NULL'
AND total_laid_off IS NOT NULL;

-- Counting records where 'total_laid_off' is explicitly 'NULL' (as text)
SELECT COUNT(*) 
FROM layoffs_staging
WHERE total_laid_off = 'NULL';

-- Counting records where 'total_laid_off' is not NULL
SELECT COUNT(*)
FROM layoffs_staging
WHERE total_laid_off IS NOT NULL;

-- Selecting all records from 'layoffs_staging' again to review table contents
SELECT *
FROM layoffs_staging;

-- Getting the maximum values of 'total_laid_off' and 'percentage_laid_off'
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging;

-- Checking table structure by listing column names
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'layoffs_staging';

-- Converting 'total_laid_off' to integer to find max laid off, ensuring numeric values
SELECT MAX(CAST(total_laid_off AS int)) AS max_laid_off
FROM layoffs_staging
WHERE ISNUMERIC(total_laid_off) = 1 AND total_laid_off IS NOT NULL;

-- Identifying non-numeric entries in 'total_laid_off' and 'percentage_laid_off'
SELECT *
FROM layoffs_staging
WHERE ISNUMERIC(total_laid_off) = 0 OR ISNUMERIC(percentage_laid_off) = 0;

-- Setting 'total_laid_off' values of 'NULL' (text) to SQL NULL
UPDATE layoffs_staging
SET total_laid_off = NULL
WHERE total_laid_off = 'NULL';

-- Converting 'total_laid_off' column values to integers where they aren't NULL
UPDATE layoffs_staging
SET total_laid_off = CAST(total_laid_off AS INT)
WHERE total_laid_off IS NOT NULL;

-- Altering the column type of 'total_laid_off' to integer
ALTER TABLE layoffs_staging
ALTER COLUMN total_laid_off INT;

-- Setting 'percentage_laid_off' values of 'NULL' (text) to SQL NULL
UPDATE layoffs_staging
SET percentage_laid_off = NULL
WHERE percentage_laid_off = 'NULL';

-- Converting 'percentage_laid_off' values to DECIMAL type where they aren't NULL
UPDATE layoffs_staging
SET percentage_laid_off = CAST(percentage_laid_off AS DECIMAL(5,2))
WHERE percentage_laid_off IS NOT NULL;

-- Altering the column type of 'percentage_laid_off' to DECIMAL with precision (5,2)
ALTER TABLE layoffs_staging
ALTER COLUMN percentage_laid_off DECIMAL(5,2);

-- Selecting records where 'percentage_laid_off' is 1, ordered by 'total_laid_off' descending
SELECT * 
FROM layoffs_staging
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Summing 'total_laid_off' by company and ordering by sum in descending order
SELECT company, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY company
ORDER BY 2 DESC;

-- Selecting minimum and maximum dates in 'date' column
SELECT MIN(date), MAX(DATE)
FROM layoffs_staging;

-- Ordering dates in descending order to view most recent dates first
SELECT date
FROM layoffs_staging
ORDER BY 'date' DESC;

-- Converting 'date' column values to SQL date format where possible
UPDATE layoffs_staging
SET date = TRY_CONVERT(date, date, 101)
WHERE TRY_CONVERT(date, date, 101) IS NOT NULL;

-- Checking rows with invalid date conversions in 'date' column
SELECT *
FROM layoffs_staging
WHERE TRY_CONVERT(date, date, 101) IS NULL;

-- Summing 'total_laid_off' by year and ordering by year in descending order
SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_staging
GROUP BY YEAR(date)
ORDER BY 1 DESC;

-- Rolling total of layoffs grouped by month

-- Summing layoffs by month
SELECT SUBSTRING(date,1,7) AS month, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY SUBSTRING(date, 1,7)
ORDER BY 1 ASC;

-- Calculating rolling total of layoffs month by month

WITH Rolling_Total AS
(
    SELECT SUBSTRING(date,1,7) AS month, SUM(total_laid_off) AS total_off
    FROM layoffs_staging
    GROUP BY SUBSTRING(date, 1,7)
)
-- Displaying month, monthly layoffs, and rolling total of layoffs
SELECT month, total_off,
    SUM(total_off) OVER(ORDER BY month) AS rolling_total
FROM Rolling_Total;

-- Ranking companies with the highest layoffs per year, top 5 each year

WITH Company_year (company, years, total_laid_off) AS
(
    -- Summing total layoffs by company and year
    SELECT company, YEAR(date), SUM(total_laid_off)
    FROM layoffs_staging
    GROUP BY company, YEAR(date)
), 
Company_year_rank AS 
(
    -- Applying rank based on layoffs within each year
    SELECT *,
        DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Rankng
    FROM Company_year
)
-- Displaying only top 5 companies by layoffs for each year
SELECT *
FROM Company_year_rank
WHERE Rankng <= 5;