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


SELECT
    pl.*,
    CASE
        WHEN pl.status = 0 AND pl.change_amount > 0 THEN '적립'
        WHEN pl.status = 1 AND pl.change_amount < 0 THEN '사용'
        WHEN pl.status = 3 AND pl.change_amount > 0 THEN '사용 취소/환불'
        WHEN pl.status = 2 THEN '소멸'
        ELSE '기타'
    END AS log_meaning
FROM point_log pl
WHERE pl.user_id = 20910
ORDER BY pl.created_at;

SELECT * FROM coupon_detail WHERE user_coupon_id = 3915;

SELECT * FROM reservation WHERE user_id = 20910;

SELECT user_id,
       SUM(change_amount) AS refund_sum
FROM point_log
WHERE status = 3         -- 사용 취소/환불
AND created_at
GROUP BY user_id;

START TRANSACTION;

-- 1-1. 11월 27일자 환불 로그( status = 3 )가 사용자별로 얼마나 있는지 확인
SELECT user_id,
       SUM(change_amount) AS refund_sum
FROM point_log
WHERE status = 3
  AND change_amount > 0              -- 안전하게: 환불은 양수만
  AND DATE(created_at) = '2025-11-27'
GROUP BY user_id;

-- 1-2. 환불 효과를 되돌리기: user.point 에서 환불 금액만큼 빼기
UPDATE user u
JOIN (
    SELECT user_id,
           SUM(change_amount) AS refund_sum
    FROM point_log
    WHERE status = 3
      AND change_amount > 0
      AND DATE(created_at) = '2025-11-27'
    GROUP BY user_id
) p ON u.user_id = p.user_id
SET u.point = u.point - p.refund_sum
WHERE p.user_id IS NOT NULL;   -- ← 이 한 줄

-- 1-3. 이제 11월 27일자 환불 로그만 깔끔하게 삭제
DELETE
FROM point_log
WHERE status = 3
  AND change_amount > 0
  AND DATE(created_at) = '2025-11-27';

COMMIT;


START TRANSACTION;

UPDATE coupon_detail cd
JOIN (
    SELECT DISTINCT user_coupon_id
    FROM coupon_log
    WHERE status = 3
      AND DATE(created_at) = '2025-11-27'
) cl ON cl.user_coupon_id = cd.user_coupon_id
SET cd.status = 1;

-- (3) coupon_log 취소 로그 삭제
DELETE
FROM coupon_log
WHERE status = 3
  AND DATE(created_at) = '2025-11-27';

COMMIT;

SELECT * FROM coupon_detail
WHERE status = 3;


SELECT user_coupon_id,
       GROUP_CONCAT(status ORDER BY created_at) AS status_history
FROM coupon_log
WHERE DATE(created_at) = '2025-11-27'
GROUP BY user_coupon_id
HAVING SUM(status = 1) > 0
   AND SUM(status = 3) > 0;

UPDATE coupon_detail cd
JOIN (
    SELECT user_coupon_id
    FROM coupon_log
    WHERE DATE(created_at) = '2025-11-27'
    GROUP BY user_coupon_id
    HAVING SUM(status = 1) > 0
       AND SUM(status = 3) > 0
) l ON l.user_coupon_id = cd.user_coupon_id
SET cd.status = 1      -- 사용으로 통일
WHERE cd.status <> 1;  -- 원래부터 1인 애는 건드리지 않기

DELETE cl
FROM coupon_log cl
JOIN (
    SELECT user_coupon_id
    FROM coupon_log
    WHERE DATE(created_at) = '2025-11-27'
    GROUP BY user_coupon_id
    HAVING SUM(status = 1) > 0
       AND SUM(status = 3) > 0
) l ON l.user_coupon_id = cl.user_coupon_id
WHERE cl.status = 3
  AND DATE(cl.created_at) = '2025-11-27';
