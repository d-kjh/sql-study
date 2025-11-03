-- person 테이블
-- DDL, DML, DCL
-- 자연키(의미가 있는 키 - 업무키), 대리키(아무런 의미가 없는 데이터)
CREATE TABLE person (
`name` VARCHAR(40),
eye_color CHAR(2) CHECK (eye_color IN ('BL', 'BR', 'GR')),
birth_date DATE,
address VARCHAR(100),
favorite_foods VARCHAR(200)
);

INSERT INTO person
(`name`, eye_color, birth_date, address, favorite_foods)
VALUES
('김주현', 'BR', '1999-04-02', '대구광역시', '돈까스');

INSERT INTO person
SET `name` = '홍길동',
eye_color = 'GR',
birth_date = '1999-03-02',
address = '대구시 중구',
favorite_foods = '떡볶이';

-- check 제약조건
INSERT INTO person
SET `name` = '김주현',
eye_color = 'GR',
birth_date = '1999-04-02',
address = '대구 동구',
favorite_foods = '떡볶이';

-- select
SELECT * FROM person;

-- 표시 컬럼명을 변경하고 싶을 때
SELECT `name` AS '이름', birth_date 생년월일 FROM person;

-- 대구 동구에 살고 있는 사람 정보
SELECT * FROM person WHERE address = '대구 동구';

SELECT *, address = '대구 동구' FROM person;

-- 대구시 중구에 살면서 눈 색상이 GR인 사람의 정보를 보고싶다.
SELECT * FROM person
WHERE address = '대구시 중구' AND eye_color = 'GR';

-- 수정
UPDATE person
SET eye_color = 'BL'
WHERE `name` = '김주현';

-- row 표시 순서 정렬 order by, 오름차순 asc, 내림차순 desc
SELECT * FROM person
ORDER BY eye_color DESC,`name` DESC;

-- 그룹(group by 문장이 있느냐 없느냐)
-- 그룹 함수 (min, max, count, avg, sum)

SELECT COUNT(*) FROM person;

SELECT MIN(address) FROM person;

SELECT MAX(address) FROM person;

SELECT COUNT(*) FROM person
GROUP BY eye_color;

-- like
SELECT * FROM person
WHERE `name` LIKE '%주현%';

SELECT eye_color, COUNT(*), MIN(address), MAX(address)
FROM person GROUP BY eye_color;

-- 홍길동6, 눈색상 = GR, 좋아하는 음식은 '된장찌개'로 변경
UPDATE person
SET eye_color = 'GR',
favorite_foods = '된장찌개'
WHERE `name` = '홍길동';

-- union, union all

-- 5 rows
SELECT `name` FROM person
UNION
SELECT address FROM person;

-- 8 rows
SELECT `name` FROM person
UNION ALL
SELECT address FROM person;


-- limit
SELECT * FROM person;

SELECT * FROM person
ORDER BY eye_color LIMIT 3;

-- limit 인자 2개 (index, length)
SELECT * from person LIMIT 2, 2;

-- 서브 쿼리

-- select-from 사이는 서브쿼리 스칼라 값이여야 한다
SELECT `name`, (SELECT address FROM person) FROM person;

SELECT `name`, (SELECT address FROM person WHERE address = '대구광역시') FROM person;

-- 인라인 뷰 (inline view) as 필수, from 절에 서브쿼리 사용
-- 테이블 이름도 as 줄 수 있다

SELECT * FROM (SELECT `name`, address FROM person) AS A;

-- where절에서 서브 쿼리
SELECT * FROM person 
WHERE `name` = (SELECT `name` FROM person WHERE address LIKE '%대구광역시%');

-- 컬럼1개 row가 많은 경우
SELECT eye_color FROM person
WHERE address LIKE '%대구%';

SELECT * FROM person
WHERE eye_color IN (SELECT eye_color FROM person
							WHERE address LIKE '%대구%');

-- 컬럼 2개 row가 많은 경우 in 연산자 사용
SELECT `name`, address FROM person
WHERE favorite_foods = '돈까스';

SELECT * FROM person
WHERE (`name`, address) IN (SELECT `name`, address FROM person
										WHERE favorite_foods = '돈까스');

SELECT @@autocommit;

SET autocommit = 0;
-- delete row 삭제
DELETE FROM person
WHERE `name` = '김주현1';

ROLLBACK;
COMMIT;

SELECT ST_ASTEXT(location)
FROM address LIMIT 10;

-- 최소 일주일 동안 대여할 수 있는 g등급의 영화를 찾고 싶다
SELECT * FROM film
WHERE rental_duration >= 7 AND rating = 'G';

-- 최소 일주일 동안 대여할 수 있는 G등급(rating)의 영화이거나
-- PG-13등급이면서 3일 이하로만 대여할 수 있는 영화의 정보
SELECT * FROM film
WHERE (rental_duration >= 7 AND rating = 'G') 
OR (rating = 'PG-13' AND rental_duration <= 3);

-- 40편 이상의 영화를 대여한 모든 고객의 정보
-- 표시 컬럼: 이름, 성, 갯수

SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.customer_id)
FROM customer c
INNER JOIN rental r ON r.customer_id = c.customer_id
GROUP BY r.customer_id HAVING COUNT(r.customer_id) >= 40;


-- 2005년 06월 14일에 대여한 모든 고객 정보
SELECT c.*
FROM customer c
INNER JOIN rental r ON r.customer_id = c.customer_id
WHERE DATE(r.rental_date) = '2005-06-14';

SELECT c.first_name, c.last_name, r.rental_date
FROM customer c
INNER JOIN rental r
ON r.customer_id = c.customer_id
WHERE r.rental_date BETWEEN '2005-06-14 00:00:00' 
AND '2005-06-14 23:59:59';

-- 프로파일링
SELECT @@profiling;

SET profiling = 0;

SHOW PROFILES;

