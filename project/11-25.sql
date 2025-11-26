SELECT u.user_id,
       u.is_delete,
       u.membership_id        AS current_membership_id,
       cur_mt.membership_code AS current_membership_code,
       p.total_earn_point,
       new_mt.membership_id   AS new_membership_id,
       new_mt.membership_code AS new_membership_code
FROM user u
         LEFT JOIN (SELECT pl.user_id,
                           SUM(CASE WHEN pl.change_amount > 0 THEN pl.change_amount ELSE 0 END)
                               AS total_earn_point
                    FROM point_log pl
                    WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
                      AND pl.created_at < CURRENT_DATE
                    GROUP BY pl.user_id) p ON u.user_id = p.user_id
         LEFT JOIN membership_tier cur_mt
                   ON cur_mt.membership_id = u.membership_id
         LEFT JOIN membership_tier new_mt
                   ON new_mt.membership_id = (SELECT mt.membership_id
                                              FROM membership_tier mt
                                              WHERE mt.promote_min_point <= IFNULL(p.total_earn_point, 0)
                                              ORDER BY mt.promote_min_point DESC
                                              LIMIT 1)
WHERE u.is_delete = 0 -- 탈퇴회원 제외
ORDER BY u.user_id;



INSERT INTO reservation_count (reservation_id, age_type, count, price)

SELECT r.reservation_id,

       -- 연령대 코드
       CASE
           WHEN r.price IN (11000, 22000) THEN '00202' -- 청소년
           WHEN r.price IN (14000, 28000) THEN '00201' -- 성인
           WHEN r.price = 7000 THEN '00203' -- 경로/우대
           END AS age_type,

       -- 인원 수
       CASE
           WHEN r.price IN (11000, 14000, 7000) THEN 1 -- 1명 금액
           WHEN r.price IN (22000, 28000) THEN 2 -- 2명 금액
           ELSE 1
           END AS count,

       -- 1인당 가격(단가)
       CASE
           WHEN r.price IN (11000, 22000) THEN 11000
           WHEN r.price IN (14000, 28000) THEN 14000
           WHEN r.price = 7000 THEN 7000
           ELSE r.price
           END AS price
FROM reservation r
-- 취소건
WHERE r.status <> 2;

