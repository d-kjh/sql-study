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

