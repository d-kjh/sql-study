SELECT ss.*
FROM screen_schedule ss
         JOIN screen sc
              ON ss.screen_id = sc.screen_id
WHERE sc.theater_id = 38
  AND ss.movie_id = 41
  AND ss.is_delete = 0;

EXPLAIN
SELECT reservation_id, status
FROM reservation
WHERE non_user_id IS NULL
  AND user_id IS NULL;

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