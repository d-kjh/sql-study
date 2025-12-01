SHOW VARIABLES WHERE variable_name LIKE '%event%';

DROP EVENT evt_update_membership_yearly_point;

DELIMITER $$

CREATE EVENT evt_update_membership_yearly_point
    ON SCHEDULE
        EVERY 1 MONTH
            STARTS (TIMESTAMP(CURRENT_DATE, '01:00:00'))
    ON COMPLETION PRESERVE
    DO
    BEGIN
        UPDATE user u
            -- 지난 1년간 포인트 합산 + 새 등급 계산
            JOIN (
                -- 포인트 로그가 있는 사람들 id와 최고 맴버십 티어
                SELECT base.user_id,
                       base.total_point,
                       (
                           -- 2. 합산된 포인트로 membership_tier에서 최고 등급 select
                           SELECT mt.membership_id
                           FROM membership_tier mt
                           WHERE mt.promote_min_point <= base.total_point
                           ORDER BY mt.promote_min_point DESC
                           LIMIT 1) AS new_membership_id
                FROM (
                         -- 1. point_log에 지난 1년간 포인트 적립 로그가 있는 사람들 select 및 포인트 합산
                         SELECT pl.user_id,
                                SUM(pl.change_amount) AS total_point
                         FROM point_log pl
                         -- 오늘 00시 기준으로 지난 1년치 (전날 23:59:59까지)
                         WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
                           AND pl.created_at < CURRENT_DATE
                           AND pl.status = 0        -- 상태가 적립인 row만
                           AND pl.change_amount > 0 -- 2중 검사(적립 중 0보다 큰 값만)
                         GROUP BY pl.user_id) base) p ON u.user_id = p.user_id

            -- 기존 등급 정보
            JOIN membership_tier mt_old ON mt_old.membership_id = u.membership_id
            -- 새 등급 정보
            JOIN membership_tier mt_new ON mt_new.membership_id = p.new_membership_id
        SET u.membership_id = CASE
            -- 12개월 보호기간 안 + 새 등급이 더 낮을 때 → 강등 금지, 기존 등급 유지
                                  WHEN u.grade_updated_at + INTERVAL 12 MONTH > NOW()
                                      AND mt_new.sort_order < mt_old.sort_order
                                      THEN u.membership_id
            -- 그 외(승급 / 같은 등급 / 보호기간 끝난 후 강등) → 새 등급 적용
                                  ELSE p.new_membership_id END
        WHERE u.is_delete = 0
          -- 기존 등급과 새 등급 자체가 다를 때만 (같은 등급이면 의미 없는 UPDATE 방지)
          AND u.membership_id <> p.new_membership_id
          -- "보호기간 + 강등" 조합인 경우만 제외하면, 나머지는 실제 등급 변경
          AND NOT (u.grade_updated_at + INTERVAL 12 MONTH > NOW()
            AND mt_new.sort_order < mt_old.sort_order);
    END $$

DELIMITER ;


DELIMITER $$

CREATE EVENT ev_expire_user_voucher
    ON SCHEDULE EVERY 1 DAY
        STARTS (CURRENT_DATE + INTERVAL 1 HOUR)
    DO
    UPDATE user_voucher
    SET status = 2
    WHERE status = 0
      AND expire_date < NOW();

DELIMITER ;


DELIMITER $$

CREATE EVENT evt_delete_non_user_daily
    ON SCHEDULE EVERY 1 DAY
        STARTS (CURRENT_DATE + INTERVAL 1 HOUR)
    DO
    BEGIN
        DELETE
        FROM non_user
        WHERE expire_at < NOW();

    END $$

DELIMITER ;


DELIMITER $$

CREATE EVENT evt_update_store_daily
    ON SCHEDULE EVERY 1 DAY
        STARTS (CURRENT_DATE + INTERVAL 1 MINUTE)
    DO
    BEGIN
        UPDATE store_item
        SET is_active = 1
        WHERE end_date IS NOT NULL
          AND end_date < NOW()
          AND is_active = 0;
    END $$

DELIMITER ;