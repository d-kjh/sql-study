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


DROP INDEX idx_res_vip_status_created_user_price ON reservation;


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

EXPLAIN
SELECT
    DATE(p.created_at) AS pay_date,
    COUNT(*)           AS pay_cnt,
    SUM(p.amount)      AS total_amount
FROM payment p
FORCE INDEX (idx_pay_status_created_amount)
WHERE p.status = 1  -- 성공
  AND p.created_at >= '2025-11-27'
  AND p.created_at <  '2025-11-28'
GROUP BY DATE(p.created_at)
ORDER BY pay_date;

CREATE INDEX idx_pay_status_created_amount
    ON payment (status, created_at, amount);

CREATE INDEX idx_pay_status_at
    ON payment (status, created_at);

DROP INDEX idx_pay_status_at ON payment;


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

CREATE INDEX idx_res_vip_status_created_user_price
ON reservation (status, created_at, user_id, price);

DROP INDEX idx_res_vip_status_created_user_price ON reservation;

SELECT m.movie_id,
       m.title,
       COUNT(*)     AS audience_cnt,
       SUM(r.price) AS total_price
FROM movie m
JOIN screen_schedule ss ON ss.movie_id = m.movie_id
JOIN reservation r      ON r.schedule_id = ss.schedule_id
WHERE r.status = 1
GROUP BY m.movie_id, m.title
ORDER BY audience_cnt DESC;


-- 영화별 박스오피스 전용 인덱스
CREATE INDEX idx_res_status_schedule_price
    ON reservation (status, schedule_id, price);

DROP INDEX idx_res_status_schedule_price on reservation;

EXPLAIN
SELECT
    m.movie_id,
    m.title,
    COUNT(*)     AS audience_cnt
FROM reservation r
    FORCE INDEX (idx_res_status_schedule_price)
JOIN screen_schedule ss ON ss.schedule_id = r.schedule_id
JOIN movie m            ON m.movie_id    = ss.movie_id
WHERE r.status = 1
GROUP BY m.movie_id, m.title
ORDER BY audience_cnt DESC;

SELECT count(1) FROM reservation r
WHERE non_user_id is NULL AND user_id IS NULL;

EXPLAIN
SELECT
    pl.point_log_id,
    pl.change_amount,
    pl.status,          -- 0: 적립, 1: 사용, 2: 소멸
    pl.created_at
FROM point_log pl
WHERE pl.user_id = 12
  AND pl.created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
ORDER BY pl.created_at DESC;

EXPLAIN
SELECT
    u.user_id,
    u.name,
    u.email,
    u.created_at
FROM user u
WHERE u.is_delete = 0
  AND u.created_at < DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
  AND NOT EXISTS (
      SELECT 1
      FROM reservation r
      WHERE r.user_id = u.user_id
        AND r.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
  )
  AND NOT EXISTS (
      SELECT 1
      FROM point_log pl
      WHERE pl.user_id = u.user_id
        AND pl.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
  );

EXPLAIN
SELECT
    u.user_id,
    u.name,
    u.membership_id,
    COUNT(*) AS available_coupon_cnt
FROM user u
JOIN coupon_detail cd
  ON cd.user_id = u.user_id
WHERE cd.status = 0                                  -- 미사용
  AND cd.expired_date >= CURDATE()                  -- 아직 안 만료
GROUP BY u.user_id, u.name, u.membership_id
ORDER BY available_coupon_cnt DESC;


CREATE INDEX idx_coupon_detail_status_expired_user
    ON coupon_detail (status, expired_date, user_id);


-- 관리자 대시보드: 최근 성공 결제 100건
SELECT
    p.payment_id,
    p.payment_type,      -- 있으면
    p.type_id,   -- 있으면
    p.amount,
    p.created_at
FROM payment p
WHERE p.status = 1              -- 성공 결제
ORDER BY p.created_at DESC
LIMIT 100;



SELECT
    r.reservation_id,
    r.user_id,
    r.schedule_id,
    r.price,
    r.created_at
FROM reservation r
WHERE r.status = 1
  AND r.created_at >= '2025-11-20'
  AND r.created_at <  '2025-11-27'
ORDER BY r.created_at DESC;

-- 관리자: 특정 등급 + 기간 조건으로 회원 목록 조회
EXPLAIN
SELECT
    u.user_id,
    u.name,
    u.email,
    u.membership_id,
    u.created_at
FROM user u
WHERE u.is_delete = 0
  AND u.membership_id IN (2, 3, 4)
  AND u.created_at >= '2025-01-01'
  AND u.created_at <  '2026-01-01'
ORDER BY u.created_at DESC;

CREATE INDEX idx_user_delete_member_created
    ON user (is_delete, membership_id, created_at DESC);


SELECT
    u.user_id,
    u.name,
    u.email,
    u.created_at
FROM user u
WHERE u.is_delete = 0
  AND u.created_at < DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
  AND NOT EXISTS (
      SELECT 1
      FROM reservation r
      WHERE r.user_id = u.user_id
  )
ORDER BY u.created_at
LIMIT 100;

SELECT
    u.user_id,
    u.name,
    u.membership_id,

    r.reservation_id,
    r.status              AS reservation_status,
    r.price               AS reservation_price,
    r.created_at          AS reservation_at,

    ss.running_date,
    ss.start_time,

    t.name                AS theater_name,
    s.name                AS screen_name,
    m.title               AS movie_title,

    p.payment_id,
    p.amount              AS payment_amount,
    p.created_at          AS payment_at

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
 AND p.type_id      = r.reservation_id
 AND p.status       = 1

WHERE u.user_id = 12
  AND r.status = 1
  AND r.created_at >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)

ORDER BY r.created_at DESC
LIMIT 50;

CREATE INDEX idx_res_user_status_created
    ON reservation (user_id, status, created_at DESC);
CREATE INDEX idx_pay_type_target_status_created
    ON payment (payment_type, type_id, status, created_at);

DROP INDEX idx_res_user_status_created on reservation;
DROP INDEX idx_pay_type_target_status_created on payment;

-- 최근 1개월 동안 영화 + 스토어 결제 합산 기준 TOP 100 유저
SELECT
    u.user_id,
    u.name,
    SUM(x.paid_amount) AS total_spent
FROM (
    -- 1) 영화 예매 결제
    SELECT
        r.user_id,
        p.amount AS paid_amount
    FROM payment p FORCE INDEX (idx_pay_type_status_created_target)
    JOIN reservation r
      ON p.payment_type = 0              -- 영화 예매 결제
     AND p.type_id      = r.reservation_id
    WHERE p.status = 1                    -- 결제 성공
      AND p.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)

    UNION ALL
        -- 2) 스토어 결제
    SELECT
        o.user_id,
        p.amount AS paid_amount
    FROM payment p FORCE INDEX (idx_pay_type_status_created_target)
    JOIN `order` o
      ON p.payment_type = 1              -- 스토어 결제
     AND p.type_id      = o.order_id
    WHERE p.status = 1
      AND p.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
) x
JOIN user u
  ON u.user_id = x.user_id
GROUP BY u.user_id, u.name
ORDER BY total_spent DESC
LIMIT 100;

CREATE INDEX idx_pay_type_status_created_target
    ON payment (payment_type, status, created_at, type_id, amount);

DROP INDEX idx_pay_type_status_created_target on payment;

-- 최근 1개월, 영화 예매 결제 기준 TOP 100 유저
SELECT
    u.user_id,
    u.name,
    SUM(p.amount) AS total_movie_spent
FROM payment p FORCE INDEX (idx_pay_type_status_created_target)
JOIN reservation r
  ON p.payment_type = 0              -- 영화 예매 결제
 AND p.type_id      = r.reservation_id
JOIN user u
  ON u.user_id = r.user_id
WHERE p.status = 1                    -- 결제 성공
  AND p.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY u.user_id, u.name
ORDER BY total_movie_spent DESC
LIMIT 100;


-- 최근 1개월, 스토어 결제 기준 TOP 100 유저
SELECT
    u.user_id,
    u.name,
    SUM(p.amount) AS total_store_spent
FROM payment p
JOIN `order` o
  ON p.payment_type = 1              -- 스토어 결제
 AND p.type_id      = o.order_id
JOIN user u
  ON u.user_id = o.user_id
WHERE p.status = 1                    -- 결제 성공
  AND p.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY u.user_id, u.name
ORDER BY total_store_spent DESC
LIMIT 100;

CREATE INDEX idx_pay_type_status_created_target
    ON payment (
        payment_type,   -- 0(영화) / 1(스토어)
        status,         -- 1: 성공
        created_at,     -- 최근 1개월 범위
        type_id,        -- reservation_id 또는 order_id
        amount          -- SUM(amount) 커버링용
    );
