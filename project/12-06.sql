EXPLAIN
SELECT m.movie_id,
       m.title,
       COUNT(*)     AS audience_cnt -- 관객 수(예매 건수 기준)
FROM movie m
         JOIN screen_schedule ss
              ON ss.movie_id = m.movie_id
         JOIN reservation r
              ON r.schedule_id = ss.schedule_id
WHERE r.status = 1 -- 결제 완료만
GROUP BY m.movie_id, m.title
ORDER BY audience_cnt DESC; -- 관객 수 기준 박스오피스 랭킹

SELECT m.movie_id,
       m.title,
       COUNT(*)     AS audience_cnt
FROM movie m
         JOIN screen_schedule ss
              ON ss.movie_id = m.movie_id
         JOIN reservation r
              ON r.schedule_id = ss.schedule_id
WHERE r.status = 1
  AND m.release_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY m.movie_id, m.title
ORDER BY audience_cnt DESC;


CREATE INDEX idx_movie_release
    ON movie (release_date, movie_id);
CREATE INDEX idx_res_schedule_status_price
    ON reservation (schedule_id, status, price);



EXPLAIN
SELECT m.movie_id,
       m.title,
       agg.audience_cnt,
       agg.total_price
FROM (SELECT ss.movie_id,
             COUNT(*)     AS audience_cnt,
             SUM(r.price) AS total_price
      FROM reservation r
               JOIN screen_schedule ss
                    ON r.schedule_id = ss.schedule_id
      WHERE r.status = 1
      GROUP BY ss.movie_id) agg
         JOIN movie m
              ON m.movie_id = agg.movie_id
WHERE m.release_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
ORDER BY agg.audience_cnt DESC;

CREATE INDEX idx_res_status_schedule
    ON reservation (status, schedule_id);

SELECT COUNT(1)
FROM reservation
WHERE status = 1;

-- 기존 인덱스 삭제
DROP INDEX idx_movie_release ON movie;
DROP INDEX idx_res_status_schedule ON reservation;
DROP INDEX idx_res_schedule_status ON reservation;
DROP INDEX idx_res_schedule_status_price ON reservation;
-- 새 인덱스 생성: schedule_id 먼저
CREATE INDEX idx_res_schedule_status
    ON reservation (status, schedule_id);

-- 커버링까지 노릴 거면 price까지 포함
CREATE INDEX idx_res_schedule_status_price
    ON reservation (schedule_id, status, price);


EXPLAIN
SELECT pl.user_id,
       SUM(pl.change_amount) AS total_point
FROM point_log pl
WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
  AND pl.created_at < CURRENT_DATE
  AND pl.status = 0
  AND pl.change_amount > 0
GROUP BY pl.user_id;


EXPLAIN
SELECT u.user_id,
       u.point        AS current_point,
       COALESCE(SUM(
                        CASE
                            WHEN pl.status = 0
                                AND pl.created_at < DATE_SUB(CURDATE(), INTERVAL 2 YEAR)
                                THEN pl.change_amount
                            ELSE 0
                            END
                ), 0) AS old_saved,
       COALESCE(SUM(
                        CASE
                            WHEN pl.status IN (1, 2)
                                THEN -pl.change_amount
                            ELSE 0
                            END
                ), 0) AS used_or_expired
FROM user u
         LEFT JOIN point_log pl
                   ON pl.user_id = u.user_id
GROUP BY u.user_id;

ALTER TABLE `user`
    ALTER COLUMN membership_id SET DEFAULT 1;

INSERT INTO user (name, email, password, birth, carrier_code, phone)
VALUES ('김주현', 'dkjh9942@gmail.com',
        '$2a$12$m7qvhiSgQeqtxq.FiT.Wbe0BuMKfWgoLzemM82RIP2KaOE7fFzZSS',
        '1999-04-02', '00901',
        '010-9865-3296');

SELECT u.name, c.`coupon_name`, c.`coupon_id`, cd.`issue_date`
FROM `user` u
         JOIN `coupon_detail` cd
              ON cd.user_id = u.user_id
         JOIN `coupon` c
              ON c.coupon_id = cd.coupon_id
WHERE u.name = '김주현';




