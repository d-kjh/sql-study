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


