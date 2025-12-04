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
    IF OLD.status <> NEW.status THEN
        INSERT INTO coupon_log (user_coupon_id, status)
        VALUES (new.user_coupon_id, NEW.status);
    END IF
    $$
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
    IF OLD.status <> NEW.status THEN
        INSERT INTO voucher_log(user_voucher_id, status)
        VALUES (new.user_voucher_id, NEW.status);
    END IF
    $$
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

# 예매 신청 시 비회원 정보 삭제기간 update
DELIMITER $$

CREATE TRIGGER trg_reservation_non_user_expire
    AFTER INSERT
    ON reservation
    FOR EACH ROW
BEGIN
    DECLARE v_end_time DATETIME;
    DECLARE v_new_expire DATETIME;
    IF NEW.non_user_id IS NOT NULL THEN

        -- 1. 상영 종료 시간 가져오기
        SELECT ss.end_time
        INTO v_end_time
        FROM screen_schedule ss
        WHERE ss.schedule_id = NEW.schedule_id;

        -- 2. +7일 계산
        SET v_new_expire = DATE_ADD(v_end_time, INTERVAL 7 DAY);

        -- 3. non_user.expire_at 갱신 (더 늦을 때만 변경)
        UPDATE non_user
        SET expire_at = CASE
                            WHEN expire_at < v_new_expire
                                THEN v_new_expire
                            ELSE expire_at
            END
        WHERE non_user_id = NEW.non_user_id;
    END IF;
END $$

DELIMITER ;

# 영화가 삭제(soft delete)되면 영화관에 등록된 영화 테이블 hard delete
DELIMITER $$

CREATE TRIGGER trg_movie_after_update
    AFTER UPDATE
    ON movie
    FOR EACH ROW
BEGIN
    -- 0 -> 1 로 바뀔 때만 동작
    IF OLD.is_delete <> 1 AND NEW.is_delete = 1 THEN
        DELETE
        FROM theater_movie
        WHERE movie_id = NEW.movie_id
          AND end_date >= CURDATE();
    END IF;
END $$

DELIMITER ;

# 영화관에 등록된 영화 테이블 hard delete되면 상영일정에서 그 영화관의 해당 영화 상영일정 모두 soft delete
DELIMITER $$

CREATE TRIGGER trg_theater_movie_after_delete
    AFTER DELETE
    ON theater_movie
    FOR EACH ROW
BEGIN
    UPDATE screen_schedule ss
        JOIN screen s
        ON ss.screen_id = s.screen_id
    SET ss.is_delete = 1
    WHERE s.theater_id = OLD.theater_id
      AND ss.movie_id = OLD.movie_id
      AND ss.is_delete = 0
      -- 아직 시작도 안 한 상영 예정 일정만 삭제
      AND TIMESTAMP(ss.running_date, ss.start_time) > NOW();
END $$

DELIMITER ;

# 상영관이 soft delete될 시 상영일정에서 해당 상영관의 상영예정인 모든 영화상영일정을 soft delete
DELIMITER $$

CREATE TRIGGER trg_screen_after_update
    AFTER UPDATE
    ON screen
    FOR EACH ROW
BEGIN
    -- is_delete 값이 바뀔 때만 동작
    IF OLD.is_delete <> NEW.is_delete THEN

        -- 상영관이 삭제될 때 (0 -> 1)
        IF NEW.is_delete = 1 THEN
            -- 아직 시작도 안 한 상영 예정 일정만 삭제 처리
            UPDATE screen_schedule ss
            SET ss.is_delete = 1
            WHERE ss.screen_id = NEW.screen_id
              AND ss.is_delete = 0
              AND TIMESTAMP(ss.running_date, ss.start_time) > NOW();
            -- 여기서 is_delete가 0 -> 1로 바뀌는 애들만
            -- screen_schedule AFTER UPDATE 트리거 타면서 예매/좌석 취소 처리
        END IF;

        -- 좌석은 삭제/복구 모두 상영관과 동기화
        UPDATE seat
        SET is_delete = NEW.is_delete
        WHERE screen_id = NEW.screen_id;

    END IF;
END $$

DELIMITER ;

# 상영일정에서 soft delete될 시 상영예정인 일정인지 다시 확인 후 예매 취소 처리
DELIMITER $$

CREATE TRIGGER trg_screen_schedule_after_update
    AFTER UPDATE
    ON screen_schedule
    FOR EACH ROW
BEGIN
    -- 0 -> 1 로 처음 삭제될 때만 실행 (중복 실행 방지)
    IF OLD.is_delete <> 1 AND NEW.is_delete = 1 THEN
        -- 혹시 모를 상황 대비: 정말 상영예정인 경우에만 처리
        IF TIMESTAMP(NEW.running_date, NEW.start_time) > NOW() THEN
            -- 해당 상영 일정의 예매 건들만 취소 상태로 변경
            UPDATE reservation r
            SET r.status = 2 -- 2 = 취소
            WHERE r.schedule_id = NEW.schedule_id;
        END IF;
    END IF;
END $$

DELIMITER ;

# 포인트 로그 포인트 자동 계산
DELIMITER $$

CREATE TRIGGER trg_point_log_before_insert
    BEFORE INSERT
    ON point_log
    FOR EACH ROW
BEGIN
    DECLARE v_current_point DECIMAL(10, 2);

    -- 현재 user의 잔여 포인트를 읽어옴
    SELECT point
    INTO v_current_point
    FROM user
    WHERE user_id = NEW.user_id;

    -- 새 로그 후의 잔액(balance_after) 계산
    SET NEW.balance_after = v_current_point + NEW.change_amount;
END $$
