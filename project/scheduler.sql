DELIMITER $$

CREATE EVENT ev_membership_update_monthly
ON SCHEDULE
EVERY 1 MONTH
STARTS '2025-12-01 09:30:00'
DO
BEGIN
    -- 1년 적립 포인트 기준 재계산
    UPDATE `user` u

END $$