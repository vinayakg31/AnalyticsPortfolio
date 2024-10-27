-- Selecting all columns from the 'layoffs' table
SELECT *
FROM layoffs;

-- 1. Remove duplicates
-- 2. Standardize the data
-- 3. Handle null or blank values
-- 4. Remove any unnecessary columns

-- Creating a new table 'layoffs_staging' with the same structure as 'layoffs' but without data
SELECT *
INTO layoffs_staging
FROM layoffs
WHERE 1 = 0;

-- Verifying the structure of the new 'layoffs_staging' table
SELECT *
FROM layoffs_staging;

-- Inserting all data from 'layoffs' table into the 'layoffs_staging' table
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- Using the 'world_layoffs' database
USE world_layoffs;

-- Identifying duplicate rows based on selected columns
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
        ORDER BY company
    ) AS row_num
FROM layoffs_staging;

-- Creating a CTE to identify duplicates by assigning row numbers based on column partition
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
            ORDER BY company
        ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;  -- Selects duplicate entries (row_num > 1)

-- Checking for a specific company 'Zywave' to verify duplicate existence
SELECT *
FROM layoffs_staging
WHERE company = 'Zywave';

-- Deleting duplicates from 'layoffs_staging' using the CTE based on row numbers
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
            ORDER BY company
        ) AS row_num
    FROM layoffs_staging
)
DELETE FROM duplicate_cte
WHERE row_num > 1;

-- Standardizing data by removing leading and trailing spaces from the 'company' column
UPDATE layoffs_staging
SET company = TRIM(company);

-- Checking distinct values in the 'industry' column to identify inconsistencies
SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1;

-- Identifying records where 'industry' begins with 'CRYPTO'
SELECT *
FROM layoffs_staging
WHERE industry LIKE 'CRYPTO %';

-- Standardizing 'CRYPTO' values in 'industry' column for consistency
UPDATE layoffs_staging
SET industry = 'CRYPTO'
WHERE industry LIKE 'CRYPTO%';

-- Checking distinct values in 'location' column
SELECT DISTINCT location
FROM layoffs_staging
ORDER BY 1;

-- Checking distinct values in 'country' column
SELECT DISTINCT country
FROM layoffs_staging
ORDER BY 1;

-- Trimming trailing periods from 'country' column values
UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Converting 'date' column from text to date format for analysis
SELECT date,
    CONVERT(DATE, date, 101) AS date
FROM layoffs_staging;

-- Identifying any rows with invalid date values in 'date' column
SELECT date
FROM layoffs_staging
WHERE TRY_CONVERT(DATE, date, 101) IS NULL AND date IS NOT NULL;

-- Deleting rows with invalid date values for cleaner data
DELETE FROM layoffs_staging
WHERE TRY_CONVERT(DATE, date, 101) IS NULL AND date IS NOT NULL;

-- Checking for rows where 'total_laid_off' and 'percentage_laid_off' columns have 'NULL' as text
SELECT *
FROM layoffs_staging
WHERE total_laid_off = 'NULL'
AND percentage_laid_off = 'NULL';

-- Identifying rows with null or blank values in the 'industry' column
SELECT *
FROM layoffs_staging
WHERE industry IS NULL
OR industry = 'NULL'
OR industry = '';

-- Checking rows where the company name starts with 'Bally' for standardization
SELECT *
FROM layoffs_staging
WHERE company LIKE 'Bally%';

-- Updating null or blank 'industry' values by copying data from other rows with the same 'company'
UPDATE t1
SET t1.industry = t2.industry
FROM layoffs_staging t1
JOIN layoffs_staging t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Verifying if any 'total_laid_off' or 'percentage_laid_off' fields still contain 'NULL' as text
SELECT *
FROM layoffs_staging
WHERE total_laid_off = 'NULL'
AND percentage_laid_off = 'NULL';

-- Deleting rows where 'total_laid_off' and 'percentage_laid_off' have 'NULL' as text for data accuracy
DELETE
FROM layoffs_staging
WHERE total_laid_off = 'NULL'
AND percentage_laid_off = 'NULL';

-- Final data check in 'layoffs_staging' table
SELECT *
FROM layoffs_staging;