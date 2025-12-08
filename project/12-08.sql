SELECT u.user_id,
       u.membership_id                          AS old_membership_id,
       p.total_point,
       p.new_membership_id                      AS calc_new_membership_id,
       mt_old.sort_order                        AS old_sort_order,
       mt_new.sort_order                        AS new_sort_order,
       u.grade_updated_at,
       (u.grade_updated_at + INTERVAL 12 MONTH) AS protect_until,
       CASE
           WHEN u.grade_updated_at + INTERVAL 12 MONTH > NOW()
               AND mt_new.sort_order < mt_old.sort_order
               THEN u.membership_id
           ELSE p.new_membership_id
           END                                  AS final_membership_id_after_rule
FROM user u
         JOIN (SELECT base.user_id,
                      base.total_point,
                      (SELECT mt.membership_id
                       FROM membership_tier mt
                       WHERE mt.promote_min_point <= base.total_point
                       ORDER BY mt.promote_min_point DESC
                       LIMIT 1) AS new_membership_id
               FROM (SELECT pl.user_id,
                            SUM(pl.change_amount) AS total_point
                     FROM point_log pl
                     WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
                       AND pl.created_at < CURRENT_DATE
                       AND pl.status = 0
                       AND pl.change_amount > 0
                     GROUP BY pl.user_id) base) p
              ON u.user_id = p.user_id
         JOIN membership_tier mt_old
              ON mt_old.membership_id = u.membership_id
         JOIN membership_tier mt_new
              ON mt_new.membership_id = p.new_membership_id
WHERE u.is_delete = 0
  AND u.membership_id <> p.new_membership_id
  AND NOT (
    u.grade_updated_at + INTERVAL 12 MONTH > NOW()
        AND mt_new.sort_order < mt_old.sort_order
    );

START TRANSACTION;

-- ↓↓↓ 이벤트 안의 UPDATE 문 그대로 실행
UPDATE user u
    JOIN (SELECT base.user_id,
                 base.total_point,
                 (SELECT mt.membership_id
                  FROM membership_tier mt
                  WHERE mt.promote_min_point <= base.total_point
                  ORDER BY mt.promote_min_point DESC
                  LIMIT 1) AS new_membership_id
          FROM (SELECT pl.user_id,
                       SUM(pl.change_amount) AS total_point
                FROM point_log pl
                WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
                  AND pl.created_at < CURRENT_DATE
                  AND pl.status = 0
                  AND pl.change_amount > 0
                GROUP BY pl.user_id) base) p
    ON u.user_id = p.user_id
    JOIN membership_tier mt_old
    ON mt_old.membership_id = u.membership_id
    JOIN membership_tier mt_new
    ON mt_new.membership_id = p.new_membership_id
SET u.membership_id = CASE
                          WHEN u.grade_updated_at + INTERVAL 12 MONTH > NOW()
                              AND mt_new.sort_order < mt_old.sort_order
                              THEN u.membership_id
                          ELSE p.new_membership_id
    END
WHERE u.is_delete = 0
  AND u.membership_id <> p.new_membership_id
  AND NOT (
    u.grade_updated_at + INTERVAL 12 MONTH > NOW()
        AND mt_new.sort_order < mt_old.sort_order
    );

-- 테스트만 해보는 거면
ROLLBACK;
-- 실제 반영할 거면 COMMIT;

SELECT COUNT(1) AS test_membership_change
FROM membership_log
WHERE DATE(created_at) = '2025-12-08';

SELECT u.user_id,
       c.coupon_id,
       NOW()                                         AS issue_date,
       TIMESTAMP(LAST_DAY(CURRENT_DATE), '23:59:59') AS expired_date,
       0                                             AS status
FROM user u
         INNER JOIN coupon c
                    ON c.membership_id = u.membership_id
WHERE u.is_delete = 0
  AND u.membership_id <> 1
  AND c.membership_id IS NOT NULL
  AND c.is_active = 1
  AND NOT EXISTS (SELECT 1
                  FROM coupon_detail cd
                  WHERE cd.user_id = u.user_id
                    AND cd.coupon_id = c.coupon_id
                    AND cd.issue_date >= DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
                    AND cd.issue_date < DATE_FORMAT(CURRENT_DATE + INTERVAL 1 MONTH, '%Y-%m-01'));


START TRANSACTION;

INSERT INTO coupon_detail (user_id, coupon_id, issue_date, expired_date, status)
SELECT u.user_id,
       c.coupon_id,
       NOW()                                         AS issue_date,
       TIMESTAMP(LAST_DAY(CURRENT_DATE), '23:59:59') AS expired_date,
       0                                             AS status
FROM user u
         INNER JOIN coupon c
                    ON c.membership_id = u.membership_id
WHERE u.is_delete = 0
  AND u.membership_id <> 1
  AND c.membership_id IS NOT NULL
  AND c.is_active = 1
  AND NOT EXISTS (SELECT 1
                  FROM coupon_detail cd
                  WHERE cd.user_id = u.user_id
                    AND cd.coupon_id = c.coupon_id
                    AND cd.issue_date >= DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
                    AND cd.issue_date < DATE_FORMAT(CURRENT_DATE + INTERVAL 1 MONTH, '%Y-%m-01'));

-- 여기서 영향받은 row 수 확인 (쿠폰 몇 개 발급되었는지)
-- 그 다음 눈으로도 일부 SELECT 해보고,

SELECT COUNT(1) AS test_membership_coupon
FROM coupon_detail
WHERE DATE(issue_date) = '2025-12-08';

ROLLBACK;
-- 테스트만 할 거면
-- 실제로 넣고 싶으면 COMMIT;