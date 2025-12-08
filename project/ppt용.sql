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
SELECT
    u.user_id, u.name, SUM(p.amount) AS total_movie_spent
FROM payment p FORCE INDEX (idx_pay_type_target_status_created)
JOIN reservation r
  ON p.payment_type = 0              -- 영화 예매 결제
 AND p.type_id      = r.reservation_id
JOIN user u
  ON u.user_id = r.user_id
WHERE p.status = 1                    -- 결제 성공
  AND p.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY u.user_id, u.name
ORDER BY total_movie_spent DESC;

CREATE INDEX idx_pay_type_target_status_created
    ON payment (payment_type, type_id, status, created_at);

SELECT
    u.user_id, u.name, u.email, u.membership_id, u.created_at
FROM user u
WHERE u.is_delete = 0
  AND u.membership_id IN (2, 3, 4)
  AND u.created_at >= '2025-01-01'
  AND u.created_at <  '2026-01-01'
ORDER BY u.created_at DESC;

CREATE INDEX idx_user_delete_member_created
    ON user (is_delete, membership_id, created_at DESC);