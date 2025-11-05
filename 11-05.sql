EXPLAIN SELECT * FROM employees;

-- p.122
EXPLAIN
SELECT * FROM employees
WHERE emp_no BETWEEN 100001 AND 200000;

-- p.123
EXPLAIN 
SELECT e.emp_no, e.first_name, e.last_name, s.salary,
(SELECT MAX(de.dept_no) FROM dept_emp de 
 WHERE de.emp_no = e.emp_no)
FROM employees e
INNER JOIN salaries s
ON s.emp_no = e.emp_no
WHERE e.emp_no = 10001;

-- select_type - simple
EXPLAIN
SELECT * FROM employees
WHERE emp_no = 100000;

-- 인라인 뷰
EXPLAIN 
SELECT e.emp_no, e.first_name, e.last_name, s.salary     
FROM employees e
INNER JOIN (SELECT emp_no, salary FROM salaries 
				WHERE salary > 80000 ) s
ON e.emp_no = s.emp_no
WHERE e.emp_no BETWEEN 10001 AND 10010;

EXPLAIN  
SELECT e.emp_no, e.first_name, e.last_name, s.salary     
FROM employees e
INNER JOIN salaries s
ON e.emp_no = s.emp_no
WHERE e.emp_no BETWEEN 10001 AND 10010
AND s.salary > 80000;
   
-- 상관 서브쿼리(Correlated Subquery)
EXPLAIN 
SELECT e.emp_no, e.first_name, e.last_name,
(SELECT MAX(dept_no) FROM dept_emp d 
 WHERE d.emp_no = e.emp_no) as cnt
FROM employees e
INNER JOIN salaries s
ON e.emp_no = s.emp_no
WHERE e.emp_no = 10001;

-- s1 알리아스 테이블의 쿼리가 UNION 
-- 최상단에 위치한 쿼리인 것을 확인
EXPLAIN 
SELECT emp_no, first_name, last_name
FROM employees s1
WHERE emp_no = 100001 
  
UNION ALL 
  
SELECT emp_no, first_name, last_name
FROM employees s2
WHERE emp_no = 100002;

-- 인라인 뷰를 제외한 독립적으로 실행되는 
-- 비상관 서브쿼리(Un-Correlated Subquery)를 의미
EXPLAIN  
SELECT ( SELECT COUNT(1) FROM dept_emp ) AS cnt
     , ( SELECT MAX(salary) FROM salaries ) AS salary;

-- 비상관 서브쿼리
EXPLAIN  
SELECT e.first_name, e.last_name,
	( SELECT COUNT(1) 
	FROM dept_emp de
	INNER JOIN dept_manager dm
	ON dm.dept_no = de.dept_no ) AS cnt
FROM employees e
WHERE e.emp_no = 10001;


EXPLAIN  
SELECT e.first_name, e.last_name,
	( SELECT COUNT(1) 
	FROM dept_emp de
	INNER JOIN dept_manager dm
	ON dm.dept_no = de.dept_no
	AND de.emp_no = e.emp_no ) AS cnt
FROM employees e
WHERE e.first_name = 'Matt';

-- 임시테이블은 무조건 type = all
EXPLAIN 
SELECT s.emp_no, s.salary
FROM employees e
	INNER JOIN ( 
	SELECT emp_no, MAX(salary) AS salary 
	FROM salaries 
	WHERE emp_no BETWEEN 10001 AND 20000
	GROUP BY emp_no
	     ) s
	  ON e.emp_no = s.emp_no;

-- 전수조사
EXPLAIN 
SELECT 'M' AS gender2, gender, MAX(hire_date) AS hire_date
FROM employees s1
WHERE gender = 'M'

UNION ALL 

SELECT 'F', gender, MAX(hire_date)
FROM employees s2
WHERE gender = 'F';

-- ---------------------------------------------
EXPLAIN 
SELECT 'M' AS gender2, gender, MAX(hire_date) AS hire_date
FROM employees s1
WHERE gender = 'M'

UNION  

SELECT 'F', gender, MAX(hire_date)
FROM employees s2
WHERE gender = 'F';


-- dependent union
EXPLAIN 
SELECT dm.dept_no
     , ( SELECT s1.first_name 
           FROM employees s1 
          WHERE s1.gender = 'F'
            AND s1.emp_no = dm.emp_no 
							  
          UNION ALL
							
         SELECT s2.first_name 
           FROM employees s2 
          WHERE s2.gender = 'M'
            AND s2.emp_no = dm.emp_no ) AS manager_name
FROM dept_manager dm;


EXPLAIN 
SELECT *
FROM employees e1
WHERE e1.emp_no IN (
       SELECT e2.emp_no FROM employees e2 WHERE e2.first_name = 'Matt'
       UNION
       SELECT e3.emp_no FROM employees e3 WHERE e3.last_name = 'Matt'
		 );

-- UNCACHEABLE SUBQUERY
EXPLAIN
SELECT *
FROM employees 
WHERE emp_no = (SELECT @STATUS 
	             FROM dept_emp 
	             WHERE dept_no='d005'
					 );

-- MATERIALIZED
EXPLAIN
SELECT * FROM employees
WHERE emp_no IN (SELECT emp_no
                 FROM salaries
                 WHERE salary BETWEEN 100 AND 1000
					  );

-- const
EXPLAIN 
SELECT *
FROM employees 
WHERE emp_no = 10001;
 
-- const
EXPLAIN 
SELECT *
FROM dept_emp
WHERE dept_no = 'd005'
AND emp_no = 10001;
   
   
-- const
EXPLAIN
SELECT COUNT(1)
FROM employees e1
WHERE first_name = ( SELECT first_name 
							FROM employees e2
							WHERE emp_no = 100001 );
                       
-- ALL               
EXPLAIN
SELECT COUNT(1)
FROM employees e1
WHERE first_name = 'Jasminko';
  
-- eq_ref 실행계획
EXPLAIN 
SELECT e.emp_no, t.title
FROM employees e
INNER JOIN titles t
ON e.emp_no = t.emp_no
WHERE e.emp_no BETWEEN 10001 AND 10100;

-- ref 실행계획
EXPLAIN 
SELECT STRAIGHT_JOIN e.emp_no, t.title
FROM employees e
INNER JOIN titles t
ON e.emp_no = t.emp_no
WHERE e.emp_no BETWEEN 10001 AND 10100;


EXPLAIN 
SELECT *
FROM titles
WHERE emp_no = 10001;


EXPLAIN 
SELECT *
FROM titles
WHERE emp_no = 10001
AND title = 'Senior Engineer';

EXPLAIN 
SELECT *
FROM titles
WHERE emp_no = 10001
AND title = 'Senior Engineer'
AND from_date = '1986-06-26';



-- 만약 titles 테이블의 to_date 컬럼에 
-- 인덱스가 없다면 아래 쿼리로 생성
CREATE INDEX idx_titles_todate
ON titles(to_date);
    
-- ref_or_null
EXPLAIN
SELECT *
FROM titles 
WHERE to_date = '1985-03-01'
OR to_date IS NULL;


EXPLAIN 
SELECT *
FROM titles
WHERE to_date = '1985-03-01';

-- idx_titles_todate 인덱스를 삭제하고 싶다면
ALTER TABLE titles
DROP INDEX IDX_TITLES_TODATE;


-- NULL 허용 컬럼에 유니크 인덱스를 생성
CREATE TABLE unique_null_test (
    id INT PRIMARY KEY AUTO_INCREMENT
  , nm VARCHAR(10) UNIQUE NULL
);

-- nm 값이 있는 Row Insert
INSERT INTO unique_null_test
SET nm = 'aaa';

-- nm이 NULL인 Row Insert 2번
INSERT INTO unique_null_test
SET nm = NULL;

INSERT INTO unique_null_test
SET nm = NULL;

SELECT * FROM unique_null_test;

EXPLAIN
SELECT id
FROM unique_null_test
WHERE nm IS NULL OR nm = 'aaa';

SELECT id
FROM unique_null_test
WHERE nm = 'aaa';

EXPLAIN
SELECT *
FROM employees
WHERE emp_no BETWEEN 10001 AND 100000;

EXPLAIN
SELECT *
FROM employees
WHERE hire_date BETWEEN '1987-10-01' AND '1987-11-11';

-- 테이블 추가
CREATE TABLE employee_name (
	  emp_no INT NOT NULL
	, first_name VARCHAR(14) NOT NULL
	, last_name VARCHAR(16) NOT NULL 
	, PRIMARY KEY (emp_no)
	, FULLTEXT KEY fx_name(first_name, last_name) WITH PARSER ngram
);


-- 테이블에 레코드 추가
INSERT INTO employee_name
(emp_no, first_name, last_name)
SELECT emp_no, first_name, last_name
FROM employees;

-- MATCH - AGAINST 명령어를 이용
-- 조회시간: 36.8ms
SELECT *
FROM employee_name
WHERE MATCH(first_name, last_name) 
AGAINST ('Facello' IN BOOLEAN MODE);

-- 조회시간: 141ms
SELECT *
FROM employee_name
WHERE first_name LIKE '%Facello%' 
OR last_name LIKE '%Facello%';

EXPLAIN
SELECT emp_no
FROM titles
WHERE title = 'Manager';


-- 사원번호가 1100으로 시작하면서 사원번호가 5자리인 사원의 정보를 모두 조회

SET profiling = 0;

SELECT @@profiling;

SHOW PROFILES;

EXPLAIN
SELECT *
FROM employees
WHERE emp_no BETWEEN 11000 AND 11009;

EXPLAIN
SELECT *
FROM employees
WHERE SUBSTRING(emp_no, 1, 4) = 1100
AND LENGTH(emp_no) = 5;

-- 성별 기준으로 몇 명의 사원이 있는지 출력하는 쿼리
EXPLAIN
SELECT gender, COUNT(gender)
FROM employees
GROUP BY gender;

-- 사용여부 use_yn값이 1인 데이터의 row 수
EXPLAIN
SELECT COUNT(1)
FROM salaries
WHERE use_yn = '1';

