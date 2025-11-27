SELECT COUNT(1)
FROM reservation_count
WHERE COUNT = 2;

SELECT COUNT(1)
FROM reservation_count;

SELECT COUNT(1)
FROM reservation;

SELECT schedule_id, COUNT(1)
FROM reservation
GROUP BY schedule_id;

SELECT o.user_id, COUNT(1)
FROM `order` o
         INNER JOIN store_item si
                    ON o.store_item_id = si.store_item_id
WHERE si.store_item_code = '00404'
GROUP BY o.user_id;

# 발급상태인것만
INSERT INTO user_voucher
    (user_id, store_item_id, issue_date, expire_date, status)
SELECT o.user_id,
       o.store_item_id,
       DATE(o.created_at)                                     AS issue_date,
       DATE_ADD(DATE(o.created_at), INTERVAL s.valid_day DAY) AS expire_date,
       o.status                                               AS status
FROM `order` o
         JOIN store_item s ON s.store_item_id = o.store_item_id
WHERE s.store_item_code NOT IN ('00403'); -- 코드번호

INSERT INTO user_voucher
    (user_id, store_item_id, issue_date, expire_date, status)
SELECT o.user_id,
       o.store_item_id,
       DATE(o.created_at) AS issue_date,

       -- 만료일 계산 (valid_day 우선, 없으면 end_date)
       CASE
           WHEN s.valid_day IS NOT NULL THEN
               DATE_ADD(DATE(o.created_at), INTERVAL s.valid_day DAY)
           WHEN s.valid_day IS NULL AND s.end_date IS NOT NULL THEN
               s.end_date
           ELSE
               NULL -- 둘 다 없으면 NULL (필요하면 나중에 UPDATE)
           END            AS expire_date,

       -- 상태값 계산 (주문취소 / 이미 만료 / 정상 발급)
       CASE
           WHEN o.status = 3 THEN 3 -- 주문 취소
           WHEN
               (
                   CASE
                       WHEN s.valid_day IS NOT NULL THEN
                           DATE_ADD(DATE(o.created_at), INTERVAL s.valid_day DAY)
                       WHEN s.valid_day IS NULL AND s.end_date IS NOT NULL THEN
                           s.end_date
                       ELSE
                           NULL
                       END
                   ) < CURDATE() THEN 2 -- 이미 만료일 지난 애들
           ELSE 0 -- 나머지: 발급 상태
           END            AS status
FROM `order` o
         JOIN store_item s ON s.store_item_id = o.store_item_id
WHERE s.store_item_code <> '00403'; -- 00403(할인쿠폰)만 제외하고 전부 교환권


INSERT INTO user_voucher
    (user_id, store_item_id, issue_date, expire_date, status)
SELECT o.user_id,
       o.store_item_id,
       DATE(o.created_at) AS issue_date,
       CASE
           WHEN s.valid_day IS NOT NULL THEN DATE_ADD(DATE(o.created_at), INTERVAL s.valid_day DAY)
           WHEN s.valid_day IS NULL AND s.end_date IS NOT NULL THEN s.end_date
           END            AS expire_date,
       0                  AS status -- 무조건 발급 상태로
FROM `order` o
         JOIN store_item s ON s.store_item_id = o.store_item_id
WHERE s.store_item_code <> '00403';

UPDATE user_voucher uv
    JOIN `order` o
    ON o.user_id = uv.user_id
        AND o.store_item_id = uv.store_item_id
        AND DATE(o.created_at) = uv.issue_date
SET uv.status = 3
WHERE o.status = 1 -- 주문취소
  AND uv.status = 0; -- 아직 발급 상태인 것만

SELECT COUNT(1)
FROM `order`
WHERE status = 1;

ALTER TABLE `reservation`
    AUTO_INCREMENT = 1;

ALTER TABLE `voucher_log`
    AUTO_INCREMENT = 1;

SELECT *
FROM `order` o
         INNER JOIN store_item si
                    ON si.store_item_id = o.store_item_id
WHERE o.status = 1
  AND si.store_item_code = '00403';

SELECT COUNT(1)
FROM coupon_detail
WHERE status = 1;

SELECT COUNT(1)
FROM coupon_log
WHERE status = 1;

INSERT INTO coupon_detail
    (user_id, coupon_id, issue_date, use_at, expired_date, status)
SELECT o.user_id,
       s.coupon_id,
       o.created_at                                           AS issue_date,
       NULL                                                   AS use_at,
       DATE_ADD(DATE(o.created_at), INTERVAL s.valid_day DAY) AS expired_date,
       0                                                      AS status
FROM `order` o
         JOIN store_item s ON s.store_item_id = o.store_item_id
         LEFT JOIN coupon_detail cd
                   ON cd.user_id = o.user_id
                       AND cd.coupon_id = s.coupon_id
                       AND DATE(cd.issue_date) = DATE(o.created_at)
WHERE s.store_item_code = '00403'
  AND cd.user_coupon_id IS NULL;

UPDATE coupon_log cl
    JOIN coupon_detail cd
    ON cd.user_coupon_id = cl.user_coupon_id
SET cl.created_at = cd.issue_date
WHERE cl.status = 0;

UPDATE user_voucher uv
    JOIN (SELECT uv2.user_voucher_id
          FROM user_voucher uv2
                   JOIN store_item si2
                        ON si2.store_item_id = uv2.store_item_id
          WHERE si2.store_item_code NOT IN ('00403')
          ORDER BY RAND()
          LIMIT 4823) t ON t.user_voucher_id = uv.user_voucher_id
SET uv.status = 1;


SELECT COUNT(1)
FROM user_voucher uv
         JOIN store_item si
              ON si.store_item_id = uv.store_item_id
WHERE uv.status = 1
  AND si.store_item_code IN ('00403');

DELETE
FROM common_code
WHERE code_id = '00204';

UPDATE common_code
SET name = '경로/우대'
WHERE code_id = '00203'

