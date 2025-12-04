SELECT ss.*
FROM screen_schedule ss
         JOIN screen sc
              ON ss.screen_id = sc.screen_id
WHERE sc.theater_id = 38
  AND ss.movie_id = 41
  AND ss.is_delete = 0;

SELECT @@profiling;
# 프로파일링 활성화
SET PROFILING = 1;
# 프로파일링 비활성화
SET PROFILING = 0;

SET @@profiling_history_size = 0;
SET @@profiling_history_size = 10;

SHOW PROFILES;



EXPLAIN
SELECT reservation_id, status
FROM reservation
WHERE non_user_id IS NULL
  AND user_id IS NULL;
SHOW PROFILES;


SELECT COUNT(1)
FROM reservation
WHERE user_id IS NOT NULL
GROUP BY user_id;

SELECT COUNT(1)
FROM reservation
WHERE non_user_id IS NOT NULL
GROUP BY non_user_id;

ALTER TABLE reservation
ADD INDEX idx_nonuser_user (non_user_id, user_id);

ALTER TABLE reservation
DROP INDEX idx_nonuser_user;

