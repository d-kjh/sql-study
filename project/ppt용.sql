-- 최근 3개월동안 영화 예매한 내역
EXPLAIN
SELECT u.user_id,
       u.name,
       u.membership_id,
       r.reservation_id,
       r.status     AS reservation_status,
       r.price,
       r.created_at AS reservation_at,
       ss.running_date,
       ss.start_time,
       t.name,
       s.name,
       m.title,
       p.payment_id,
       p.amount,
       p.created_at AS payment_at
FROM user u
         JOIN reservation r
              ON r.user_id = u.user_id
         JOIN screen_schedule ss
              ON ss.schedule_id = r.schedule_id
         JOIN screen s
              ON s.screen_id = ss.screen_id
         JOIN theater t
              ON t.theater_id = s.theater_id
         JOIN movie m
              ON m.movie_id = ss.movie_id
         LEFT JOIN payment p
                   ON p.payment_type = 0
                       AND p.type_id = r.reservation_id
                       AND p.status = 1
WHERE u.user_id = 12
  AND r.status = 1
  AND r.created_at >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
ORDER BY r.created_at DESC;

CREATE INDEX idx_res_user_status_created
    ON reservation (user_id, status, created_at DESC);
CREATE INDEX idx_pay_type_target_status_created
    ON payment (payment_type, type_id, status, created_at);

DROP INDEX idx_res_user_status_created ON reservation;
DROP INDEX idx_pay_type_target_status_created ON payment;

EXPLAIN
SELECT DATE(p.created_at) AS pay_date,
       COUNT(*)           AS pay_cnt,
       SUM(p.amount)      AS total_amount
FROM payment p
WHERE p.status = 1 -- 성공
  AND p.created_at >= '2025-11-20'
  AND p.created_at < '2025-11-28'
GROUP BY DATE(p.created_at)
ORDER BY pay_date;

CREATE INDEX idx_pay_status_at
    ON payment (status, created_at);

DROP INDEX idx_pay_status_at ON payment;

DROP INDEX idx_pay_type_target_status_created ON payment;
DROP INDEX idx_payment_completed_status_type ON payment;
DROP INDEX idx_pay_status_created_amount ON payment;

-- 최근 1개월, 영화 예매 결제 기준 TOP 100 유저
SELECT u.user_id,
       u.name,
       SUM(p.amount) AS total_movie_spent
FROM payment p FORCE INDEX (idx_pay_type_target_status_created)
         JOIN reservation r
              ON p.payment_type = 0 -- 영화 예매 결제
                  AND p.type_id = r.reservation_id
         JOIN user u
              ON u.user_id = r.user_id
WHERE p.status = 1 -- 결제 성공
  AND p.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY u.user_id, u.name
ORDER BY total_movie_spent DESC;

CREATE INDEX idx_pay_type_target_status_created
    ON payment (payment_type, type_id, status, created_at);

SELECT u.user_id,
       u.name,
       u.email,
       u.membership_id,
       u.created_at
FROM user u
WHERE u.is_delete = 0
  AND u.membership_id IN (2, 3, 4)
  AND u.created_at >= '2025-01-01'
  AND u.created_at < '2026-01-01'
ORDER BY u.created_at DESC;

CREATE INDEX idx_user_delete_member_created
    ON user (is_delete, membership_id, created_at DESC);

EXPLAIN
SELECT u.user_id,
       u.name,
       u.membership_id,
       r.reservation_id,
       r.status     AS reservation_status,
       r.price,
       r.created_at AS reservation_at,
       ss.running_date,
       ss.start_time,
       t.name,
       s.name,
       m.title,
       p.payment_id,
       p.amount,
       p.created_at AS payment_at
FROM user u
         JOIN reservation r
              ON r.user_id = u.user_id
         JOIN screen_schedule ss
              ON ss.schedule_id = r.schedule_id
         JOIN screen s
              ON s.screen_id = ss.screen_id
         JOIN theater t
              ON t.theater_id = s.theater_id
         JOIN movie m
              ON m.movie_id = ss.movie_id
         LEFT JOIN payment p
                   ON p.payment_type = 0
                       AND p.type_id = r.reservation_id
                       AND p.status = 1
WHERE u.user_id = 12
  AND r.status = 1
  AND r.created_at >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
ORDER BY r.created_at DESC;

EXPLAIN
SELECT DATE(p.created_at) AS pay_date,
       COUNT(*)           AS pay_cnt,
       SUM(p.amount)      AS total_amount
FROM payment p
WHERE p.status = 1 -- 성공
  AND p.created_at >= '2025-11-20'
  AND p.created_at < '2025-11-28'
GROUP BY DATE(p.created_at)
ORDER BY pay_date;

CREATE INDEX idx_pay_status_at ON payment (status, created_at);

DROP INDEX idx_pay_status_at ON payment;

ALTER TABLE payment
    ADD INDEX idx_pay_report (status, created_at, amount);

DROP INDEX idx_pay_report ON payment;


CREATE INDEX idx_res_user_status_created
    ON reservation (user_id, status, created_at DESC);
CREATE INDEX idx_pay_type_target_status_created
    ON payment (payment_type, type_id, status, created_at);

DROP INDEX idx_res_user_status_created ON reservation;
DROP INDEX idx_pay_type_target_status_created ON payment;

SELECT card_num
FROM user
LIMIT 1;

INSERT INTO user (name, email, birth, password, card_num, carrier_code, phone)
VALUES ( '중복테스트', 'test@test.com', '1999-12-01', 'pw', '0000-1276-2997-8587'
       , '00901', '010-0101-0101');

SELECT *
FROM user
WHERE card_num = '0000-1276-2997-8587';

SELECT *
FROM user
WHERE name = '중복테스트';


SELECT cd.user_coupon_id, cd.status
FROM coupon_detail cd
         JOIN `user` u
              ON u.user_id = cd.user_id
WHERE u.name = '김주현';

UPDATE coupon_detail
SET status = 1
WHERE user_coupon_id = 264047;

SELECT *
FROM coupon_log
WHERE user_coupon_id = 264047;

SELECT * from user_voucher WHERE status = 0 LIMIT 1;

INSERT INTO user_voucher (user_id, order_id, status, store_item_id, issue_date)
VALUES (1,  1, 0, 1, now());

select * from user_voucher
WHERE user_voucher_id = 15922;

UPDATE user_voucher
SET status = 1
WHERE user_voucher_id = 15922;


-- 진행중인 이벤트 (오늘 이전에 종료됨)
INSERT INTO event (event_id, event_title, event_desc, status, start_date, end_date, event_code)
VALUES (1000, '연말 이벤트', 'test용 이벤트' ,0,'2025-12-01' ,NOW() - INTERVAL 1 DAY, '00601');

-- 이 이벤트의 참여자 3명
INSERT INTO event_part (part_id, event_id, user_id, status)
VALUES
  (1, 1000, 1, 0),   -- 참여중 → 종료되면 2로 바뀜
  (2, 1000, 2, 0),
  (3, 1000, 3, 1);   -- 이미 당첨/처리 상태라 그대로 둠

-- 종료 대상 이벤트 미리보기
SELECT event_id, event_title, status, start_date, end_date
FROM event
WHERE end_date < NOW()
  AND status = 0;



-- 종료 대상 이벤트의 '참여중' 참여자 미리보기
SELECT ep.part_id, ep.event_id, ep.user_id, ep.status
FROM event_part ep
JOIN event e ON ep.event_id = e.event_id
WHERE e.end_date < NOW()   -- 종료 시점 지난 이벤트
  AND e.status = 0         -- 아직 진행중으로 찍혀 있는 애들
  AND ep.status = 0;       -- 참여중 상태


SELECT event_id, event_title, status, end_date
FROM event
WHERE event_id = 1000;

SELECT part_id, event_id, user_id, status
FROM event_part
WHERE event_id = 1000;


-- 1. 이벤트 종료 처리
UPDATE event
SET status = 1
WHERE end_date < NOW()
  AND status = 0;

-- 2. 참여자 상태 처리
UPDATE event_part ep
JOIN event e ON ep.event_id = e.event_id
SET ep.status = 2
WHERE e.status = 1
  AND ep.status = 0;


