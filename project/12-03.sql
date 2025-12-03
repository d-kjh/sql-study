SELECT ss.*
FROM screen_schedule ss
JOIN screen sc
    ON ss.screen_id = sc.screen_id
WHERE sc.theater_id = 38
  AND ss.movie_id   = 41
  AND ss.is_delete  = 0;