UPDATE reservation
SET status = 2
WHERE status = 0;

SELECT COUNT(1)
FROM reservation
WHERE status = 0;

SELECT COUNT(1)
FROM reservation_count rc
         JOIN reservation r
              ON r.reservation_id = rc.reservation_id
         JOIN reservation_seat_list rsl
              ON rsl.reservation_id = rc.reservation_id
         JOIN reservation_seat rs
              ON rs.reservation_seat_id = rsl.reservation_seat_id
WHERE r.status = 2;

-- 예매별 1인당 티켓 가격 계산 서브쿼리
SELECT r2.reservation_id,
       ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
FROM reservation r2
         JOIN reservation_count rc2
              ON rc2.reservation_id = r2.reservation_id
GROUP BY r2.reservation_id;


INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
SELECT rs.reservation_seat_id,
       '01101'       AS benefit_code,
       r.user_id     AS benefit_id,    -- 포인트: user PK 기준
       rp.seat_price AS applied_amount -- 티켓 1장 가격 = 전액 할인
FROM reservation_seat rs
         JOIN reservation_seat_list rsl
              ON rsl.reservation_seat_id = rs.reservation_seat_id
         JOIN reservation r
              ON r.reservation_id = rsl.reservation_id
         JOIN (SELECT r2.reservation_id,
                      ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
               FROM reservation r2
                        JOIN reservation_count rc2
                             ON rc2.reservation_id = r2.reservation_id
               GROUP BY r2.reservation_id) rp
              ON rp.reservation_id = r.reservation_id
         LEFT JOIN ticket_discount td
                   ON td.reservation_seat_id = rs.reservation_seat_id
WHERE r.user_id IS NOT NULL          -- 회원 예매만
  AND td.reservation_seat_id IS NULL -- 아직 할인 안들어간 좌석만
LIMIT 50; -- 테스트용 개수 (원하면 수정)


INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
SELECT rs.reservation_seat_id,
       '01102'           AS benefit_code,
       cd.user_coupon_id AS benefit_id, -- 어떤 쿠폰인지
       CASE
           WHEN c.discount_type = 0 THEN -- 정액 쿠폰
           -- 티켓 가격보다 많이 깎지 않도록 최소값 사용
               LEAST(c.discount_value, rp.seat_price)

           WHEN c.discount_type = 1 THEN -- 정률 쿠폰 (%)
           -- seat_price * (할인율 / 100)
               ROUND(
                       LEAST(
                               rp.seat_price * (c.discount_value / 100),
                               IFNULL(c.max_discount_amount, rp.seat_price)
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
                      ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
               FROM reservation r2
                        JOIN reservation_count rc2
                             ON rc2.reservation_id = r2.reservation_id
               GROUP BY r2.reservation_id) rp
              ON rp.reservation_id = r.reservation_id
         JOIN coupon_detail cd
              ON cd.user_id = r.user_id
         JOIN coupon c
              ON c.coupon_id = cd.coupon_id
         LEFT JOIN ticket_discount td
                   ON td.reservation_seat_id = rs.reservation_seat_id
WHERE cd.status = 0                  -- 발급 상태 쿠폰만 사용했다고 가정
  AND td.reservation_seat_id IS NULL -- 아직 할인 없는 좌석만
LIMIT 50;


INSERT INTO ticket_discount (reservation_seat_id, benefit_code, benefit_id, applied_amount)
SELECT rs.reservation_seat_id,
       '01103'            AS benefit_code,
       uv.user_voucher_id AS benefit_id,    -- 어떤 교환권으로 깎았는지
       rp.seat_price      AS applied_amount -- 티켓 1장 가격 = 전액 할인
FROM reservation_seat rs
         JOIN reservation_seat_list rsl
              ON rsl.reservation_seat_id = rs.reservation_seat_id
         JOIN reservation r
              ON r.reservation_id = rsl.reservation_id
         JOIN (SELECT r2.reservation_id,
                      ROUND(r2.price / NULLIF(SUM(rc2.count), 0), 2) AS seat_price
               FROM reservation r2
                        JOIN reservation_count rc2
                             ON rc2.reservation_id = r2.reservation_id
               GROUP BY r2.reservation_id) rp
              ON rp.reservation_id = r.reservation_id
         JOIN user_voucher uv
              ON uv.user_id = r.user_id
         JOIN store_item si
              ON si.store_item_id = uv.store_item_id
         LEFT JOIN ticket_discount td
                   ON td.reservation_seat_id = rs.reservation_seat_id
WHERE si.store_item_code = '00401'   -- 영화 교환권 코드
  AND uv.status = 0                  -- 발급 상태 교환권만 사용했다고 가정
  AND td.reservation_seat_id IS NULL -- 아직 할인 없는 좌석만
LIMIT 30;



UPDATE reservation_count rc
    JOIN reservation r
    ON r.reservation_id = rc.reservation_id
    JOIN db_odd_adv_1.screen_schedule sch
    ON sch.schedule_id = r.schedule_id -- 예매 → 상영일정
    JOIN screen_type st
    ON st.screen_type = sch.screen_type -- 상영관 타입(2D/4D/리클/돌비)
    JOIN screen_time stime
    ON stime.screen_time = sch.screen_time -- 상영 시간(조조/일반/심야)
    JOIN age_type at
    ON at.age_type = rc.age_type -- 관람 연령(성인/청소년/경로,우대)
SET rc.price = GREATEST(
        (st.price -- 기본 상영관 가격
            - at.adjust_price -- 연령 할인
            - stime.adjust_price -- 시간대 할인
            ) * rc.count, -- 인원 수만큼 곱하기
        0
               );

UPDATE reservation r
    JOIN (SELECT reservation_id,
                 SUM(price) AS total_price
          FROM reservation_count
          GROUP BY reservation_id) x
    ON x.reservation_id = r.reservation_id
SET r.price = x.total_price;

SELECT r.reservation_id,
       sch.screen_type,
       sch.screen_time,
       rc.age_type,
       st.price                                          AS base_price,
       at.adjust_price                                   AS age_discount,
       stime.adjust_price                                AS time_discount,
       (st.price - at.adjust_price - stime.adjust_price) AS seat_price,
       rc.count,
       rc.price
FROM reservation r
         JOIN screen_schedule sch ON sch.schedule_id = r.schedule_id
         JOIN reservation_count rc ON rc.reservation_id = r.reservation_id
         JOIN screen_type st ON st.screen_type = sch.screen_type
         JOIN age_type at ON at.age_type = rc.age_type
         JOIN screen_time stime ON stime.screen_time = sch.screen_time
WHERE rc.age_type <> 0; -- 테스트할 예매ID

