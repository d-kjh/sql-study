-- 2006년 1월 1일 이후에 기록이 생성된 사람 중에, 이름이
-- Steven이거나 Young인 사람이 아닌 고객 정보

SELECT * FROM customer
WHERE create_date >= '2006-01-02 00:00:00'
AND !(first_name = 'STEVEN' OR first_name = 'YOUNG');

SELECT * FROM customer
WHERE create_date >= '2006-01-02 00:00:00'
AND first_name NOT IN ('STEVEN', 'YOUNG');

-- 2005년에 렌탈한 고객의 이름, 성 조회(중복제거)

SELECT DISTINCT c.first_name, c.last_name FROM customer c
INNER JOIN rental r ON r.customer_id = c.customer_id
WHERE r.rental_date BETWEEN '2005-01-01 00:00:00'
AND '2005-12-31 23:59:59';

/* 10달러에서 11.99달러 사이의 모든 결제 정보를 조회
표시 컬럼 : 고객번호, 결제날짜, 금액
*/
SELECT customer_id, amount, payment_date 
FROM payment
WHERE amount BETWEEN 10.00 AND 11.99;

/* FA와 FR 사이에 성이 속하는 고객을 조회 
표시 컬럼 : 성,이름
*/

SELECT last_name, first_name FROM customer
WHERE last_name >= 'FA' AND last_name < 'FS';

/* 영화 제목에 'PET'이 포함된 영화의 등급과 같은 영화들의
제목과 등급을 표시해 주세요
*/

SELECT title, rating FROM film
WHERE rating IN 
(SELECT rating FROM film WHERE title LIKE '%PET%');








