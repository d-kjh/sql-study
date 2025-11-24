DELIMITER $$

CREATE TRIGGER trg_user_before_insert_membership_card
    BEFORE INSERT
    ON user
    FOR EACH ROW
BEGIN
    IF NEW.card_num IS NULL OR NEW.card_num = '' THEN
        SET NEW.card_num = CONCAT(
                LPAD(FLOOR(RAND() * 10000), 4, '0'), '-',
                LPAD(FLOOR(RAND() * 10000), 4, '0'), '-',
                LPAD(FLOOR(RAND() * 10000), 4, '0'), '-',
                LPAD(FLOOR(RAND() * 10000), 4, '0')
                           );
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_user_after_insert_join_coupon
    AFTER INSERT
    ON user
    FOR EACH ROW
BEGIN
    DECLARE t_coupon_id BIGINT;
    DECLARE t_valid_day INT;
    DECLARE t_fixed_expire_date DATETIME;
    DECLARE t_expire_date DATETIME;


END $$


DELIMITER $$

CREATE TRIGGER trg_user_membership_change
    AFTER UPDATE
    ON `user`
    FOR EACH ROW
BEGIN
    -- membership_id 가 변경된 경우에만 로그 기록
    IF NEW.membership_id <> OLD.membership_id THEN
        INSERT INTO membership_log (user_id, membership_id, created_at)
        VALUES (NEW.user_id, NEW.membership_id, NOW());

        UPDATE `user`
        SET grade_updated_at = NOW()
        WHERE user_id = NEW.user_id;
    END IF;
END $$

DELIMITER ;

DROP TRIGGER IF EXISTS trg_user_membership_change;

DELIMITER $$

CREATE TRIGGER trg_user_membership_change
BEFORE UPDATE ON `user`
FOR EACH ROW
BEGIN
    -- membership_id 가 변경된 경우에만 동작
    IF NEW.membership_id <> OLD.membership_id THEN
        -- 등급 변경 시간 갱신 (별도 UPDATE 문 필요 없음)
        SET NEW.grade_updated_at = NOW();

        -- 등급 변경 로그 기록
        INSERT INTO membership_log (user_id, membership_id, created_at)
        VALUES (NEW.user_id, NEW.membership_id, NOW());
    END IF;
END$$

DELIMITER ;