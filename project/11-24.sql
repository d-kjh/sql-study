SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS non_user;

SET FOREIGN_KEY_CHECKS = 1;

ALTER TABLE `non_user`
    AUTO_INCREMENT = 1;

ALTER TABLE `point_log`
    AUTO_INCREMENT = 1;

ALTER TABLE ticket_discount
    DROP PRIMARY KEY,
    ADD PRIMARY KEY (benefit_id, reservation_seat_id, benefit_code);

SELECT COUNT(1)
FROM `user`
WHERE membership_id = 1;

SELECT count(1)
FROM `user`
WHERE membership_id = 2;

SELECT count(1)
FROM `user`
WHERE membership_id = 3;

SELECT count(1)
FROM `user`
WHERE membership_id = 4;

SELECT count(1)
FROM `membership_log`;

SELECT ROUND(COUNT(*) * 0.01)
FROM `user`;

UPDATE `user`
SET membership_id = 5
WHERE membership_id = 4
ORDER BY RAND()
LIMIT 8897;


UPDATE `user`
SET is_delete = 1
ORDER BY rand()
LIMIT 10000;

SELECT count(*) FROM user
WHERE point >= 24000 AND ('2023-11-24 00:00:00' <= created_at);

UPDATE `user`
SET membership_id = 5
WHERE membership_id = 5
ORDER BY rand()
LIMIT 4624;

UPDATE `user`
SET point = FLOOR(24000 + RAND() * 6000)
WHERE membership_id = 5 AND point < 24000;



# 포인트 로그 테이블 insert 작업 (적립은 아직 없음 - DB 이관 작업 느낌)

TRUNCATE TABLE point_log;

INSERT INTO point_log
    (user_id, change_amount, balance_after, created_at, status)
SELECT
    u.user_id,
    u.point,         -- 지금까지 적립된 포인트 전체
    u.point,         -- 현재 잔액 = 전체 적립
    u.created_at,    -- 앞에서 랜덤으로 만들어둔 가입일/기준일
    0                -- 0 = 적립
FROM `user` u
WHERE u.point > 0;

INSERT INTO point_log
    (user_id, change_amount, balance_after, created_at, status)
SELECT
    pl.user_id,
    ROUND(-pl.change_amount * 0.3, 2) AS change_amount,    -- 30% 소멸 (음수)
    pl.balance_after + ROUND(-pl.change_amount * 0.3, 2) AS balance_after,
    DATE_ADD(pl.created_at, INTERVAL 24 MONTH) AS created_at,
    2 AS status   -- 2 = 소멸
FROM point_log pl
WHERE pl.status = 0
  AND DATE_ADD(pl.created_at, INTERVAL 24 MONTH) <= NOW();

SELECT *
FROM point_log
WHERE status = 2;

UPDATE `user` u
SET u.point = (
    SELECT IFNULL(SUM(pl.change_amount), 0)
    FROM point_log pl
    WHERE pl.user_id = u.user_id
);

UPDATE `user`
SET membership_id =
    CASE
        WHEN point >= 24000 THEN 5   -- MVIP
        WHEN point >= 18000 THEN 4   -- VVIP
        WHEN point >= 12000 THEN 3   -- VIP
        WHEN point >= 6000  THEN 2   -- Friends
        ELSE 1                       -- Basic
    END;


SELECT
    pl.user_id,
    SUM(CASE WHEN pl.change_amount > 0 THEN pl.change_amount ELSE 0 END) AS earned_last_year
FROM point_log pl
WHERE pl.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
  AND pl.created_at < CURDATE()           -- 오늘은 제외 (전월까지)
GROUP BY pl.user_id;
