## 1. Завантажте дані
drop schema if exists pandemic;
create schema pandemic;
use pandemic;

SELECT * FROM infectious_cases;

## 2. Нормальізація
drop table if exists countries;
CREATE TABLE  countries (
    id INT AUTO_INCREMENT UNIQUE PRIMARY KEY,
    entity VARCHAR(125) NOT NULL,
    code VARCHAR(10) NOT NULL
);

insert into countries (entity, code)
select distinct Entity, Code
from infectious_cases;

drop table if exists infectious_cases_normalized;
create table infectious_cases_normalized(
    id INT AUTO_INCREMENT PRIMARY KEY,
    country_id INT NOT NULL,
    year INT NOT NULL,
    polio_cases INT DEFAULT NULL,
    cases_guinea_worm INT DEFAULT NULL,
    Number_yaws FLOAT DEFAULT NULL,
    Number_rabies FLOAT DEFAULT NULL,
    Number_malaria FLOAT DEFAULT NULL,
    Number_hiv FLOAT DEFAULT NULL,
    Number_tuberculosis FLOAT DEFAULT NULL,
    Number_smallpox FLOAT DEFAULT NULL,
    Number_cholera_cases FLOAT DEFAULT NULL,
    CONSTRAINT fk_country
        FOREIGN KEY (country_id)
        REFERENCES countries(id)
);

INSERT INTO infectious_cases_normalized (
    country_id,
    year,
    polio_cases,
    cases_guinea_worm,
    Number_yaws,
    Number_rabies,
    Number_malaria,
    Number_hiv,
    Number_tuberculosis,
    Number_smallpox,
    Number_cholera_cases
)
SELECT
    c.id,
    ic.year,
    NULLIF(ic.polio_cases, ''),
    NULLIF(ic.cases_guinea_worm, ''),
    NULLIF(ic.Number_yaws, ''),
    NULLIF(ic.Number_rabies, ''),
    NULLIF(ic.Number_malaria, ''),
    NULLIF(ic.Number_hiv, ''),
    NULLIF(ic.Number_tuberculosis, ''),
    NULLIF(ic.Number_smallpox, ''),
    NULLIF(ic.Number_cholera_cases, '')
FROM infectious_cases ic
JOIN countries c
    ON ic.Entity = c.entity
    AND ic.Code = c.code;
    
select count(*) as ic_raw from infectious_cases;
select count(*) as c_norm from countries;
select count(*)  as ic_norm from infectious_cases_normalized;

## 3. Аналіз даних
SELECT 
    c.entity,
    c.code,
    c.id,
    ROUND(AVG(ic_norm.Number_rabies), 2) AS avg_rabies,
    ROUND(MIN(ic_norm.Number_rabies), 2) AS min_rabies,
    ROUND(MAX(ic_norm.Number_rabies), 2) AS max_rabies,
    ROUND(SUM(ic_norm.Number_rabies), 2) AS sum_rabies
FROM
    infectious_cases_normalized AS ic_norm
        JOIN
    countries AS c ON ic_norm.country_id = c.id
WHERE
    ic_norm.Number_rabies IS NOT NULL
GROUP BY c.entity , c.code , c.id
ORDER BY avg_rabies DESC
LIMIT 10;

## 4. Побудуйте колонку різниці в роках
SELECT 
    id,
    year,
    MAKEDATE(year, 1) AS first_day_year,
    CURRENT_DATE() AS cur_date,
    TIMESTAMPDIFF(YEAR,
        MAKEDATE(year, 1),
        CURRENT_DATE()) AS year_diff
FROM
    infectious_cases_normalized
ORDER BY year DESC;
    
## 5. Побудуйте власну функцію
drop function if exists year_diff_func;
delimiter //
create function year_diff_func(input_year int)
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(
        year,
        MAKEDATE(input_year, 1),
        CURRENT_DATE()
    );
END //

DELIMITER ;

SELECT id,
year,
    makedate(year,1) as first_day_year,
    curdate() as cur_date,
    year_diff_func(year) AS year_diff
FROM infectious_cases_normalized
ORDER BY year desc;

## 5 - Альтернативна функція
drop function if exists cases_per_period;
delimiter //
create function cases_per_period(cases_per_year float, divisor int)
returns float
deterministic
begin
return cases_per_year / nullif(divisor,0);
end
//

delimiter ;

SELECT 
    c.entity,
    ic_norm.year,
    ic_norm.Number_tuberculosis AS n_tuberculosis,
    ROUND(CASES_PER_PERIOD(ic_norm.Number_tuberculosis, 12),
            0) AS avg_per_month,
    ROUND(CASES_PER_PERIOD(ic_norm.Number_tuberculosis, 4),
            0) AS avg_per_quater,
    ROUND(CASES_PER_PERIOD(ic_norm.Number_tuberculosis, 2),
            0) AS avg_per_half_year
FROM
    infectious_cases_normalized AS ic_norm
        JOIN
    countries AS c ON ic_norm.id = c.id
WHERE
    Number_tuberculosis IS NOT NULL
ORDER BY ic_norm.year DESC , ROUND(CASES_PER_PERIOD(ic_norm.Number_tuberculosis, 12),
        0) DESC;