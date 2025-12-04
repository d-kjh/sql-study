SHOW VARIABLES WHERE variable_name LIKE '%event%';

DROP EVENT evt_update_membership_yearly_point;

# 1년간 적립한 포인트 합산해서 선정 기준으로 각 맴버십 등급 별로 승급/강등 스케줄러
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

# 스토어 구매 상품 중 교환권 만료 처리 스케줄러
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

# 비회원 정보 삭제 스케줄러
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

# store 판매 품목 중 판매일이 지난 품목(굿즈 같은 한정 상품 등) 삭제(숨김 - soft delete) 처리 스케줄러
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

DROP EVENT evt_update_coupon_detail;

# 보유 쿠폰 만료일이 지난 쿠폰들 만료 처리 스케줄러
DELIMITER $$

CREATE EVENT evt_update_coupon_detail
    ON SCHEDULE EVERY 1 DAY
        STARTS (TIMESTAMP(CURRENT_DATE, '00:01:00'))
    DO
    BEGIN
        UPDATE coupon_detail
        SET status = 2
        WHERE expired_date < NOW();
    END $$

DELIMITER ;

# 매달 맴버십 별로 맴버십 쿠폰 발급 스케줄러
DELIMITER $$

CREATE EVENT evt_issue_membership_coupon_monthly
    ON SCHEDULE
        EVERY 1 MONTH
            -- 매 달 1일 06시
            STARTS TIMESTAMP(DATE_FORMAT(CURRENT_DATE, '%Y-%m-01'), '06:00:00')
    DO
    BEGIN
        INSERT INTO coupon_detail (user_id, coupon_id, issue_date, expired_date, status)
        SELECT u.user_id,
               c.coupon_id,
               NOW()                                         AS issue_date,
               TIMESTAMP(LAST_DAY(CURRENT_DATE), '23:59:59') AS expired_date, -- 그 달의 마지막날 23시 59분 59초로 포맷
               0                                             AS status
        FROM user u
                 INNER JOIN coupon c
                            ON c.membership_id = u.membership_id
        WHERE u.is_delete = 0
          AND u.membership_id <> 1 -- basic등급은 제외하기 위해
          AND c.membership_id IS NOT NULL
          AND c.is_active = 1
          -- 매 달 중복체크( 중복 발급 방지 )
          AND NOT EXISTS (SELECT 1
                          FROM coupon_detail cd
                          WHERE cd.user_id = u.user_id
                            AND cd.coupon_id = c.coupon_id
                            AND cd.issue_date >= DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
                            AND cd.issue_date < DATE_FORMAT(CURRENT_DATE + INTERVAL 1 MONTH, '%Y-%m-01'));
    END $$

DELIMITER ;

