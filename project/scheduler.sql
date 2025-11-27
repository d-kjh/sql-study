SHOW VARIABLES WHERE variable_name LIKE '%event%';

DELIMITER $$

CREATE EVENT ev_update_membership_by_yearly_point
    ON SCHEDULE
        EVERY 1 MONTH
            STARTS (TIMESTAMP(CURRENT_DATE, '04:00:00'))
    ON COMPLETION PRESERVE
    DO
    BEGIN
        UPDATE user u
            JOIN (SELECT pl.user_id,
                         SUM(
                                 CASE WHEN pl.change_amount > 0 THEN pl.change_amount ELSE 0 END
                         ) AS total_earn_point
                  FROM point_log pl
                  WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
                    AND pl.created_at < CURRENT_DATE
                  GROUP BY pl.user_id) p ON u.user_id = p.user_id
            JOIN (SELECT p2.user_id,
                         (SELECT mt.membership_id
                          FROM membership_tier mt
                          WHERE mt.promote_min_point <= p2.total_earn_point
                          ORDER BY mt.promote_min_point DESC
                          LIMIT 1) AS new_membership_id
                  FROM (SELECT pl.user_id,
                               SUM(
                                       CASE WHEN pl.change_amount > 0 THEN pl.change_amount ELSE 0 END
                               ) AS total_earn_point
                        FROM point_log pl
                        WHERE pl.created_at >= DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
                          AND pl.created_at < CURRENT_DATE
                        GROUP BY pl.user_id) p2) t ON u.user_id = t.user_id
        SET u.membership_id = t.new_membership_id
        WHERE u.is_delete = 0; -- 탈퇴회원 제외
    END $$

DELIMITER ;


DELIMITER $$

CREATE EVENT ev_expire_user_voucher
    ON SCHEDULE EVERY 1 DAY
        STARTS '2025-01-01 03:00:00'
    DO
    UPDATE user_voucher
    SET status = 2
    WHERE status = 0
      AND expire_date < CURDATE();

DELIMITER ;



DELIMITER $$

CREATE EVENT evt_delete_non_user_daily
ON SCHEDULE EVERY 1 DAY
STARTS (current_date + INTERVAL 1 HOUR)
DO
BEGIN
    DELETE nu
    FROM non_user nu;

END $$

DELIMITER ;
