# 인덱스 없이 작은 규모의 데이터를 조회하는 나쁜 SQL문
EXPLAIN
SELECT *
FROM employees
WHERE last_name = 'Wielonsky'
  AND first_name = 'Georgi';

ALTER TABLE employees
    ADD INDEX I_이름_성 (first_name, last_name);

DROP INDEX I_이름_성 ON employees;

CREATE INDEX I_성_이름
    ON employees (last_name, first_name);

DROP INDEX I_성_이름 ON employees;
# 인덱스를 하나만 사용하는 나쁜 SQL문

EXPLAIN
SELECT *
FROM employees
WHERE first_name = 'matt'
  AND hire_date = '1987-03-31';


CREATE INDEX I_이름
    ON employees (first_name);

DROP INDEX I_이름 ON employees;

# 큰 규모의 데이터 변경으로 인덱스에 영향을 주는 나쁜 SQL문
# 세션용
SELECT @@autocommit;
SET AUTOCOMMIT = 0;

EXPLAIN
UPDATE emp_access_logs
SET door = 'X'
WHERE door = 'B';

SELECT COUNT(1)
FROM emp_access_logs
WHERE door = 'B';

ROLLBACK;

SHOW INDEX FROM emp_access_logs;

DROP INDEX I_출입문 ON emp_access_logs;

CREATE INDEX I_출입문 ON emp_access_logs (door);

# 비효율적인 인덱스를 사용하는 나쁜 SQL 문

EXPLAIN ANALYZE
SELECT emp_no, first_name, last_name
FROM employees
WHERE gender = 'M'
  AND last_name = 'Baba';

SHOW INDEX FROM employees;

# 기존 인덱스 삭제 후 변경 인덱스 추가
ALTER TABLE employees
    DROP INDEX I_성별_성,
    ADD INDEX I_lastname_gender (last_name, gender);

# 변경 인덱스 삭제 후 기존 인덱스 추가
ALTER TABLE employees
    DROP INDEX I_lastname_gender,
    ADD INDEX I_성별_성 (gender, last_name);

DROP INDEX I_lastname_gender ON employees;
CREATE INDEX I_성별_성 ON employees (gender, last_name);
EXPLAIN ANALYZE
SELECT emp_no, first_name, last_name
FROM employees
WHERE last_name = 'Baba'
  AND gender = 'M';

# 잘못된 열 속성으로 비효율적으로 작성한 나쁜 SQL문
EXPLAIN
SELECT dept_name, remark
FROM departments
WHERE remark = 'active'
  AND ASCII(SUBSTR(remark, 1, 1)) = 97 -- a
  AND ASCII(SUBSTR(remark, 2, 1)) = 99; -- b

SELECT dept_name, remark
FROM departments
WHERE remark = 'active';

# remark 컬럼의 collate general > bin
ALTER TABLE departments
    CHANGE COLUMN remark remark VARCHAR(40) NULL DEFAULT NULL
        COLLATE 'utf8mb4_bin';

# remark 컬럼의 collate bin > genaral
ALTER TABLE departments
    CHANGE COLUMN remark remark VARCHAR(40) NULL DEFAULT NULL
        COLLATE 'utf8mb4_general_ci';

# 대소문자가 섞인 데이터와 비교하는 나쁜 SQL문
EXPLAIN
SELECT first_name, last_name, gender, birth_date
FROM employees
WHERE first_name = LOWER('MARY')
  AND hire_date >= STR_TO_DATE('1990-01-01', '%Y-%m-%d');

EXPLAIN
SELECT first_name, last_name, gender, birth_date
FROM employees FORCE INDEX (I_입사일자)
WHERE first_name = LOWER('MARY')
  AND hire_date >= STR_TO_DATE('1990-01-01', '%Y-%m-%d');

# 컬럼 하나 추가
ALTER TABLE employees
    ADD COLUMN lower_first_name VARCHAR(14) NOT NULL COLLATE 'utf8mb3_general_ci'
        AFTER first_name;

SELECT *
FROM employees;

# first_name 값을 모두 소문자로 변경하여 lower_first_name으로 값을 넣고싶다
UPDATE employees
SET lower_first_name = LOWER(first_name);

EXPLAIN
SELECT first_name, last_name, gender, birth_date
FROM employees
WHERE first_name = LOWER('mary')
  AND hire_date >= STR_TO_DATE('1990-01-01', '%Y-%m-%d');

# 분산 없이 큰 규모의 데이터를 사용하는 나쁜 SQL문

#  2,844,047 rows
SELECT count(1) FROM salaries;

#  255,785 rows
SELECT COUNT(1)
FROM salaries
WHERE from_date
          BETWEEN '2000-01-01' AND '2000-12-31';


SELECT year(from_date) AS from_year, count(1)
FROM salaries
GROUP BY from_year;

# 파티셔닝 제거
ALTER TABLE salaries DROP PARTITION 'p00';

-- 파티셔닝 생성
ALTER TABLE salaries
PARTITION BY RANGE COLUMNS (from_date)
(
	PARTITION p85 VALUES LESS THAN ('1985-12-31'),
	PARTITION p86 VALUES LESS THAN ('1986-12-31'),
	PARTITION p87 VALUES LESS THAN ('1987-12-31'),
	PARTITION p88 VALUES LESS THAN ('1988-12-31'),
	PARTITION p89 VALUES LESS THAN ('1989-12-31'),
	PARTITION p90 VALUES LESS THAN ('1990-12-31'),
	PARTITION p91 VALUES LESS THAN ('1991-12-31'),
	PARTITION p92 VALUES LESS THAN ('1992-12-31'),
	PARTITION p93 VALUES LESS THAN ('1993-12-31'),
	PARTITION p94 VALUES LESS THAN ('1994-12-31'),
	PARTITION p95 VALUES LESS THAN ('1995-12-31'),
	PARTITION p96 VALUES LESS THAN ('1996-12-31'),
	PARTITION p97 VALUES LESS THAN ('1997-12-31'),
	PARTITION p98 VALUES LESS THAN ('1998-12-31'),
	PARTITION p99 VALUES LESS THAN ('1999-12-31'),
	PARTITION p00 VALUES LESS THAN ('2000-12-31'),
	PARTITION p01 VALUES LESS THAN ('2001-12-31'),
	PARTITION p02 VALUES LESS THAN ('2002-12-31'),
	PARTITION p03 VALUES LESS THAN (maxvalue)
);

-- 파티션 스캔 비율
SELECT partition_name, table_rows, AVG_ROW_LENGTH, data_length / 1024 / 1024 AS data_size_mb
FROM information_schema.partitions
WHERE table_schema = 'tuning2'
AND TABLE_NAME = 'salaries'
AND partition_name IS NOT NULL
ORDER BY partition_ordinal_position;

# 전체 파티셔닝 제거
alter TABLE salaries REMOVE PARTITIONING;














