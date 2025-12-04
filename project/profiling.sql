SELECT @@profiling;
# 프로파일링 활성화
SET PROFILING = 1;
# 프로파일링 비활성화
SET PROFILING = 0;

SET @@profiling_history_size = 0;
SET @@profiling_history_size = 10;

SHOW PROFILES;

EXPLAIN
SELECT user_id, change_amount
FROM point_log
WHERE user_id = 1;

SELECT s.row_label, s.col_no, r.reservation_id, ss.schedule_id
FROM seat s
JOIN reservation_seat rs
ON s.seat_id = rs.seat_id
JOIN screen_schedule ss
ON ss.schedule_id = rs.schedule_id
JOIN reservation r
ON r.schedule_id = ss.schedule_id
WHERE ss.schedule_id = 969
AND  r.reservation_id = 838262;

SELECT * FROM screen_schedule
WHERE running_date = '2025-11-23';

SELECT * FROM reservation
WHERE schedule_id = 969;

SELECT * FROM screen_schedule
WHERE schedule_id = 969;

SELECT * FROM  seat
WHERE screen_id = 1;

SELECT * FROM reservation_count
WHERE reservation_id = 1568881;

EXPLAIN
SELECT
    s.seat_id,
    s.row_label,
    s.col_no,
    CASE WHEN rs.seat_id IS NULL THEN 0 ELSE 1 END AS is_reserved
FROM seat s
LEFT JOIN reservation_seat rs
    ON rs.seat_id = s.seat_id
    AND rs.schedule_id = 969          -- 스케줄 ID는 여기에!
LEFT JOIN reservation r
    ON r.schedule_id = rs.schedule_id
    AND r.status = 1                  -- 상태 조건도 여기에!
WHERE s.screen_id = (
    SELECT screen_id
    FROM screen_schedule ss
    WHERE ss.schedule_id = 969
)
ORDER BY s.row_label, s.col_no;

SET profiling = 1;
SELECT
    s.seat_id,
    s.row_label,
    s.col_no,
    CASE WHEN rs.seat_id IS NULL THEN 0 ELSE 1 END AS is_reserved
FROM seat s
LEFT JOIN reservation_seat rs
    ON rs.seat_id = s.seat_id
    AND rs.schedule_id = 969          -- 스케줄 ID는 여기에!
LEFT JOIN reservation r
    ON r.schedule_id = rs.schedule_id
    AND r.status = 1                  -- 상태 조건도 여기에!
WHERE s.screen_id = (
    SELECT screen_id
    FROM screen_schedule ss
    WHERE ss.schedule_id = 969
)
ORDER BY s.row_label, s.col_no;
SHOW PROFILES;


SELECT
    u.user_id,
    COALESCE(SUM(pl.change_amount), 0) AS total_point_1year
FROM user u
LEFT JOIN point_log pl
    ON pl.user_id = u.user_id
    AND pl.status = 0         -- 적립만
    AND pl.created_at >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
WHERE u.user_id = 12;

SELECT user_id, count(*) FROM point_log
WHERE created_at >= date_sub(now(),INTERVAL  1 year)
AND status = 0
GROUP BY user_id;