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