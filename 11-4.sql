-- 2006년 1월 1일 이후에 기록이 생성된 사람 중에, 이름이
-- Steven이거나 Young인 사람이 아닌 고객 정보

SELECT * FROM customer
WHERE create_date >= '2006-01-02 00:00:00'
AND (first_name != 'STEVEN' AND first_name != 'YOUNG');

SELECT * FROM customer
WHERE create_date >= '2006-01-02 00:00:00'
AND first_name NOT IN ('STEVEN', 'YOUNG');