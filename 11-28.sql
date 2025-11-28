SELECT
    nu.non_user_id,
    MAX(ss.end_time) AS last_end_time,
    DATE_ADD(MAX(ss.end_time), INTERVAL 7 DAY) AS new_expire_at
FROM non_user nu
JOIN reservation r
      ON r.non_user_id = nu.non_user_id
JOIN screen_schedule ss
      ON ss.schedule_id = r.schedule_id

GROUP BY nu.non_user_id;


UPDATE non_user nu
JOIN (
    SELECT
        r.non_user_id,
        DATE_ADD(MAX(ss.end_time), INTERVAL 7 DAY) AS new_expire_at
    FROM reservation r
    JOIN screen_schedule ss ON ss.schedule_id = r.schedule_id
    WHERE r.non_user_id IS NOT NULL
      AND r.status IN (1,2)       -- 결제완료/취소만
      AND r.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)   -- 성능 핵심 포인트
    GROUP BY r.non_user_id
) x ON x.non_user_id = nu.non_user_id
SET nu.expire_at = x.new_expire_at;

ALTER TABLE non_user
ADD INDEX idx_non_user_expire (expire_at);
