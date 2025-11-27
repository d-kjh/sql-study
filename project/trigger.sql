DROP TRIGGER trg_user_before_insert_membership_card;

-- 회원가입시 카드 번호 지급

DELIMITER $$

CREATE TRIGGER trg_user_before_insert_membership_card
    BEFORE INSERT
    ON user
    FOR EACH ROW
BEGIN
    DECLARE new_card VARCHAR(19);
    DECLARE card_exists INT DEFAULT 1;

    WHILE card_exists > 0
        DO
            SET new_card = CONCAT(
                    LPAD(FLOOR(RAND() * 10000), 4, '0'), '-',
                    LPAD(FLOOR(RAND() * 10000), 4, '0'), '-',
                    LPAD(FLOOR(RAND() * 10000), 4, '0'), '-',
                    LPAD(FLOOR(RAND() * 10000), 4, '0')
                           );

            SELECT COUNT(*)
            INTO card_exists
            FROM user
            WHERE card_num = new_card;
        END WHILE;

    SET NEW.card_num = new_card;
END$$

DELIMITER ;

-- 회원가입시 가입축하 쿠폰 지급

DELIMITER $$

CREATE TRIGGER trg_user_after_insert_join_coupon
    AFTER INSERT
    ON user
    FOR EACH ROW
BEGIN
    INSERT INTO coupon_detail (user_id, coupon_id, expired_date, status)
    VALUES (NEW.user_id, 1, DATE_ADD(CURDATE(), INTERVAL 30 DAY), 0);
END $$

DELIMITER ;

-- 쿠폰 테이블 변경시 사용 내역 insert

DELIMITER  $$

CREATE TRIGGER trg_coupon_detail_update
    AFTER UPDATE
    ON coupon_detail
    FOR EACH ROW
BEGIN
    INSERT INTO coupon_log (user_coupon_id, status)
    VALUES (new.user_coupon_id, NEW.status);
END $$

DELIMITER ;

-- 맴버십이 변경된 후 log insert

DELIMITER $$

CREATE TRIGGER trg_user_membership_change
    BEFORE UPDATE
    ON `user`
    FOR EACH ROW
BEGIN
    -- membership_id 가 변경된 경우에만 동작
    IF NEW.membership_id <> OLD.membership_id THEN
        -- 등급 변경 시간 갱신 (별도 UPDATE 문 필요 없음)
        SET NEW.grade_updated_at = NOW();

        -- 등급 변경 로그 기록
        INSERT INTO membership_log (user_id, membership_id)
        VALUES (NEW.user_id, NEW.membership_id);
    END IF;
END$$

DELIMITER ;

-- 포인트 로그 insert시 자동으로 point 계산

DELIMITER $$

CREATE TRIGGER trg_point_log_after_insert
    AFTER INSERT
    ON point_log
    FOR EACH ROW
BEGIN
    UPDATE user
    SET point = point + NEW.change_amount
    WHERE user_id = NEW.user_id;
END $$

DELIMITER ;

-- 스토어에서 교환권 구매시 유저 보유 및 로그 추가

DELIMITER $$

CREATE TRIGGER trg_user_voucher_after_insert
    AFTER INSERT
    ON user_voucher
    FOR EACH ROW
BEGIN
    INSERT INTO voucher_log(user_voucher_id, status)
    VALUES (NEW.user_voucher_id, '0');
END $$

DELIMITER ;

-- 회원이 보유한 교환권 사용 및 만료 시 로그 추가

DELIMITER $$

CREATE TRIGGER trg_user_voucher_after_update
    AFTER UPDATE
    ON user_voucher
    FOR EACH ROW
BEGIN
    INSERT INTO voucher_log(user_voucher_id, status)
    VALUES (new.user_voucher_id, NEW.status);
END $$

DELIMITER ;

-- coupon_detail에 insert 발생 시 log 추가

DELIMITER $$

CREATE TRIGGER trg_coupon_detail_after_insert
    AFTER INSERT
    ON coupon_detail
    FOR EACH ROW
BEGIN
    INSERT INTO coupon_log(user_coupon_id, created_at)
    VALUES (NEW.user_coupon_id, NEW.issue_date);
END $$

DELIMITER ;

-- reservation에 상태값이 취소로 변경이 되면 예매 좌석, 예매 인원 삭제(더미용)
DROP TRIGGER trg_reservation_after_update;

DELIMITER $$

CREATE TRIGGER trg_reservation_after_update
    AFTER UPDATE
    ON reservation
    FOR EACH ROW
BEGIN
    -- 상태가 2로 변경이 된다면
    IF NEW.status = 2 AND OLD.status <> 2 THEN

        -- 예매별 예매 좌석 + 실제 좌석 같이 삭제
        DELETE rs, rsl
        FROM reservation_seat_list rsl
                 JOIN reservation_seat rs
                      ON rs.reservation_seat_id = rsl.reservation_seat_id
        WHERE reservation_id = NEW.reservation_id;

        -- 예매 인원 삭제
        DELETE FROM reservation_count WHERE reservation_id = NEW.reservation_id;
    END IF;

END $$

DELIMITER ;









