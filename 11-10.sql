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
alter TABLE departments
CHANGE COLUMN remark remark VARCHAR(40) NULL DEFAULT NULL
COLLATE 'utf8mb4_bin';

# remark 컬럼의 collate bin > genaral
alter TABLE departments
CHANGE COLUMN remark remark VARCHAR(40) NULL DEFAULT NULL
COLLATE 'utf8mb4_general_ci';