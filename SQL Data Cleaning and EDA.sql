SELECT * FROM layoffs;
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null values or Blank values
-- 4. Remove any column


CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT * FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT * ,ROW_NUMBER() OVER(
partition by company,location,industry,total_laid_off,percentage_laid_off,`date`
) AS row_num
FROM layoffs_staging;

with duplicate_cte AS (
SELECT * ,ROW_NUMBER() OVER(
partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions
) AS row_num
FROM layoffs_staging)
SELECT * FROM duplicate_cte
WHERE row_num > 1;

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_staging2
WHERE row_num > 1;

INSERT INTO layoffs_staging2
SELECT * ,ROW_NUMBER() OVER(
partition by company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions
) AS row_num
FROM layoffs_staging;

DELETE FROM layoffs_staging2
WHERE row_num > 1;

SELECT * FROM layoffs_staging2;

-- Standardizing data

SELECT company, TRIM(company)
FROM layoffs_staging2;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country,TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

SELECT `date` 
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`,'%m/%d/%Y');

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country like 'United states%';


SELECT * FROM  layoffs_staging2
WHERE industry LIKE 'crypto%';

UPDATE layoffs_staging2
SET industry = 'crypto'
WHERE industry LIKE 'crypto%';

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL;

SELECT * FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';


SELECT * FROM layoffs_staging2
WHERE company LIKE 'Bally%';

SELECT t1.industry,t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
WHERE(t1.industry IS NULL OR t1.industry = '' )
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';



UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE(t1.industry IS NULL OR t1.industry = '' )
AND t2.industry IS NOT NULL;

-- Removing column

SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off iS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off iS NULL;

SELECT * FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Exploratory Data

SELECT * FROM layoffs_staging2;

-- Max laid off of all Companies

SELECT MAX(total_laid_off)
FROM layoffs_staging2;

-- Looking at the companies to see how big these laysoff were

SELECT MAX(percentage_laid_off), MIN(percentage_laid_off)
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL ;

-- Which companies had 1/100 percent layoffs

SELECT * FROM layoffs_staging2
WHERE percentage_laid_off = 1 ;

-- Most of these companies are startup companies they went out of business during this time

-- Order by funds_raised to see how big some these companies were

SELECT * FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC ;

-- Britishvolt and Quibi raised like 2400 and 1800 billion dollars and still went under

-- Companies with the biggest single layoffs

SELECT company,total_laid_off
FROM layoffs_staging2
ORDER BY 2 DESC
LIMIT 5;

-- the layoffs by a single day

-- Companies with the most total layoffs

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;

-- WE can see that Amazon and Google are the top 2

-- By location

SELECT location,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- Total in the past 3 years

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
-- United States and India are the highest

SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 2 DESC;
-- Total layoffs by year

-- Total layoffs by industry

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
-- Consumer and Retail are the top 2

-- Total layoffs by stage

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- Companies with the most layoffs per year

WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;

-- Roiling total layoffs per month

SELECT SUBSTRING(date,1,7) AS dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC;

-- WE use a CTE to query off of it 

WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;










