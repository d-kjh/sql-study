EXPLAIN
SELECT
    r.reservation_id,
    r.status,
    r.price,
    r.created_at AS reserved_at,
    ss.running_date,
    ss.start_time,
    t.`name`,
    m.title
FROM reservation r
JOIN screen_schedule ss ON r.schedule_id = ss.schedule_id
JOIN screen s          ON ss.screen_id = s.screen_id
JOIN theater t         ON s.theater_id = t.theater_id
JOIN movie m           ON ss.movie_id = m.movie_id
WHERE r.user_id = 1
  AND r.status IN (1, 2)                      -- 완료 / 취소
ORDER BY r.created_at DESC;

CREATE INDEX idx_res_user_status_created
    ON reservation (user_id, status, created_at DESC);
DROP INDEX idx_res_user_status_created ON reservation;


EXPLAIN
SELECT
    ss.schedule_id,
    ss.running_date,
    ss.start_time,
    t.name,
    s.name,
    m.title,
    COUNT(*)                                         AS reservation_cnt
FROM screen_schedule ss
JOIN screen s      ON ss.screen_id = s.screen_id
JOIN theater t     ON s.theater_id = t.theater_id
JOIN movie m       ON ss.movie_id = m.movie_id
LEFT JOIN reservation r
       ON r.schedule_id = ss.schedule_id
WHERE ss.running_date = '2025-11-26'
  AND ss.is_delete = 0
GROUP BY ss.schedule_id,
         ss.running_date,
         ss.start_time,
         t.name,
         s.name,
         m.title
ORDER BY ss.start_time;


DROP INDEX idx_ss_delete_date_start ON screen_schedule;

CREATE INDEX idx_ss_delete_date_start
    ON screen_schedule (is_delete, running_date, start_time);

DROP INDEX idx_res_schedule ON reservation;

CREATE INDEX idx_res_schedule
    ON reservation (schedule_id);



EXPLAIN
SELECT
    DATE(p.created_at) AS pay_date,
    COUNT(*)           AS pay_cnt,
    SUM(p.amount)      AS total_amount
FROM payment p
WHERE p.status = 1  -- 성공
  AND p.created_at >= '2025-11-20'
  AND p.created_at <  '2025-11-27'   -- (예: 오늘+7일)
GROUP BY DATE(p.created_at)
ORDER BY pay_date;

DROP INDEX idx_pay_status_at ON payment;

CREATE INDEX idx_pay_status_at
    ON payment (status, created_at);


EXPLAIN
SELECT
    u.user_id,
    u.name,
    COUNT(DISTINCT r.reservation_id) AS reservation_cnt,
    SUM(CASE WHEN r.status = 1 THEN r.price ELSE 0 END) AS total_spent
FROM user u
JOIN reservation r
  ON r.user_id = u.user_id
WHERE r.status = 1
  AND r.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY u.user_id, u.name
HAVING total_spent >= 300000
ORDER BY total_spent DESC
LIMIT 100;

CREATE INDEX idx_res_user_status_created
    ON reservation (user_id, status, created_at);

-- VIP 쿼리용 인덱스
CREATE INDEX idx_res_status_created_user
    ON reservation (status, created_at, user_id);

CREATE INDEX idx_res_vip_status_created_user_price
    ON reservation (status, created_at, user_id, price);


DROP INDEX idx_res_user_status_created ON reservation;


SELECT
    u.user_id,
    u.name,
    agg.reservation_cnt,
    agg.total_spent
FROM (
    SELECT
        r.user_id,
        COUNT(*)     AS reservation_cnt,
        SUM(r.price) AS total_spent
    FROM reservation r
    WHERE r.status = 1
      AND r.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    GROUP BY r.user_id
) agg
JOIN user u
  ON u.user_id = agg.user_id
WHERE agg.total_spent >= 300000
ORDER BY agg.total_spent DESC
LIMIT 100;
