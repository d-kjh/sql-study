-- CTE 사용 더미 insert 문

WITH seat_price AS (SELECT r2.reservation_id,
                           ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
                    FROM reservation r2
                             JOIN reservation_count rc2
                                  ON rc2.reservation_id = r2.reservation_id
                    GROUP BY r2.reservation_id),
     point_candidates AS (SELECT r.user_id,
                                 rs.reservation_seat_id,
                                 sp.seat_price,
                                 ROW_NUMBER() OVER (PARTITION BY r.user_id ORDER BY RAND()) AS rn
                          FROM reservation r
                                   JOIN seat_price sp
                                        ON sp.reservation_id = r.reservation_id
                                   JOIN reservation_seat_list rsl
                                        ON rsl.reservation_id = r.reservation_id
                                   JOIN reservation_seat rs
                                        ON rs.reservation_seat_id = rsl.reservation_seat_id
                                   JOIN user u
                                        ON u.user_id = r.user_id
                                   LEFT JOIN ticket_discount td
                                             ON td.reservation_seat_id = rs.reservation_seat_id
                          WHERE td.reservation_seat_id IS NULL -- 이미 할인 들어간 좌석 제외
                            AND u.point >= sp.seat_price -- 이 좌석 1장 가격은 낼 수 있는 유저만
     )
INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
SELECT pc.reservation_seat_id,
       'POINT'       AS benefit_code,
       pc.user_id    AS benefit_id,
       pc.seat_price AS applied_amount
FROM point_candidates pc
WHERE pc.rn = 1 -- 유저당 랜덤 1좌석만
LIMIT 100; -- 전체 몇 건 넣을지 조절


WITH seat_price AS (SELECT r2.reservation_id,
                           ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
                    FROM reservation r2
                             JOIN reservation_count rc2
                                  ON rc2.reservation_id = r2.reservation_id
                    GROUP BY r2.reservation_id),
     coupon_candidates AS (SELECT cd.user_coupon_id,
                                  rs.reservation_seat_id,
                                  sp.seat_price,
                                  c.discount_type,
                                  c.discount_value,
                                  c.max_discount_amount,
                                  ROW_NUMBER() OVER (PARTITION BY cd.user_coupon_id ORDER BY RAND()) AS rn
                           FROM coupon_detail cd
                                    JOIN coupon c
                                         ON c.coupon_id = cd.coupon_id
                                    JOIN reservation r
                                         ON r.user_id = cd.user_id
                                    JOIN seat_price sp
                                         ON sp.reservation_id = r.reservation_id
                                    JOIN reservation_seat_list rsl
                                         ON rsl.reservation_id = r.reservation_id
                                    JOIN reservation_seat rs
                                         ON rs.reservation_seat_id = rsl.reservation_seat_id
                                    LEFT JOIN ticket_discount td_seat
                                              ON td_seat.reservation_seat_id = rs.reservation_seat_id
                                    LEFT JOIN ticket_discount td_coupon
                                              ON td_coupon.benefit_code = 'COUPON'
                                                  AND td_coupon.benefit_id = cd.user_coupon_id
                           WHERE cd.status = 0                       -- 미사용 쿠폰
                             AND c.is_active = 0                     -- 사용 가능한 쿠폰
                             AND td_seat.reservation_seat_id IS NULL -- 이미 할인 있는 좌석 X
                             AND td_coupon.benefit_id IS NULL -- 이미 다른 좌석에 쓴 쿠폰 X
     )
INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
SELECT cc.reservation_seat_id,
       'COUPON'          AS benefit_code,
       cc.user_coupon_id AS benefit_id,
       CASE
           WHEN cc.discount_type = 0 THEN -- 정액
               LEAST(cc.discount_value, cc.seat_price)
           WHEN cc.discount_type = 1 THEN -- 정률
               ROUND(
                       LEAST(
                               cc.seat_price * (cc.discount_value / 100),
                               IFNULL(cc.max_discount_amount, cc.seat_price)
                       ), 2
               )
           ELSE 0.00
           END           AS applied_amount
FROM coupon_candidates cc
WHERE cc.rn = 1 -- 쿠폰 1장당 랜덤 1좌석에만 사용
LIMIT 100;



WITH seat_price AS (SELECT r2.reservation_id,
                           ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
                    FROM reservation r2
                             JOIN reservation_count rc2
                                  ON rc2.reservation_id = r2.reservation_id
                    GROUP BY r2.reservation_id),
     voucher_candidates AS (SELECT uv.user_voucher_id,
                                   rs.reservation_seat_id,
                                   sp.seat_price,
                                   ROW_NUMBER() OVER (PARTITION BY uv.user_voucher_id ORDER BY RAND()) AS rn
                            FROM user_voucher uv
                                     JOIN store_item si
                                          ON si.store_item_id = uv.store_item_id
                                     JOIN reservation r
                                          ON r.user_id = uv.user_id
                                     JOIN seat_price sp
                                          ON sp.reservation_id = r.reservation_id
                                     JOIN reservation_seat_list rsl
                                          ON rsl.reservation_id = r.reservation_id
                                     JOIN reservation_seat rs
                                          ON rs.reservation_seat_id = rsl.reservation_seat_id
                                     LEFT JOIN ticket_discount td_seat
                                               ON td_seat.reservation_seat_id = rs.reservation_seat_id
                                     LEFT JOIN ticket_discount td_voucher
                                               ON td_voucher.benefit_code = 'VOUCHER'
                                                   AND td_voucher.benefit_id = uv.user_voucher_id
                            WHERE si.store_item_code = '00401' -- 이 코드만 영화 교환권
                              AND uv.status = 0                -- 미사용 교환권
                              AND td_seat.reservation_seat_id IS NULL
                              AND td_voucher.benefit_id IS NULL)
INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
SELECT vc.reservation_seat_id,
       'VOUCHER'          AS benefit_code,
       vc.user_voucher_id AS benefit_id,
       vc.seat_price      AS applied_amount
FROM voucher_candidates vc
WHERE vc.rn = 1 -- 교환권 1장당 랜덤 1좌석만
LIMIT 100;


-- CTE 미사용 insert 문

INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
SELECT rs.reservation_seat_id,
       '01101',
       r.user_id,
       ROUND(r.price / NULLIF(sp.total_count, 0), 2)
FROM reservation_seat rs
         JOIN reservation_seat_list rsl ON rsl.reservation_seat_id = rs.reservation_seat_id
         JOIN reservation r ON r.reservation_id = rsl.reservation_id
         JOIN (SELECT reservation_id, SUM(count) AS total_count
               FROM reservation_count
               GROUP BY reservation_id) sp ON sp.reservation_id = r.reservation_id
         JOIN user u ON u.user_id = r.user_id
         LEFT JOIN ticket_discount td ON td.reservation_seat_id = rs.reservation_seat_id
WHERE td.reservation_seat_id IS NULL
  AND u.point >= ROUND(r.price / NULLIF(sp.total_count, 0), 2)
ORDER BY RAND()
LIMIT 30;


INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
SELECT rs.reservation_seat_id,          -- 할인 들어간 좌석
       'COUPON'          AS benefit_code,
       cd.user_coupon_id AS benefit_id, -- 어떤 user_coupon인지
       CASE
           WHEN c.discount_type = 0 THEN
               LEAST(c.discount_value, sp.seat_price) -- 정액: 티켓가격보다 많이 깎지 않기

           WHEN c.discount_type = 1 THEN
               -- 정률(%): seat_price * (discount_value / 100), 상한 있으면 상한까지
               ROUND(
                       LEAST(
                               sp.seat_price * (c.discount_value / 100),
                               IFNULL(c.max_discount_amount, sp.seat_price)
                       ),
                       2)

           ELSE 0.00
           END           AS applied_amount
FROM reservation_seat rs
         JOIN reservation_seat_list rsl
              ON rsl.reservation_seat_id = rs.reservation_seat_id
         JOIN reservation r
              ON r.reservation_id = rsl.reservation_id
         JOIN (SELECT r2.reservation_id,
                      SUM(rc2.count)                                 AS total_count,
                      ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
               FROM reservation r2
                        JOIN reservation_count rc2
                             ON rc2.reservation_id = r2.reservation_id
               GROUP BY r2.reservation_id) sp
              ON sp.reservation_id = r.reservation_id
         JOIN coupon_detail cd
              ON cd.user_id = r.user_id
         JOIN coupon c
              ON c.coupon_id = cd.coupon_id
         LEFT JOIN ticket_discount td_seat
                   ON td_seat.reservation_seat_id = rs.reservation_seat_id
         LEFT JOIN ticket_discount td_coupon
                   ON td_coupon.benefit_code = 'COUPON'
                       AND td_coupon.benefit_id = cd.user_coupon_id
WHERE cd.status = 0                       -- 발급(미사용) 쿠폰만
  AND c.is_active = 0                     -- 사용 가능한 쿠폰만 (네 플래그에 맞게 조정)
  AND td_seat.reservation_seat_id IS NULL -- 이미 할인 있는 좌석은 제외
  AND td_coupon.benefit_id IS NULL        -- 이미 다른 좌석에 쓴 쿠폰은 제외 (쿠폰 1장당 1좌석)
ORDER BY RAND()
LIMIT 30; -- 랜덤 30좌석에 쿠폰 할인 생성


INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
SELECT rs.reservation_seat_id,              -- 할인 좌석
       'VOUCHER'          AS benefit_code,
       uv.user_voucher_id AS benefit_id,    -- 어떤 교환권인지
       sp.seat_price      AS applied_amount -- 티켓 1장 전체 금액
FROM reservation_seat rs
         JOIN reservation_seat_list rsl
              ON rsl.reservation_seat_id = rs.reservation_seat_id
         JOIN reservation r
              ON r.reservation_id = rsl.reservation_id
         JOIN (SELECT r2.reservation_id,
                      SUM(rc2.count)                                 AS total_count,
                      ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
               FROM reservation r2
                        JOIN reservation_count rc2
                             ON rc2.reservation_id = r2.reservation_id
               GROUP BY r2.reservation_id) sp
              ON sp.reservation_id = r.reservation_id
         JOIN user_voucher uv
              ON uv.user_id = r.user_id
         JOIN store_item si
              ON si.store_item_id = uv.store_item_id
         LEFT JOIN ticket_discount td_seat
                   ON td_seat.reservation_seat_id = rs.reservation_seat_id
         LEFT JOIN ticket_discount td_voucher
                   ON td_voucher.benefit_code = 'VOUCHER'
                       AND td_voucher.benefit_id = uv.user_voucher_id
WHERE si.store_item_code = '00401'        -- 이 코드만 영화 교환권
  AND uv.status = 0                       -- 미사용 교환권만
  AND td_seat.reservation_seat_id IS NULL -- 이미 할인 있는 좌석 제외
  AND td_voucher.benefit_id IS NULL       -- 교환권 1장당 1좌석만
ORDER BY RAND()
LIMIT 30; -- 랜덤 30좌석에 교환권 할인 생성


INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
SELECT t.reservation_seat_id,
       t.benefit_code,
       t.benefit_id,
       t.applied_amount
FROM (( -- POINT 후보
          SELECT rs.reservation_seat_id,
                 r.user_id     AS benefit_id,
                 '01101'       AS benefit_code,
                 sp.seat_price AS applied_amount
          FROM reservation_seat rs
                   JOIN reservation_seat_list rsl ON rsl.reservation_seat_id = rs.reservation_seat_id
                   JOIN reservation r ON r.reservation_id = rsl.reservation_id
                   JOIN (SELECT r2.reservation_id,
                                SUM(rc2.count)                                 AS total_count,
                                ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
                         FROM reservation r2
                                  JOIN reservation_count rc2 ON rc2.reservation_id = r2.reservation_id
                         GROUP BY r2.reservation_id) sp ON sp.reservation_id = r.reservation_id
                   JOIN user u ON u.user_id = r.user_id
                   LEFT JOIN ticket_discount td ON td.reservation_seat_id = rs.reservation_seat_id
          WHERE u.point >= sp.seat_price
            AND td.reservation_seat_id IS NULL)

      UNION ALL

      ( -- COUPON 후보
          SELECT rs.reservation_seat_id,
                 cd.user_coupon_id AS benefit_id,
                 '01102'           AS benefit_code,
                 CASE
                     WHEN c.discount_type = 0
                         THEN LEAST(c.discount_value, sp.seat_price)
                     WHEN c.discount_type = 1
                         THEN ROUND(
                             LEAST(sp.seat_price * (c.discount_value / 100),
                                   IFNULL(c.max_discount_amount, sp.seat_price)), 2)
                     END           AS applied_amount
          FROM reservation_seat rs
                   JOIN reservation_seat_list rsl ON rsl.reservation_seat_id = rs.reservation_seat_id
                   JOIN reservation r ON r.reservation_id = rsl.reservation_id
                   JOIN (SELECT r2.reservation_id,
                                SUM(rc2.count)                                 AS total_count,
                                ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
                         FROM reservation r2
                                  JOIN reservation_count rc2 ON rc2.reservation_id = r2.reservation_id
                         GROUP BY r2.reservation_id) sp ON sp.reservation_id = r.reservation_id
                   JOIN coupon_detail cd ON cd.user_id = r.user_id
                   JOIN coupon c ON c.coupon_id = cd.coupon_id
                   LEFT JOIN ticket_discount td ON td.reservation_seat_id = rs.reservation_seat_id
                   LEFT JOIN ticket_discount td2 ON td2.benefit_id = cd.user_coupon_id AND td2.benefit_code = '01102'
          WHERE cd.status = 0
            AND c.is_active = 0
            AND td.reservation_seat_id IS NULL
            AND td2.benefit_id IS NULL)

      UNION ALL

      ( -- VOUCHER 후보
          SELECT rs.reservation_seat_id,
                 uv.user_voucher_id AS benefit_id,
                 '01103'            AS benefit_code,
                 sp.seat_price      AS applied_amount
          FROM reservation_seat rs
                   JOIN reservation_seat_list rsl ON rsl.reservation_seat_id = rs.reservation_seat_id
                   JOIN reservation r ON r.reservation_id = rsl.reservation_id
                   JOIN (SELECT r2.reservation_id,
                                SUM(rc2.count)                                 AS total_count,
                                ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
                         FROM reservation r2
                                  JOIN reservation_count rc2 ON rc2.reservation_id = r2.reservation_id
                         GROUP BY r2.reservation_id) sp ON sp.reservation_id = r.reservation_id
                   JOIN user_voucher uv ON uv.user_id = r.user_id
                   JOIN store_item si ON si.store_item_id = uv.store_item_id
                   LEFT JOIN ticket_discount td ON td.reservation_seat_id = rs.reservation_seat_id
                   LEFT JOIN ticket_discount td3 ON td3.benefit_id = uv.user_voucher_id AND td3.benefit_code = '01103'
          WHERE si.store_item_code = '00401'
            AND uv.status = 0
            AND td.reservation_seat_id IS NULL
            AND td3.benefit_id IS NULL)) t
ORDER BY RAND()
LIMIT 8529; -- 원하는 개수만큼 랜덤 적용


ALTER TABLE ticket_discount
    AUTO_INCREMENT = 1;


-- 혹시 기존에 있으면 먼저 삭제
DROP PROCEDURE IF EXISTS populate_ticket_discount_dummy;

DELIMITER $$

CREATE PROCEDURE populate_ticket_discount_dummy(
    IN p_point_limit INT, -- 포인트 할인 좌석 개수
    IN p_coupon_limit INT, -- 쿠폰   할인 좌석 개수
    IN p_voucher_limit INT -- 교환권 할인 좌석 개수
)
BEGIN
    /* seat_price 계산:
       예매별 티켓 한 장 가격 = reservation_count.price / reservation_count.count
       여러 연령대가 있으면 가장 비싼 1장 가격 사용 (MAX)
    */


    /* 1) 포인트(01101) 전액 할인: applied_amount = 티켓 1장 가격 */
    INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
    SELECT rs.reservation_seat_id,
           '01101'       AS benefit_code,
           r.user_id     AS benefit_id,
           sp.seat_price AS applied_amount -- 티켓 1장 가격 = 전액 포인트 할인
    FROM reservation_seat rs
             JOIN reservation_seat_list rsl
                  ON rsl.reservation_seat_id = rs.reservation_seat_id
             JOIN reservation r
                  ON r.reservation_id = rsl.reservation_id
             JOIN (SELECT rc2.reservation_id,
                          FLOOR(MAX(rc2.price / NULLIF(rc2.count, 0))) AS seat_price
                   FROM reservation_count rc2
                   GROUP BY rc2.reservation_id) sp
                  ON sp.reservation_id = r.reservation_id
             JOIN user u
                  ON u.user_id = r.user_id
             LEFT JOIN ticket_discount td
                       ON td.reservation_seat_id = rs.reservation_seat_id
    WHERE td.reservation_seat_id IS NULL                            -- 이미 할인 들어간 좌석 제외
      AND u.point >= sp.seat_price                                  -- 포인트가 1장 가격 이상 있어야
      AND sp.seat_price IN (7000, 9000, 10000, 12000, 13000, 14000) -- 깔끔한 단가만
    ORDER BY RAND()
    LIMIT p_point_limit;


    /* 2) 할인쿠폰(01102):
          - 정액(discount_type=0) : applied_amount = 쿠폰 할인금액(단, 1장 가격보다 클 수 없음)
          - 정률(discount_type=1) : applied_amount = seat_price * (할인율/100)
    */
    INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
    SELECT rs.reservation_seat_id,
           '01102'           AS benefit_code,
           cd.user_coupon_id AS benefit_id,
           CASE
               WHEN c.discount_type = 0 THEN -- 정액 쿠폰
                   FLOOR(LEAST(c.discount_value, sp.seat_price))
               WHEN c.discount_type = 1 THEN -- 정률 쿠폰 (%)
                   ROUND(sp.seat_price * (c.discount_value / 100), 0) -- 실제 할인된 금액(정수)
               ELSE 0
               END           AS applied_amount
    FROM reservation_seat rs
             JOIN reservation_seat_list rsl
                  ON rsl.reservation_seat_id = rs.reservation_seat_id
             JOIN reservation r
                  ON r.reservation_id = rsl.reservation_id
             JOIN (SELECT rc2.reservation_id,
                          FLOOR(MAX(rc2.price / NULLIF(rc2.count, 0))) AS seat_price
                   FROM reservation_count rc2
                   GROUP BY rc2.reservation_id) sp
                  ON sp.reservation_id = r.reservation_id
             JOIN coupon_detail cd
                  ON cd.user_id = r.user_id
             JOIN coupon c
                  ON c.coupon_id = cd.coupon_id
             LEFT JOIN ticket_discount td_seat
                       ON td_seat.reservation_seat_id = rs.reservation_seat_id
             LEFT JOIN ticket_discount td_coupon
                       ON td_coupon.benefit_code = '01102'
                           AND td_coupon.benefit_id = cd.user_coupon_id
    WHERE cd.status = 0                       -- 미사용 쿠폰
      AND c.is_active = 0                     -- 사용 가능 쿠폰
      AND td_seat.reservation_seat_id IS NULL -- 이미 할인 있는 좌석 X
      AND td_coupon.benefit_id IS NULL        -- 쿠폰 1장당 1좌석만
      AND sp.seat_price IN (7000, 9000, 10000, 12000, 13000, 14000)
    ORDER BY RAND()
    LIMIT p_coupon_limit;


    /* 3) 교환권(01103) 전액 할인: applied_amount = 티켓 1장 가격 */
    INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
    SELECT rs.reservation_seat_id,
           '01103'            AS benefit_code,
           uv.user_voucher_id AS benefit_id,
           sp.seat_price      AS applied_amount -- 티켓 1장 가격 전액을 교환권으로
    FROM reservation_seat rs
             JOIN reservation_seat_list rsl
                  ON rsl.reservation_seat_id = rs.reservation_seat_id
             JOIN reservation r
                  ON r.reservation_id = rsl.reservation_id
             JOIN (SELECT rc2.reservation_id,
                          FLOOR(MAX(rc2.price / NULLIF(rc2.count, 0))) AS seat_price
                   FROM reservation_count rc2
                   GROUP BY rc2.reservation_id) sp
                  ON sp.reservation_id = r.reservation_id
             JOIN user_voucher uv
                  ON uv.user_id = r.user_id
             JOIN store_item si
                  ON si.store_item_id = uv.store_item_id
             LEFT JOIN ticket_discount td_seat
                       ON td_seat.reservation_seat_id = rs.reservation_seat_id
             LEFT JOIN ticket_discount td_voucher
                       ON td_voucher.benefit_code = '01103'
                           AND td_voucher.benefit_id = uv.user_voucher_id
    WHERE si.store_item_code = '00401'        -- 영화 교환권 코드
      AND uv.status = 0                       -- 미사용 교환권
      AND td_seat.reservation_seat_id IS NULL -- 이미 할인 있는 좌석 X
      AND td_voucher.benefit_id IS NULL       -- 교환권 1장당 1번만 사용
      AND sp.seat_price IN (7000, 9000, 10000, 12000, 13000, 14000)
    ORDER BY RAND()
    LIMIT p_voucher_limit;

END$$

DELIMITER ;


CALL populate_ticket_discount_dummy(1526, 2346, 2137);
