SELECT first_name
  FROM employees
 ORDER BY first_name DESC
 LIMIT 1;

-- SELECT (1) 정순
SELECT first_name
  FROM employees
 WHERE first_name >= 'Anneke'
 ORDER BY first_name ASC LIMIT 4;

-- SELECT (2) 역순
SELECT first_name
  FROM employees
 ORDER BY first_name DESC LIMIT 6;


-- SELECT (3)
SELECT *
  FROM dept_emp
 WHERE dept_no = 'd002'
   AND emp_no >= 100114;

-- SELECT (4)
SELECT *
  FROM employees
 WHERE first_name LIKE '%mer';


-- SELECT (5)
SELECT *
  FROM dept_emp
 WHERE emp_no >= 10144;

-- SELECT (6)
SELECT *
  FROM employees
 WHERE first_name LIKE 'Abd%';


-- SELECT (7)
SELECT *
  FROM dept_emp
 WHERE dept_no >= 'd002';


 -- SELECT (8)
SELECT *
  FROM dept_emp
 WHERE dept_no >= 'd002'
   AND emp_no >= 100114;