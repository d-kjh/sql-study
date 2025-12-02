SELECT *
FROM user
WHERE grade_updated_at = DATE('2025-12-02');

SELECT u.user_id,
       u.membership_id     AS old_membership_id,
       p.new_membership_id AS calculated_new_membership_id,
       u.grade_updated_at,
       mt_old.sort_order   AS old_sort,
       mt_new.sort_order   AS new_sort,
       p.total_point
FROM user u

-- 지난 1년치 포인트 합산 + 새 등급 계산
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
                     GROUP BY pl.user_id) base) p ON u.user_id = p.user_id

-- 기존 등급 정보
         JOIN membership_tier mt_old ON mt_old.membership_id = u.membership_id

-- 새 등급 정보
         JOIN membership_tier mt_new ON mt_new.membership_id = p.new_membership_id

WHERE u.is_delete = 0
  AND u.membership_id <> p.new_membership_id -- 실제 등급이 바뀌는 경우만
  AND NOT (
    -- 보호기간 + 강등 조합일 경우는 UPDATE가 실행되지 않으므로 제외
    u.grade_updated_at + INTERVAL 12 MONTH > NOW()
        AND mt_new.sort_order < mt_old.sort_order
    );

SELECT *
FROM point_log
WHERE status = 0;

SELECT u.user_id, u.membership_id, c.coupon_name
FROM user u
         INNER JOIN coupon c
                    ON c.membership_id = u.membership_id
WHERE u.is_delete = 0
  AND u.membership_id <> 1
  AND c.membership_id IS NOT NULL;

SELECT * FROM coupon_detail
WHERE status = 0
AND issue_date > '2025-12-02';
