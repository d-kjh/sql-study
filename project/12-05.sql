EXPLAIN
SELECT pl.point_log_id,
       pl.user_id,
       pl.change_amount,
       pl.balance_after,
       pl.status,
       pl.created_at
FROM point_log pl
WHERE pl.user_id = 12
  AND pl.status = 0
  AND pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
  AND pl.created_at < CURRENT_DATE; -- 오늘 00:00 기준 1년치

SELECT user_id, COUNT(1)
FROM point_log
WHERE created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
  AND created_at < CURRENT_DATE
  AND status = 0
GROUP BY user_id;

EXPLAIN
SELECT user_id, membership_id, created_at
FROM membership_log
WHERE created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
AND user_id = 1;

EXPLAIN
SELECT m.movie_id, m.title, count(1) FROM movie m
JOIN screen_schedule ss
ON ss.movie_id = m.movie_id
JOIN reservation r
ON r.schedule_id = ss.schedule_id
GROUP BY m.movie_id;

# 너무 느림 개선필요
SELECT
    m.movie_id,
    m.title,
    COUNT(*)                           AS audience_cnt,  -- 관객 수(예매 건수 기준)
    SUM(r.price)                       AS total_price    -- 매출까지 보고 싶으면
FROM movie m
JOIN screen_schedule ss
    ON ss.movie_id = m.movie_id
JOIN reservation r
    ON r.schedule_id = ss.schedule_id
WHERE r.status = 1                     -- 결제 완료만
GROUP BY m.movie_id, m.title
ORDER BY audience_cnt DESC;            -- 관객 수 기준 박스오피스 랭킹



SELECT
    u.user_id,
    u.membership_id AS old_membership_id,
    p.total_point,
    p.new_membership_id AS calculated_new_membership_id,
    mt_old.sort_order AS old_sort_order,
    mt_new.sort_order AS new_sort_order,

    CASE
        WHEN u.grade_updated_at + INTERVAL 12 MONTH > NOW()
             AND mt_new.sort_order < mt_old.sort_order
            THEN u.membership_id     -- 강등 보호기간 → 기존 등급 유지
        ELSE p.new_membership_id
    END AS final_membership_to_apply
FROM user u
JOIN (
        -- 지난 1년간 적립 포인트 합산 + 새 등급 계산
        SELECT base.user_id,
               base.total_point,
               (
                   SELECT mt.membership_id
                   FROM membership_tier mt
                   WHERE mt.promote_min_point <= base.total_point
                   ORDER BY mt.promote_min_point DESC
                   LIMIT 1
               ) AS new_membership_id
        FROM (
                 SELECT pl.user_id,
                        SUM(pl.change_amount) AS total_point
                 FROM point_log pl
                 WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
                   AND pl.created_at < CURRENT_DATE
                   AND pl.status = 0
                   AND pl.change_amount > 0
                 GROUP BY pl.user_id
             ) base
     ) p
     ON u.user_id = p.user_id
JOIN membership_tier mt_old ON mt_old.membership_id = u.membership_id
JOIN membership_tier mt_new ON mt_new.membership_id = p.new_membership_id
WHERE u.is_delete = 0
  AND u.membership_id <> p.new_membership_id   -- 변경 필요 유저만 표시
  AND NOT (u.grade_updated_at + INTERVAL 12 MONTH > NOW()
           AND mt_new.sort_order < mt_old.sort_order); -- 보호기간 강등 제외

UPDATE user
SET grade_updated_at = DATE_SUB('2025-11-11', INTERVAL 1 YEAR);


SELECT
    COUNT(*)          AS total_last_year_rows,
    MIN(created_at)   AS min_created_at,
    MAX(created_at)   AS max_created_at
FROM point_log
WHERE status = 0
  AND change_amount > 0
  AND created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
  AND created_at < CURRENT_DATE;

SELECT
    pl.user_id,
    SUM(pl.change_amount) AS total_point
FROM point_log pl
WHERE pl.status = 0
  AND pl.change_amount > 0
GROUP BY pl.user_id
ORDER BY total_point DESC
LIMIT 20;

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
    SELECT pl.user_id,
           SUM(pl.change_amount) AS total_point
    FROM point_log pl
    WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
      AND pl.created_at < CURRENT_DATE
      AND pl.status = 0
      AND pl.change_amount > 0
    GROUP BY pl.user_id
) base
LIMIT 50;

SELECT
    u.user_id,
    u.membership_id         AS old_membership_id,
    u.grade_updated_at,
    u.is_delete,
    p.total_point,
    p.new_membership_id,
    mt_old.sort_order       AS old_sort_order,
    mt_new.sort_order       AS new_sort_order,

    -- 디버그용 플래그들
    (u.membership_id <> p.new_membership_id) AS cond_diff_membership,
    (u.is_delete = 0)                        AS cond_not_deleted,
    (u.grade_updated_at + INTERVAL 12 MONTH > NOW()) AS cond_in_protect_period,
    (mt_new.sort_order < mt_old.sort_order)          AS cond_is_downgrade,
    NOT (u.grade_updated_at + INTERVAL 12 MONTH > NOW()
         AND mt_new.sort_order < mt_old.sort_order)  AS cond_pass_protect_rule

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
        SELECT pl.user_id,
               SUM(pl.change_amount) AS total_point
        FROM point_log pl
        WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
          AND pl.created_at < CURRENT_DATE
          AND pl.status = 0
          AND pl.change_amount > 0
        GROUP BY pl.user_id
    ) base
) p ON u.user_id = p.user_id
LEFT JOIN membership_tier mt_old ON mt_old.membership_id = u.membership_id
LEFT JOIN membership_tier mt_new ON mt_new.membership_id = p.new_membership_id
LIMIT 100;

SELECT
    u.user_id,
    u.membership_id AS old_membership_id,
    p.total_point,
    p.new_membership_id,
    mt_old.sort_order AS old_sort_order,
    mt_new.sort_order AS new_sort_order
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
        SELECT pl.user_id,
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
  AND NOT (u.grade_updated_at + INTERVAL 12 MONTH > NOW()
           AND mt_new.sort_order < mt_old.sort_order);

SELECT
    u.user_id,
    u.membership_id AS old_membership_id,
    u.grade_updated_at,
    u.is_delete,
    p.total_point,
    p.new_membership_id,
    mt_old.sort_order AS old_sort_order,
    mt_new.sort_order AS new_sort_order
FROM user u
JOIN (  -- p 서브쿼리 (지난 1년 적립 + 새 등급 계산)
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
        SELECT pl.user_id,
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
LIMIT 100;

UPDATE user
SET membership_id = (
    SELECT membership_id
    FROM membership_tier
    ORDER BY RAND()
    LIMIT 1
)
WHERE RAND() < 0.3;

