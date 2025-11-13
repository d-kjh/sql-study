-- 맴버십 등급 규칙 테이블 (포인트 구간별 등급)
CREATE TABLE membership_rule
(
    grade_code VARCHAR(20) PRIMARY KEY, -- 'BRONZE', 'SILVER', ...
    min_point  INT NOT NULL,
    max_point  INT NOT NULL
);

-- 회원 테이블
CREATE TABLE member
(
    member_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
    name             VARCHAR(50) NOT NULL,
    total_point      INT         NOT NULL DEFAULT 0,        -- 총 포인트
    membership_grade VARCHAR(20) NOT NULL DEFAULT 'BRONZE', -- 현재 맴버십 등급
    created_at       DATETIME    NOT NULL DEFAULT NOW()
);

-- 포인트 히스토리
CREATE TABLE point_history
(
    point_history_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    member_id        BIGINT   NOT NULL,
    change_point     INT      NOT NULL, -- + 적립 / - 사용
    type             TINYINT  NOT NULL,
    -- 1 = 적립(SAVE), 2 = 사용(USE), 3 = 조정(ADJUST)
    description      VARCHAR(255),
    created_at       DATETIME NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_point_member
        FOREIGN KEY (member_id) REFERENCES member (member_id)
);

-- 결제
CREATE TABLE payment
(
    payment_id     BIGINT PRIMARY KEY AUTO_INCREMENT,
    member_id      BIGINT   NOT NULL,
    pay_amount     INT      NOT NULL,              -- 실제 결제 금액(포인트/쿠폰 적용 후)
    used_point     INT      NOT NULL DEFAULT 0,    -- 사용한 포인트
    used_coupon_id BIGINT            DEFAULT NULL, -- 사용한 쿠폰 (없으면 NULL)
    created_at     DATETIME NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_payment_member
        FOREIGN KEY (member_id) REFERENCES member (member_id)
);


-- 쿠폰
CREATE TABLE coupon
(
    coupon_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
    member_id      BIGINT       NOT NULL,
    name           VARCHAR(100) NOT NULL,           -- '영화 2천원 할인', '팝콘 50%' 등
    discount_type  TINYINT      NOT NULL,           -- 1 = 금액할인, 2 = 퍼센트할인
    discount_value INT          NOT NULL,           -- 2000원, 10(%)
    status         TINYINT      NOT NULL DEFAULT 0, -- 0 = 발급(ISSUED), 1 = 사용(USED), 2 = 만료(EXPIRED)
    issued_at      DATETIME     NOT NULL DEFAULT NOW(),
    expired_at     DATETIME     NOT NULL,           -- 만료일
    used_at        DATETIME     NULL,
    CONSTRAINT fk_coupon_member
        FOREIGN KEY (member_id) REFERENCES member (member_id)
);

-- 쿠폰 사용 로그
CREATE TABLE coupon_use_log
(
    coupon_use_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    coupon_id     BIGINT   NOT NULL,
    member_id     BIGINT   NOT NULL,
    payment_id    BIGINT   NULL, -- 어떤 결제에서 썼는지
    used_at       DATETIME NOT NULL DEFAULT NOW(),
    used_amount   INT      NULL, -- 실제 할인된 금액
    CONSTRAINT fk_coupon_use_coupon
        FOREIGN KEY (coupon_id) REFERENCES coupon (coupon_id),
    CONSTRAINT fk_coupon_use_member
        FOREIGN KEY (member_id) REFERENCES member (member_id),
    CONSTRAINT fk_coupon_use_payment
        FOREIGN KEY (payment_id) REFERENCES payment (payment_id)
);

INSERT INTO membership_rule (grade_code, min_point, max_point)
VALUES ('BRONZE', 0, 9999),
       ('SILVER', 10000, 49999),
       ('GOLD', 50000, 99999),
       ('PLATINUM', 100000, 999999);

-- 회원 1명
INSERT INTO member (name)
VALUES ('홍길동');

-- 회원 1에게 쿠폰 2개 발급
INSERT INTO coupon (member_id, name, discount_type, discount_value, expired_at)
VALUES (1, '영화 2,000원 할인', 1, 2000, DATE_ADD(NOW(), INTERVAL 1 HOUR)), -- 1시간 뒤 만료
       (1, '팝콘 20% 할인', 2, 20, DATE_ADD(NOW(), INTERVAL 2 DAY)); -- 2일 뒤 만료

SELECT *
FROM member;
SELECT *
FROM coupon;


DELIMITER $$

DROP TRIGGER IF EXISTS trg_payment_after_insert$$

CREATE TRIGGER trg_payment_after_insert
    AFTER INSERT
    ON payment
    FOR EACH ROW
BEGIN
    DECLARE v_save_point INT DEFAULT 0;
    DECLARE v_total_point INT DEFAULT 0;
    DECLARE v_grade VARCHAR(20);

    -- 1) 포인트 사용 처리 (사용한 포인트가 있으면)
    IF NEW.used_point > 0 THEN
        -- 포인트 사용 내역 로그
        INSERT INTO point_history (member_id, change_point, type, description)
        VALUES (NEW.member_id, -NEW.used_point, 2, '결제 시 포인트 사용');

        -- 회원 총 포인트 차감
        UPDATE member
        SET total_point = total_point - NEW.used_point
        WHERE member_id = NEW.member_id;
    END IF;

    -- 2) 포인트 적립 처리 (결제금액 기준 5% 적립 예시)
    IF NEW.pay_amount > 0 THEN
        SET v_save_point = FLOOR(NEW.pay_amount * 0.05); -- 5% 적립

        IF v_save_point > 0 THEN
            INSERT INTO point_history (member_id, change_point, type, description)
            VALUES (NEW.member_id, v_save_point, 1, '결제 시 포인트 적립');

            UPDATE member
            SET total_point = total_point + v_save_point
            WHERE member_id = NEW.member_id;
        END IF;
    END IF;

    -- 3) 최종 total_point 조회
    SELECT total_point
    INTO v_total_point
    FROM member
    WHERE member_id = NEW.member_id;

    -- 4) 맴버십 등급 계산
    SELECT grade_code
    INTO v_grade
    FROM membership_rule
    WHERE v_total_point BETWEEN min_point AND max_point
    LIMIT 1;

    -- 5) 맴버십 등급 업데이트
    IF v_grade IS NOT NULL THEN
        UPDATE member
        SET membership_grade = v_grade
        WHERE member_id = NEW.member_id;
    END IF;
END$$

DELIMITER ;


DELIMITER $$

DROP TRIGGER IF EXISTS trg_coupon_use_after_insert$$

CREATE TRIGGER trg_coupon_use_after_insert
    AFTER INSERT
    ON coupon_use_log
    FOR EACH ROW
BEGIN
    UPDATE coupon
    SET status  = 1,
        used_at = NEW.used_at
    WHERE coupon_id = NEW.coupon_id
      AND status = 0; -- 아직 사용 전인 쿠폰만
END$$

DELIMITER ;

DELIMITER $$

DROP EVENT IF EXISTS ev_membership_daily$$

CREATE EVENT ev_membership_daily
    ON SCHEDULE EVERY 1 DAY
        STARTS TIMESTAMP(CURRENT_DATE, '04:00:00')
    DO
    BEGIN
        UPDATE member m
            JOIN membership_rule r
            ON m.total_point BETWEEN r.min_point AND r.max_point
        SET m.membership_grade = r.grade_code;
    END$$

DELIMITER ;

DELIMITER $$

DROP EVENT IF EXISTS ev_expire_coupons$$

CREATE EVENT ev_expire_coupons
    ON SCHEDULE EVERY 1 MINUTE -- 테스트용: 1분마다
    DO
    BEGIN
        UPDATE coupon
        SET status = 2 -- EXPIRED
        WHERE status = 0
          AND expired_at < NOW();
    END$$

DELIMITER ;

SHOW EVENTS;

SELECT *
FROM member;
SELECT *
FROM membership_rule;
SELECT *
FROM coupon;
SELECT *
FROM point_history;
SELECT *
FROM payment;
SELECT *
FROM coupon_use_log;


-- 포인트 없이 20000원 결제
INSERT INTO payment (member_id, pay_amount, used_point, used_coupon_id)
VALUES (1, 20000, 0, NULL);

-- 확인
SELECT *
FROM payment;
SELECT *
FROM point_history
WHERE member_id = 1;
SELECT *
FROM member
WHERE member_id = 1;


-- 쿠폰 사용 테스트

INSERT INTO coupon_use_log (coupon_id, member_id, payment_id, used_amount)
VALUES (1, 1, 1, 2000);

SELECT *
FROM coupon_use_log;
SELECT *
FROM coupon
WHERE coupon_id = 1;


-- 쿠폰 만료 테스트
-- 강제로 만료 시점 과거로 수정 (테스트용)
UPDATE coupon
SET expired_at = DATE_SUB(NOW(), INTERVAL 1 MINUTE),
    status     = 0
WHERE coupon_id = 2;

-- 1~2분 기다린 뒤
SELECT *
FROM coupon
WHERE coupon_id = 2;
