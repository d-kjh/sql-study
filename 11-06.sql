-- 성이 'Radwan'이고 성별이 남자인 고객
EXPLAIN
SELECT *
FROM employees
WHERE last_name = 'Radwan'
  AND gender = 'M';

-- 부서 관리자의 사원번호, 이름, 성, 부서번호 데이터를 중복 제거하여 조회
EXPLAIN
SELECT d.emp_no, e.first_name, e.last_name, d.dept_no
FROM dept_manager d
         INNER JOIN employees e
                    ON d.emp_no = e.emp_no;

-- 성이 'Baba'이면서 성별이 남자인 사원과 성이 'Baba'이면서 성별이 여자인 사윈을 조회
EXPLAIN
SELECT *
FROM employees
WHERE last_name = 'Baba' AND gender = 'M'
   OR last_name = 'Baba' AND gender = 'F';

-- 성과 성별 순서로 그룹핑하여 몇 건의 데이터가 있는지 구하시오
EXPLAIN
SELECT last_name, gender, COUNT(1)
FROM employees
GROUP BY last_name, gender;

-- 사원의 입사일자 값이 '1989'로 시작하면서 사원번호가 100_000을 초과하는 데이터를 조회
EXPLAIN
SELECT emp_no
FROM employees USE INDEX (I_입사일자)
WHERE hire_date LIKE '1989%'
  AND emp_no > 100000;

EXPLAIN
SELECT emp_no
FROM employees USE INDEX (I_입사일자)
WHERE (hire_date >= '1989-01-01' AND hire_date <= '1989-12-31')
  AND emp_no > 100000;

SET PROFILING = 0;
SELECT @@profiling;
SHOW PROFILES;

-- emp_access_logs(사원출입기록), door(출입문) 'B'출입문으로 출입한 이력이 있는 정보를 모두 조회

SELECT *
FROM emp_access_logs
WHERE door = 'B';

-- 입사일자가 1994년 1월 1일부터 2000년 12월 31일까지인 사원들의 이름과 성을 출력

-- ALL 테이블 풀스캔
EXPLAIN
SELECT last_name, first_name
FROM employees
WHERE hire_date
          BETWEEN STR_TO_DATE('1994-01-01', '%Y-%m-%d')
          AND STR_TO_DATE('2000-12-31', '%Y-%m-%d');

-- range 인덱스 사용
EXPLAIN
SELECT last_name, first_name
FROM employees FORCE INDEX (I_입사일자)
WHERE hire_date
          BETWEEN STR_TO_DATE('1994-01-01', '%Y-%m-%d')
          AND STR_TO_DATE('2000-12-31', '%Y-%m-%d');

#  부서사원 테이블과  테이블을 조인하여 부서 시작일자가 '2002-03-01'
#  부터인 사원의 데이터를 조회하는 쿼리 표시컬럼 : 사원번호, 부서번호

EXPLAIN
SELECT STRAIGHT_JOIN de.emp_no, d.dept_no
FROM dept_emp de
         INNER JOIN departments d
                    ON de.dept_no = d.dept_no
WHERE de.from_date >= '2002-03-01';

SELECT COUNT(1)
FROM dept_emp;
SELECT COUNT(1)
FROM departments;

/* 사원번호가 450,000보다 크고 최대 연봉이 100,000보다 큰 데이터를 찾아 출력하시오
   즉, 사원번호가 450,000번을 초과하면서 그동안 받은 연봉 중 한 번이라도 100,000달러를 초과한 적이 있는 사원의 정보를 출력
   표시 컬럼 : 사원번호, 이름, 성
*/
EXPLAIN
SELECT DISTINCT e.emp_no, e.last_name, e.first_name
FROM employees e
         INNER JOIN salaries s
                    ON s.emp_no = e.emp_no
WHERE e.emp_no > 450000
  AND s.salary > 100000;

EXPLAIN
SELECT e.emp_no, e.first_name, e.last_name
FROM employees e
WHERE e.emp_no > 450000
  AND (SELECT MAX(s.salary) FROM salaries s WHERE s.emp_no = e.emp_no);

# 'A'출입문으로 출입한 사원이 총 몇 명인지 구하시오
EXPLAIN
SELECT COUNT(DISTINCT emp_no)
FROM emp_access_logs
WHERE door = 'A';

# 성능개선

EXPLAIN
SELECT e.emp_no, s.avg_salary, s.max_salary, s.min_salary, e.first_name, e.last_name
FROM employees e
         INNER JOIN (SELECT emp_no,
                            ROUND(AVG(salary), 0) AS avg_salary,
                            ROUND(MAX(salary), 0) AS max_salary,
                            ROUND(MIN(salary), 0) AS min_salary
                     FROM salaries
                     GROUP BY emp_no) s
                    ON s.emp_no = e.emp_no
WHERE e.emp_no BETWEEN 10001 AND 10100;

EXPLAIN
SELECT e.emp_no,
       ROUND(AVG(salary), 0)   AS avg_salary,
       ROUND(MAX(s.salary), 0) AS max_salary,
       ROUND(MIN(s.salary), 0) AS min_salary,
       e.first_name,
       e.last_name
FROM employees e
         INNER JOIN salaries s
                    ON e.emp_no = s.emp_no
WHERE (e.emp_no >= 10001 AND e.emp_no < 10101)
GROUP BY s.emp_no;

-- 프로파일링 상태 확인
SELECT @@profiling;
-- 프로파일링 활성화
SET profiling = 1;
-- 프로파일링 비활성화
SET profiling = 0;
-- 프로파일링 히스토리 리셋 후 저장 공간확보
SET @@profiling_history_size = 0;
SET @@profiling_history_size = 10;
-- 프로파일링 내용 확인
SHOW PROFILES;


EXPLAIN
SELECT e.emp_no, e.first_name, e.last_name, e.hire_date
FROM employees e
         INNER JOIN salaries s
                    ON s.emp_no = e.emp_no
WHERE e.emp_no BETWEEN 10001 AND 50000
GROUP BY e.emp_no
ORDER BY SUM(s.salary) DESC
LIMIT 150, 10;


EXPLAIN
SELECT e.emp_no, e.first_name, e.last_name, e.hire_date
FROM employees e
         INNER JOIN (SELECT emp_no
                     FROM salaries
                     WHERE emp_no >= 10001
                       AND emp_no < 50001
                     GROUP BY emp_no
                     ORDER BY SUM(salary) DESC
                     LIMIT 150, 10) s
                    ON s.emp_no = e.emp_no;

# 필요 이상으로 많은 정보를 가져오는 나쁜 SQL문
SELECT COUNT(s.emp_no) AS cnt
FROM (SELECT e.emp_no, dm.dept_no
      FROM (SELECT *
            FROM employees
            WHERE gender = 'M'
              AND emp_no > 300000) e
               LEFT JOIN dept_manager dm
                         ON dm.emp_no = e.emp_no) s;

SELECT COUNT(s.emp_no) AS cnt
FROM (SELECT e.emp_no
      FROM (SELECT *
            FROM employees
            WHERE gender = 'M'
              AND emp_no > 300000) e) s;

SELECT COUNT(emp_no) AS cnt
FROM employees FORCE INDEX (`PRIMARY`)
WHERE gender = 'M'
  AND emp_no > 300000;


# 대량의 데이터를 가져와 조인하는 나쁜 SQL문

SELECT DISTINCT de.dept_no
FROM dept_manager dm
         INNER JOIN dept_emp de
                    ON de.dept_no = dm.dept_no
ORDER BY de.dept_no;

SELECT DISTINCT dept_no
FROM dept_manager;

# 책 result

SELECT de.dept_no
FROM (SELECT DISTINCT dept_no FROM dept_emp) de
WHERE EXISTS (SELECT 1
              FROM dept_manager dm
              WHERE de.dept_no = dm.dept_no)
ORDER BY de.dept_no;

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















