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

UPDATE ticket_discount td
JOIN reservation_seat rs
  ON rs.reservation_seat_id = td.reservation_seat_id
JOIN reservation_seat_list rsl
  ON rsl.reservation_seat_id = rs.reservation_seat_id
JOIN reservation r
  ON r.reservation_id = rsl.reservation_id
JOIN (
    SELECT
        rc.reservation_id,
        FLOOR(MAX(rc.price / NULLIF(rc.count, 0))) AS seat_price
    FROM reservation_count rc
    GROUP BY rc.reservation_id
) sp
  ON sp.reservation_id = r.reservation_id
SET td.applied_amount = sp.seat_price
WHERE td.benefit_code = '01101';


UPDATE ticket_discount td
JOIN reservation_seat rs
  ON rs.reservation_seat_id = td.reservation_seat_id
JOIN reservation_seat_list rsl
  ON rsl.reservation_seat_id = rs.reservation_seat_id
JOIN reservation r
  ON r.reservation_id = rsl.reservation_id
JOIN (
    SELECT
        rc.reservation_id,
        FLOOR(MAX(rc.price / NULLIF(rc.count, 0))) AS seat_price
    FROM reservation_count rc
    GROUP BY rc.reservation_id
) sp
  ON sp.reservation_id = r.reservation_id
SET td.applied_amount = sp.seat_price
WHERE td.benefit_code = '01103';


UPDATE ticket_discount td
JOIN reservation_seat rs
  ON rs.reservation_seat_id = td.reservation_seat_id
JOIN reservation_seat_list rsl
  ON rsl.reservation_seat_id = rs.reservation_seat_id
JOIN reservation r
  ON r.reservation_id = rsl.reservation_id
JOIN (
    SELECT
        rc.reservation_id,
        FLOOR(MAX(rc.price / NULLIF(rc.count, 0))) AS seat_price
    FROM reservation_count rc
    GROUP BY rc.reservation_id
) sp
  ON sp.reservation_id = r.reservation_id
JOIN coupon_detail cd
  ON cd.user_coupon_id = td.benefit_id
JOIN coupon c
  ON c.coupon_id = cd.coupon_id
SET td.applied_amount =
    CASE
        WHEN c.discount_type = 0 THEN      -- 정액
            LEAST(c.discount_value, sp.seat_price)
        WHEN c.discount_type = 1 THEN      -- 정률
            ROUND(sp.seat_price * (c.discount_value / 100), 0)
        ELSE 0
    END
WHERE td.benefit_code = '01102';


SELECT count(1)
FROM ticket_discount;






