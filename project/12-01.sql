SELECT
    u.user_id,
    u.membership_id AS old_membership_id,
    p.total_point,
    p.new_membership_id,
    mt_old.sort_order AS old_sort,
    mt_new.sort_order AS new_sort,
    CASE
        -- 12개월 보호기간 안 + 새 등급이 더 낮을 때 → 강등 금지, 기존 등급 유지
        WHEN u.grade_updated_at + INTERVAL 12 MONTH > NOW()
             AND mt_new.sort_order < mt_old.sort_order
            THEN u.membership_id

        -- 그 외(승급 / 같은 등급 / 보호기간 끝난 후 강등) → 새 등급 적용
        ELSE p.new_membership_id
    END AS final_membership_id
FROM user u
    -- 지난 1년간 포인트 합산 + 새 등급 계산
    JOIN (
        -- 포인트 로그가 있는 사람들 id와 최고 맴버십 티어
        SELECT
            base.user_id,
            base.total_point,
            (
                SELECT mt.membership_id
                FROM membership_tier mt
                WHERE mt.promote_min_point <= base.total_point
                ORDER BY mt.promote_min_point DESC
                LIMIT 1
            ) AS new_membership_id
        FROM (
            -- 지난 1년간 적립 포인트만 합산
            SELECT
                pl.user_id,
                SUM(
                    CASE
                        WHEN pl.change_amount > 0 THEN pl.change_amount
                        ELSE 0
                    END
                ) AS total_point
            FROM point_log pl
            WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
              AND pl.created_at < CURRENT_DATE
            GROUP BY pl.user_id
        ) base
    ) p ON u.user_id = p.user_id

    -- 기존 등급 정보
    JOIN membership_tier mt_old
        ON mt_old.membership_id = u.membership_id

    -- 새 등급 정보
    JOIN membership_tier mt_new
        ON mt_new.membership_id = p.new_membership_id

WHERE u.is_delete = 0
  AND u.membership_id <> p.new_membership_id;   -- 실제로 등급이 바뀌는 회원만 출력


-- 강등되는 유저들
SELECT
    u.user_id,
    u.membership_id AS old_membership_id,
    p.total_point,
    p.new_membership_id,
    mt_old.sort_order AS old_sort,
    mt_new.sort_order AS new_sort,
    'DOWNGRADE' AS status
FROM user u
JOIN (
    SELECT
        base.user_id,
        base.total_point,
        (
            SELECT mt.membership_id
            FROM membership_tier mt
            WHERE mt.promote_min_point <= base.total_point
            ORDER BY mt.promote_min_point DESC
            LIMIT 1
        ) AS new_membership_id
    FROM (
        SELECT
            pl.user_id,
            SUM(
                CASE WHEN pl.change_amount > 0 THEN pl.change_amount ELSE 0 END
            ) AS total_point
        FROM point_log pl
        WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
          AND pl.created_at < CURRENT_DATE
        GROUP BY pl.user_id
    ) base
) p ON u.user_id = p.user_id
JOIN membership_tier mt_old ON mt_old.membership_id = u.membership_id
JOIN membership_tier mt_new ON mt_new.membership_id = p.new_membership_id
WHERE u.is_delete = 0
  -- 보호기간 끝났음
  AND u.grade_updated_at + INTERVAL 12 MONTH <= NOW()
  -- 새 등급이 기존 등급보다 낮음 (정확한 강등 조건)
  AND mt_new.sort_order < mt_old.sort_order;


-- 강등이 되어야하지만 보호기간때문에 막힌 유저들
SELECT
    u.user_id,
    u.membership_id AS old_membership_id,
    p.total_point,
    p.new_membership_id,
    mt_old.sort_order AS old_sort,
    mt_new.sort_order AS new_sort,
    'PROTECTED' AS status
FROM user u
JOIN (
    SELECT
        base.user_id,
        base.total_point,
        (
            SELECT mt.membership_id
            FROM membership_tier mt
            WHERE mt.promote_min_point <= base.total_point
            ORDER BY mt.promote_min_point DESC
            LIMIT 1
        ) AS new_membership_id
    FROM (
        SELECT
            pl.user_id,
            SUM(
                CASE WHEN pl.change_amount > 0 THEN pl.change_amount ELSE 0 END
            ) AS total_point
        FROM point_log pl
        WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
          AND pl.created_at < CURRENT_DATE
        GROUP BY pl.user_id
    ) base
) p ON u.user_id = p.user_id
JOIN membership_tier mt_old ON mt_old.membership_id = u.membership_id
JOIN membership_tier mt_new ON mt_new.membership_id = p.new_membership_id
WHERE u.is_delete = 0
  -- 보호기간 안임 (강등 금지)
  AND u.grade_updated_at + INTERVAL 12 MONTH > NOW()
  -- 새 등급이 기존 등급보다 낮음 → 강등 조건 충족
  AND mt_new.sort_order < mt_old.sort_order;



SELECT
    u.user_id,
    u.membership_id AS old_membership_id,
    p.total_point,
    p.new_membership_id,
    mt_old.sort_order AS old_sort_order,
    mt_new.sort_order AS new_sort_order,
    CASE
        WHEN u.grade_updated_at + INTERVAL 12 MONTH > NOW()
             AND mt_new.sort_order < mt_old.sort_order
            THEN u.membership_id   -- 보호기간 + 강등 → 기존 등급 유지
        ELSE p.new_membership_id   -- 승급 / 같은 등급 / 보호기간 끝난 강등
    END AS final_membership_id
FROM user u
JOIN (
        SELECT
            base.user_id,
            base.total_point,
            (
                SELECT mt.membership_id
                FROM membership_tier mt
                WHERE mt.promote_min_point <= base.total_point
                ORDER BY mt.promote_min_point DESC
                LIMIT 1
            ) AS new_membership_id
        FROM (
            SELECT
                pl.user_id,
                SUM(pl.change_amount) AS total_point
            FROM point_log pl
            WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
              AND pl.created_at < CURRENT_DATE
              AND pl.status = 0
              AND pl.change_amount > 0
            GROUP BY pl.user_id
        ) base
) p ON u.user_id = p.user_id
JOIN membership_tier mt_old ON mt_old.membership_id = u.membership_id
JOIN membership_tier mt_new ON mt_new.membership_id = p.new_membership_id
WHERE u.is_delete = 0
  AND u.membership_id <> p.new_membership_id
  AND NOT (
        u.grade_updated_at + INTERVAL 12 MONTH > NOW()
        AND mt_new.sort_order < mt_old.sort_order
      );

SELECT count(1) FROM payment WHERE status = 2;

SHOW TRIGGERS LIKE 'point%';
SHOW TRIGGERS LIKE 'ticket_discount%';
SHOW TRIGGERS LIKE 'payment%';
SHOW TRIGGERS LIKE 'reservation%';