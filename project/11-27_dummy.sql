-- 혹시 기존에 있으면 먼저 삭제
DROP PROCEDURE IF EXISTS populate_voucher_discount_dummy;
DELIMITER $$

CREATE PROCEDURE populate_voucher_discount_dummy(
    IN p_voucher_limit INT
)
BEGIN
    INSERT INTO ticket_discount (benefit_id, reservation_seat_id, benefit_code, applied_amount)
    SELECT t.user_voucher_id,     -- benefit_id : 교환권 PK
           t.reservation_seat_id, -- reservation_seat_id : 좌석 PK
           '01103',               -- benefit_code : 교환권
           t.seat_price           -- applied_amount : 티켓 1장 가격
    FROM (SELECT MIN(rs.reservation_seat_id) AS reservation_seat_id, -- 이 교환권이 사용할 좌석 1개
                 uv.user_voucher_id,
                 sp.seat_price
          FROM user_voucher uv
                   JOIN store_item si
                        ON si.store_item_id = uv.store_item_id
                   JOIN user u
                        ON u.user_id = uv.user_id
                   JOIN reservation r
                        ON r.user_id = u.user_id
                   JOIN reservation_seat_list rsl
                        ON rsl.reservation_id = r.reservation_id
                   JOIN reservation_seat rs
                        ON rs.reservation_seat_id = rsl.reservation_seat_id
                   JOIN (SELECT rc2.reservation_id,
                                ROUND(MAX(rc2.price / NULLIF(rc2.count, 0)), 0) AS seat_price
                         FROM reservation_count rc2
                         GROUP BY rc2.reservation_id) sp
                        ON sp.reservation_id = r.reservation_id
                   LEFT JOIN ticket_discount td
                             ON td.reservation_seat_id = rs.reservation_seat_id
          WHERE uv.status = 0                  -- 미사용 교환권
            AND si.store_item_code = '00401'   -- 영화 교환권 코드
            AND r.status = 1                   -- 예매 완료
            AND td.reservation_seat_id IS NULL -- 아직 할인 안 붙은 좌석
          GROUP BY uv.user_voucher_id, sp.seat_price
             -- ★ 교환권 한 장당 딱 1좌석
         ) t
    ORDER BY RAND()
    LIMIT p_voucher_limit;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS populate_coupon_discount_dummy;
DELIMITER $$

CREATE PROCEDURE populate_coupon_discount_dummy(
    IN p_coupon_limit INT
)
BEGIN
    INSERT INTO ticket_discount (benefit_id, reservation_seat_id, benefit_code, applied_amount)
    SELECT t.user_coupon_id,      -- benefit_id : user_coupon_id
           t.reservation_seat_id, -- 좌석 PK
           '01102',               -- 쿠폰
           t.applied_amount       -- 실제 깎인 금액
    FROM (SELECT MIN(rs.reservation_seat_id) AS reservation_seat_id, -- 이 쿠폰이 붙을 좌석 1개
                 cd.user_coupon_id,
                 CASE
                     WHEN c.discount_type = 0 THEN -- 정액
                         LEAST(c.discount_value, sp.seat_price)
                     WHEN c.discount_type = 1 THEN -- 정률
                         ROUND(
                                 LEAST(
                                         sp.seat_price * (c.discount_value / 100),
                                         IFNULL(c.max_discount_amount, sp.seat_price)
                                 ), 0
                         )
                     ELSE 0
                     END                     AS applied_amount,
                 sp.seat_price
          FROM coupon_detail cd
                   JOIN coupon c
                        ON c.coupon_id = cd.coupon_id
                   JOIN user u
                        ON u.user_id = cd.user_id
                   JOIN reservation r
                        ON r.user_id = u.user_id
                   JOIN reservation_seat_list rsl
                        ON rsl.reservation_id = r.reservation_id
                   JOIN reservation_seat rs
                        ON rs.reservation_seat_id = rsl.reservation_seat_id
                   JOIN (SELECT rc2.reservation_id,
                                ROUND(MAX(rc2.price / NULLIF(rc2.count, 0)), 0) AS seat_price
                         FROM reservation_count rc2
                         GROUP BY rc2.reservation_id) sp
                        ON sp.reservation_id = r.reservation_id
                   LEFT JOIN ticket_discount td
                             ON td.reservation_seat_id = rs.reservation_seat_id
          WHERE cd.status = 0                  -- 미사용 쿠폰
            AND r.status = 1                   -- 예매 완료
            AND td.reservation_seat_id IS NULL -- 아직 할인 없는 좌석
          GROUP BY cd.user_coupon_id, sp.seat_price,
                   c.discount_type, c.discount_value, c.max_discount_amount
             -- ★ 쿠폰 한 장당 딱 1좌석
         ) t
    ORDER BY RAND()
    LIMIT p_coupon_limit;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS populate_point_discount_dummy;
DELIMITER $$

CREATE PROCEDURE populate_point_discount_dummy(
    IN p_point_limit INT
)
BEGIN
    SET @prev_user := NULL;
    SET @used_sum := 0;

    INSERT INTO ticket_discount (benefit_id, reservation_seat_id, benefit_code, applied_amount)
    SELECT seat.user_id,             -- benefit_id : user_id
           seat.reservation_seat_id, -- 좌석 PK
           '01101',                  -- 포인트
           seat.seat_price           -- 이 좌석 1장 가격 = 포인트 사용 금액
    FROM (SELECT r.user_id,
                 rs.reservation_seat_id,
                 sp.seat_price,
                 u.point AS point_balance
          FROM reservation_seat rs
                   JOIN reservation_seat_list rsl
                        ON rsl.reservation_seat_id = rs.reservation_seat_id
                   JOIN reservation r
                        ON r.reservation_id = rsl.reservation_id
                   JOIN (SELECT rc2.reservation_id,
                                ROUND(MAX(rc2.price / NULLIF(rc2.count, 0)), 0) AS seat_price
                         FROM reservation_count rc2
                         GROUP BY rc2.reservation_id) sp
                        ON sp.reservation_id = r.reservation_id
                   JOIN user u
                        ON u.user_id = r.user_id
                   LEFT JOIN ticket_discount td
                             ON td.reservation_seat_id = rs.reservation_seat_id
          WHERE r.status = 1
            AND td.reservation_seat_id IS NULL -- 다른 할인 안 붙은 좌석만
            AND u.point >= sp.seat_price       -- 1장 가격보다 포인트가 많을 때만
          ORDER BY r.user_id,
                   RAND() -- 유저별 좌석 랜덤
         ) seat
    WHERE (
              @used_sum := IF(@prev_user = seat.user_id,
                              @used_sum + seat.seat_price,
                              seat.seat_price)
              ) <= seat.point_balance
      AND (@prev_user := seat.user_id) IS NOT NULL
    LIMIT p_point_limit;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS populate_all_discount_dummy;
DELIMITER $$

CREATE PROCEDURE populate_all_discount_dummy(
    IN p_point_limit INT,
    IN p_coupon_limit INT,
    IN p_voucher_limit INT
)
BEGIN
    TRUNCATE TABLE ticket_discount;

    CALL populate_voucher_discount_dummy(p_voucher_limit);
    CALL populate_coupon_discount_dummy(p_coupon_limit);
    CALL populate_point_discount_dummy(p_point_limit);
END$$

DELIMITER ;


CALL populate_all_discount_dummy(
        13625, 9364, 14952);

SELECT benefit_id, reservation_seat_id, benefit_code, applied_amount
FROM ticket_discount
ORDER BY created_at DESC
LIMIT 30;

SELECT COUNT(1)
FROM ticket_discount
WHERE benefit_code = '01103';

SELECT r.non_user_id,
       MAX(TIMESTAMP(ss.running_date, ss.end_time)) AS last_end_at
FROM reservation r
         JOIN screen_schedule ss
              ON ss.schedule_id = r.schedule_id
WHERE r.non_user_id IS NOT NULL -- 비회원 예매만
  AND r.status = 1              -- 필요하면: 정상 예매만
  AND ss.is_delete = 0          -- 삭제된 상영 일정 제외
GROUP BY r.non_user_id;

EXPLAIN
SELECT r2.non_user_id
FROM reservation r2
         JOIN screen_schedule ss
              ON ss.schedule_id = r2.schedule_id
WHERE r2.non_user_id IS NOT NULL
  AND r2.status = 1
GROUP BY r2.non_user_id
HAVING MAX(TIMESTAMP(ss.running_date, ss.end_time)) < NOW() - INTERVAL 7 DAY;

show CREATE TABLE reservation;

-- 프로파일링 상태 확인
SELECT @@profiling;
-- 프로파일링 활성화
SET profiling = 1;
-- 프로파일링 비활성화
SET profiling = 0;
-- 프로파일링 히스토리 리셋 후 저장 공간확보
SET @@profiling_history_size = 0;
SET @@profiling_history_size = 10;
-- 프로파일링 내용 확인
SHOW PROFILES;

EXPLAIN
SELECT
    n.non_user_id,
    n.name,
    n.phone,
    n.created_at
FROM non_user n
WHERE
    -- 1) non_user가 생성된 지 7일이 넘었고
    n.created_at < NOW() - INTERVAL 7 DAY
    -- 2) 최근 7일 이내에 끝나는 예매가 한 건도 없다
    AND NOT EXISTS (
        SELECT 1
        FROM reservation r
        JOIN screen_schedule ss
              ON ss.schedule_id = r.schedule_id
        WHERE r.non_user_id = n.non_user_id
          AND r.status = 1          -- 정상 예매만 (필요하면 조건 조정)
          AND ss.is_delete = 0
          AND TIMESTAMP(ss.running_date, ss.end_time) >= NOW() - INTERVAL 7 DAY
    );

EXPLAIN
SELECT
    n.non_user_id,
    n.name,
    n.phone,
    n.created_at,
    n.expire_at
FROM non_user n
WHERE n.created_at < NOW() - INTERVAL 7 DAY
  AND n.expire_at   < NOW() - INTERVAL 7 DAY;

ALTER TABLE non_user
ADD INDEX idx_non_user_expire_created (expire_at, created_at);
