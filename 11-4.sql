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

-- 성이 Q로 시작하는 고객 조회
SELECT * FROM customer
WHERE last_name LIKE 'Q%';

SELECT * FROM customer
WHERE LEFT(last_name, 1) = 'Q';

SELECT * FROM customer
WHERE last_name > 'Q' AND last_name < 'R';

-- 대여를 반납하지 않은 정보를 조회
-- 표시 컬럼 대여ID, 고객ID
SELECT rental_id, customer_id FROM rental
WHERE return_date IS NULL;

/* 고객번호가 5가 아니면서 결제날짜가 '2005-08-23'이거나
결제금액이 8달러 이상인 payment_id를 조회하시오

문자열 비교보다 숫자비교를 먼저하는게 성능이 무조건 좋다
*/

SELECT payment_id FROM payment
WHERE customer_id != 5 
AND (payment_date BETWEEN '2005-08-23 00:00:00' 
AND '2005-08-23 23:59:59' OR amount >= 8.00);

-- payments 테이블에서 금액이 1.98, 7.98 또는 9.98인 모든행을 조회
SELECT * FROM payment
WHERE amount IN(1.98, 7.98, 9.98);

-- 성의 두 번째 위치에 A가 있고 A 다음에 W가 있는 모든 고객을 조회

SELECT * FROM customer
WHERE last_name LIKE '_AW%';

-- 모든 고객의 성, 이름, 주소 조회

SELECT a.address, c.last_name, c.first_name 
FROM address a
INNER JOIN customer c 
ON c.address_id = a.address_id;



