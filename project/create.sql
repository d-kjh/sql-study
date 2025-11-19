SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS
    coupon_detail,
    point_log,
    membership_coupon_rule,
    non_user,
    admin,
    payment,
    screen_time,
    reservation,
    coupon,
    reservation_seat_list,
    point,
    favorite,
    common_code,
    age_type,
    screen_type,
    employee,
    `user`,
    payment_discount,
    store_item,
    `order`,
    ticket_discount,
    screen_schedule,
    membership_tier,
    movie,
    coupon_log,
    review_like,
    `event`,
    voucher_log,
    reservation_seat,
    user_voucher,
    discount_policy,
    seat,
    event_part,
    store_coupon,
    screen,
    reservation_count,
    user_payment_method,
    review;

SET FOREIGN_KEY_CHECKS = 1;

-- 테이블 admin 구조 내보내기
CREATE TABLE IF NOT EXISTS `admin`
(
    `admin_id` BIGINT      NOT NULL AUTO_INCREMENT COMMENT '관리자 ID',
    `name`     VARCHAR(20) NOT NULL COMMENT '이름',
    PRIMARY KEY (`admin_id`)
);

-- 테이블 common_code 구조 내보내기
CREATE TABLE IF NOT EXISTS `common_code`
(
    `code_id`   VARCHAR(7)  NOT NULL COMMENT '분류 코드 ID',
    `code_type` VARCHAR(3) DEFAULT NULL COMMENT '대분류',
    `name`      VARCHAR(30) NOT NULL COMMENT '분류명',
    PRIMARY KEY (`code_id`)
);

-- 테이블 coupon 구조 내보내기
CREATE TABLE IF NOT EXISTS `coupon`
(
    `coupon_id`           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '쿠폰 ID',
    `coupon_code`         VARCHAR(7)   NOT NULL COMMENT '쿠폰 분류 코드',
    `coupon_name`         VARCHAR(50)  NOT NULL,
    `comment`             VARCHAR(200) NOT NULL,
    `min_price`           INT                   DEFAULT '0',
    `discount_amount`     INT                   DEFAULT NULL COMMENT '할인금액이 값이 있을 시 할인율엔 값이 없어야 한다',
    `discount_rate`       TINYINT               DEFAULT NULL COMMENT '할인율에 값이 있을시 할인금액에는 값이 없어야 한다',
    `max_discount_amount` INT                   DEFAULT NULL COMMENT '할인율에 값이 있을시 반드시 값이 있어야한다',
    `start_date`          DATETIME     NOT NULL,
    `end_date`            DATETIME              DEFAULT NULL,
    `valid_day`           INT          NOT NULL COMMENT '기본 일수 30',
    `is_active`           TINYINT(1)   NOT NULL DEFAULT '0' COMMENT '0: 사용, 1: 미사용',
    PRIMARY KEY (`coupon_id`),
    KEY `FK_coupon_common_code` (`coupon_code`),
    CONSTRAINT `FK_coupon_common_code` FOREIGN KEY (`coupon_code`) REFERENCES `common_code` (`code_id`)
);

-- 테이블 age_type 구조 내보내기
CREATE TABLE IF NOT EXISTS `age_type`
(
    `age_type`     VARCHAR(7) NOT NULL COMMENT '연령 분류 코드(성인, 청소년, 경로, 우대)',
    `adjust_price` INT        NOT NULL COMMENT '가감 가격',
    KEY `FK_common_code_TO_age_type_1` (`age_type`),
    CONSTRAINT `FK_common_code_TO_age_type_1` FOREIGN KEY (`age_type`) REFERENCES `common_code` (`code_id`)
);

-- 테이블 membership_tier 구조 내보내기
CREATE TABLE IF NOT EXISTS `membership_tier`
(
    `membership_id`     INT        NOT NULL AUTO_INCREMENT COMMENT '맴버십 ID',
    `membership_code`   VARCHAR(7) NOT NULL COMMENT 'basic, friend, vip, vvip, mvip',
    `promote_min_point` INT        NOT NULL DEFAULT '0' COMMENT '6000, 12000, 18000, 24000',
    `sort_order`        TINYINT    NOT NULL COMMENT '1,2,3,4,5',
    `is_active`         TINYINT    NOT NULL DEFAULT '0' COMMENT '0 : 미사용중 1 : 사용중',
    PRIMARY KEY (`membership_id`),
    KEY `FK_membership_tier_common_code` (`membership_code`),
    CONSTRAINT `FK_membership_tier_common_code` FOREIGN KEY (`membership_code`) REFERENCES `common_code` (`code_id`)
);

-- 테이블 user 구조 내보내기
CREATE TABLE IF NOT EXISTS `user`
(
    `user_id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '회원 ID',
    `membership_id`    INT          NOT NULL COMMENT '맴버십 ID',
    `name`             VARCHAR(10)  NOT NULL,
    `email`            VARCHAR(100) NOT NULL,
    `password`         VARCHAR(255) NOT NULL COMMENT 'hashcode',
    `birth`            DATE         NOT NULL,
    `carrier_code`     VARCHAR(7)   NOT NULL COMMENT 'KT, SKT, LG',
    `phone`            VARCHAR(13)  NOT NULL,
    `created_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '기본 가입일 -> update시 변경',
    `is_delete`        TINYINT(1)   NOT NULL DEFAULT '0' COMMENT '0: 가입, 1: 탈퇴',
    `grade_updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '맴버십 변경 월 저장',
    PRIMARY KEY (`user_id`),
    KEY `FK_user_membership_tier` (`membership_id`),
    KEY `FK_user_common_code` (`carrier_code`),
    CONSTRAINT `FK_user_common_code` FOREIGN KEY (`carrier_code`) REFERENCES `common_code` (`code_id`),
    CONSTRAINT `FK_user_membership_tier` FOREIGN KEY (`membership_id`) REFERENCES `membership_tier` (`membership_id`)
);

-- 테이블 user_payment_method 구조 내보내기
CREATE TABLE IF NOT EXISTS `user_payment_method`
(
    `user_payment_id` BIGINT   NOT NULL AUTO_INCREMENT COMMENT '유저 등록 결제 수단 ID',
    `user_id`         BIGINT   NOT NULL COMMENT '회원 ID',
    `card_number`     VARCHAR(40)       DEFAULT NULL COMMENT '(마스킹 된) 카드 번호',
    `is_active`       TINYINT  NOT NULL DEFAULT '0' COMMENT '활성화 여부(0: 활성화, 1: 비활성화)',
    `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `deleted_at`      DATETIME          DEFAULT NULL COMMENT '비활성화된 일자',
    PRIMARY KEY (`user_payment_id`),
    KEY `FK_user_payment_method_user` (`user_id`),
    CONSTRAINT `FK_user_payment_method_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
);

-- 테이블 movie 구조 내보내기
CREATE TABLE IF NOT EXISTS `movie`
(
    `movie_id`       BIGINT       NOT NULL AUTO_INCREMENT COMMENT '영화 ID',
    `admin_id`       BIGINT       NOT NULL COMMENT '관리자 ID',
    `title`          VARCHAR(50)  NOT NULL COMMENT '영화 제목',
    `release_date`   DATE         NOT NULL COMMENT '개봉일',
    `running_time`   INT          NOT NULL COMMENT '상영 시간',
    `classification` VARCHAR(20)  NOT NULL COMMENT '연령 등급',
    `genre`          VARCHAR(50)  NOT NULL COMMENT '장르',
    `plot`           TEXT         NOT NULL COMMENT '줄거리',
    `type`           VARCHAR(100) NOT NULL COMMENT '타입',
    `director`       VARCHAR(20)  NOT NULL COMMENT '감독',
    `actor`          VARCHAR(100) NOT NULL COMMENT '배우',
    `is_delete`      TINYINT      NOT NULL DEFAULT '0' COMMENT '삭제 여부(0: 삭제안됨, 1: 삭제됨)',
    `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (`movie_id`),
    KEY `FK_movie_admin` (`admin_id`),
    CONSTRAINT `FK_movie_admin` FOREIGN KEY (`admin_id`) REFERENCES `admin` (`admin_id`)
);

-- 테이블 non_user 구조 내보내기
CREATE TABLE IF NOT EXISTS `non_user`
(
    `non_user_id`   BIGINT       NOT NULL AUTO_INCREMENT COMMENT '비회원 ID',
    `password`      VARCHAR(100) NOT NULL COMMENT 'hashcode',
    `name`          VARCHAR(10)  NOT NULL COMMENT 'GUEST_',
    `phone`         VARCHAR(13)  NOT NULL COMMENT '7일 후 null 처리',
    `birth`         VARCHAR(6)   NOT NULL COMMENT '주민등록번호 앞 6자리, 7일 후  null 처리',
    `is_anonymized` TINYINT      NOT NULL DEFAULT '0' COMMENT '0: 유지, 1: 삭제',
    `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `deleted_at`    DATETIME              DEFAULT NULL COMMENT '삭제 update시',
    PRIMARY KEY (`non_user_id`)
);

-- 테이블 store_item 구조 내보내기
CREATE TABLE IF NOT EXISTS `store_item`
(
    `store_item_id`   BIGINT       NOT NULL AUTO_INCREMENT COMMENT '스토어 상품 ID',
    `store_item_code` VARCHAR(7)   NOT NULL COMMENT '상품 분류(영화 관람권, 팝콘/음료/굿즈 교환권, 할인 쿠폰)',
    `item_name`       VARCHAR(100) NOT NULL COMMENT '상품 이름',
    `item_desc`       VARCHAR(50)  NOT NULL COMMENT '상품 설명',
    `item_limit`      INT          NOT NULL DEFAULT '1' COMMENT '1회 최대 구매 가능 수량(기본 수량 1)',
    `price`           INT          NOT NULL COMMENT '가격',
    `valid_day`       INT          NOT NULL DEFAULT '90' COMMENT '교환권 사용 유효 기간(기본 일수 90)',
    `start_date`      DATE         NOT NULL COMMENT '판매 시작일',
    `end_date`        DATE         NOT NULL COMMENT '판매 종료일',
    `is_active`       TINYINT      NOT NULL DEFAULT '0' COMMENT '판매 여부(0: 판매중, 1: 판매 종료)',
    `payment_type`    TINYINT      NOT NULL DEFAULT '0' COMMENT '결제 방식(0: 현금, 1: 포인트)',
    `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (`store_item_id`),
    KEY `FK_store_item_common_code` (`store_item_code`),
    CONSTRAINT `FK_store_item_common_code` FOREIGN KEY (`store_item_code`) REFERENCES `common_code` (`code_id`)
);

-- 테이블 store_coupon 구조 내보내기
CREATE TABLE IF NOT EXISTS `store_coupon`
(
    `store_item_id` BIGINT NOT NULL COMMENT '스토어 상품 ID',
    `coupon_id`     BIGINT NOT NULL COMMENT '쿠폰 ID',
    PRIMARY KEY (`store_item_id`, `coupon_id`),
    KEY `FK_coupon_TO_store_coupon_1` (`coupon_id`),
    CONSTRAINT `FK_coupon_TO_store_coupon_1` FOREIGN KEY (`coupon_id`) REFERENCES `coupon` (`coupon_id`),
    CONSTRAINT `FK_store_item_TO_store_coupon_1` FOREIGN KEY (`store_item_id`) REFERENCES `store_item` (`store_item_id`)
);

-- 테이블 order 구조 내보내기
CREATE TABLE IF NOT EXISTS `order`
(
    `order_id`      BIGINT   NOT NULL AUTO_INCREMENT COMMENT '주문 ID',
    `user_id`       BIGINT   NOT NULL COMMENT '회원 ID',
    `store_item_id` BIGINT   NOT NULL COMMENT '스토어 상품 ID',
    `quantity`      INT      NOT NULL COMMENT '구매 수량',
    `unit_price`    INT      NOT NULL COMMENT '구매 금액',
    `price`         INT      NOT NULL COMMENT '총 구매 금액',
    `status`        TINYINT  NOT NULL DEFAULT '0' COMMENT '주문 상태(0: 주문 완료, 1: 주문 취소)',
    `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (`order_id`),
    KEY `FK_order_user` (`user_id`),
    KEY `FK_order_store_item` (`store_item_id`),
    CONSTRAINT `FK_order_store_item` FOREIGN KEY (`store_item_id`) REFERENCES `store_item` (`store_item_id`),
    CONSTRAINT `FK_order_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
);

-- 테이블 employee 구조 내보내기
CREATE TABLE IF NOT EXISTS `employee`
(
    `employee_id` BIGINT      NOT NULL AUTO_INCREMENT COMMENT '직원 ID',
    `theater`     VARCHAR(7)  NOT NULL COMMENT '지점 분류 코드',
    `admin_id`    BIGINT      NOT NULL COMMENT '관리자 ID',
    `name`        VARCHAR(20) NOT NULL COMMENT '이름(unique)',
    `phone`       VARCHAR(13) NOT NULL COMMENT '전화번호(unique)',
    `type`        TINYINT     NOT NULL DEFAULT '0' COMMENT '구분(0: 일반, 1: 매니저)',
    `is_active`   TINYINT     NOT NULL DEFAULT '0' COMMENT '재직 여부(0: 재직중, 1: 퇴사)',
    `created_at`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `updated_at`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (`employee_id`),
    KEY `FK_employee_common_code` (`theater`),
    KEY `FK_employee_admin` (`admin_id`),
    CONSTRAINT `FK_employee_admin` FOREIGN KEY (`admin_id`) REFERENCES `admin` (`admin_id`),
    CONSTRAINT `FK_employee_common_code` FOREIGN KEY (`theater`) REFERENCES `common_code` (`code_id`)
);

-- screen
-- 테이블 screen_type 구조 내보내기
CREATE TABLE IF NOT EXISTS `screen_type`
(
    `screen_type` VARCHAR(7) NOT NULL COMMENT '상영관 분류 코드(2D, 4D, 리클라이너, 돌비)',
    `price`       INT        NOT NULL COMMENT '가격',
    KEY `FK_common_code_TO_screen_type_1` (`screen_type`),
    CONSTRAINT `FK_common_code_TO_screen_type_1` FOREIGN KEY (`screen_type`) REFERENCES `common_code` (`code_id`)
);

-- 테이블 screen 구조 내보내기
CREATE TABLE IF NOT EXISTS `screen`
(
    `screen_id`   BIGINT      NOT NULL AUTO_INCREMENT COMMENT '상영관 ID',
    `theater`     VARCHAR(7)  NOT NULL COMMENT '지점 분류 코드',
    `screen_type` VARCHAR(7)  NOT NULL COMMENT '상영관 분류 코드',
    `name`        VARCHAR(20) NOT NULL COMMENT '이름',
    `is_delete`   TINYINT     NOT NULL DEFAULT '0' COMMENT '삭제 여부(0: 삭제안됨, 1: 삭제됨)',
    `created_at`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `updated_at`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (`screen_id`),
    KEY `FK_screen_common_code` (`theater`),
    KEY `FK_screen_screen_type` (`screen_type`),
    CONSTRAINT `FK_screen_common_code` FOREIGN KEY (`theater`) REFERENCES `common_code` (`code_id`),
    CONSTRAINT `FK_screen_screen_type` FOREIGN KEY (`screen_type`) REFERENCES `screen_type` (`screen_type`)
);

-- 테이블 screen_time 구조 내보내기
CREATE TABLE IF NOT EXISTS `screen_time`
(
    `screen_time`  VARCHAR(7) NOT NULL COMMENT '상영 시간 분류 코드(조조, 일반, 심야)',
    `start_time`   TIME       NOT NULL COMMENT '시작 시간(09:00:00, 10:00:00, 23:00:00)',
    `end_time`     TIME       NOT NULL COMMENT '종료 시간(10:59:59, 22:59:59, 02:59:59)',
    `adjust_price` INT        NOT NULL COMMENT '가감 가격',
    KEY `FK_common_code_TO_screen_time_1` (`screen_time`),
    CONSTRAINT `FK_common_code_TO_screen_time_1` FOREIGN KEY (`screen_time`) REFERENCES `common_code` (`code_id`)
);

-- 테이블 screen_schedule 구조 내보내기
CREATE TABLE IF NOT EXISTS `screen_schedule`
(
    `schedule_id`  BIGINT   NOT NULL AUTO_INCREMENT COMMENT '상영 일정 ID',
    `screen_id`    BIGINT   NOT NULL COMMENT '상영관 ID',
    `movie_id`     BIGINT   NOT NULL COMMENT '영화 ID',
    `employee_id`  BIGINT   NOT NULL COMMENT '직원(매니저) ID',
    `running_date` DATE     NOT NULL COMMENT '상영일',
    `start_time`   TIME     NOT NULL COMMENT '상영 시작 시간',
    `end_time`     TIME     NOT NULL COMMENT '상영 종료 시간',
    `price`        INT      NOT NULL COMMENT '가격',
    `is_delete`    TINYINT  NOT NULL DEFAULT '0' COMMENT '삭제 여부(0: 삭제안됨, 1: 삭제됨)',
    `created_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `updated_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (`schedule_id`),
    KEY `FK_screen_schedule_screen` (`screen_id`),
    KEY `FK_screen_schedule_movie` (`movie_id`),
    KEY `FK_screen_schedule_employee` (`employee_id`),
    CONSTRAINT `FK_screen_schedule_employee` FOREIGN KEY (`employee_id`) REFERENCES `employee` (`employee_id`),
    CONSTRAINT `FK_screen_schedule_movie` FOREIGN KEY (`movie_id`) REFERENCES `movie` (`movie_id`),
    CONSTRAINT `FK_screen_schedule_screen` FOREIGN KEY (`screen_id`) REFERENCES `screen` (`screen_id`)
);

-- 테이블 reservation 구조 내보내기
CREATE TABLE IF NOT EXISTS `reservation`
(
    `reservation_id` BIGINT      NOT NULL AUTO_INCREMENT COMMENT '예매 ID',
    `schedule_id`    BIGINT      NOT NULL COMMENT '상영 일정 ID',
    `user_id`        BIGINT               DEFAULT NULL COMMENT '회원 ID',
    `non_user_id`    BIGINT               DEFAULT NULL COMMENT '비회원 ID',
    `buyer_name`     VARCHAR(10) NOT NULL COMMENT 'user, non_user 이름',
    `buyer_phone`    VARCHAR(13) NOT NULL COMMENT 'user, non_user 전화번호',
    `buyer_birth`    VARCHAR(6)  NOT NULL COMMENT 'user, non_user 생년월일',
    `price`          INT         NOT NULL COMMENT '예매 가격',
    `status`         TINYINT     NOT NULL DEFAULT '0' COMMENT '예매 상태 구분(0: 결제중, 1: 완료, 2: 취소)',
    `created_at`     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `updated_at`     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (`reservation_id`),
    KEY `FK_reservation_screen_schedule` (`schedule_id`),
    KEY `FK_reservation_user` (`user_id`),
    KEY `FK_reservation_non_user` (`non_user_id`),
    CONSTRAINT `FK_reservation_non_user` FOREIGN KEY (`non_user_id`) REFERENCES `non_user` (`non_user_id`),
    CONSTRAINT `FK_reservation_screen_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `screen_schedule` (`schedule_id`),
    CONSTRAINT `FK_reservation_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
);

-- 테이블 payment 구조 내보내기
CREATE TABLE IF NOT EXISTS `payment`
(
    `payment_id`     BIGINT   NOT NULL AUTO_INCREMENT COMMENT '결제 ID',
    `reservation_id` BIGINT            DEFAULT NULL COMMENT '예매 ID',
    `order_id`       BIGINT            DEFAULT NULL COMMENT '주문 ID',
    `origin_amount`  INT      NOT NULL COMMENT '할인 전 금액(정가)',
    `discount_total` INT      NOT NULL DEFAULT '0' COMMENT '할인 된 금액 합계',
    `amount`         INT      NOT NULL COMMENT '실제 결제금액',
    `status`         TINYINT  NOT NULL DEFAULT '0' COMMENT '결제 상태 구분 (0: 결제대기, 1: 완료, 2: 취소, 3: 환불)',
    `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '결제 생성 일시 - 예매 시도 시점',
    `completed_at`   DATETIME          DEFAULT NULL COMMENT '실제 결제 완료 시점',
    `updated_at`     DATETIME          DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '상태 변경 시점',
    `canceled_at`    DATETIME          DEFAULT NULL COMMENT '취소 환불 완료 시점',
    PRIMARY KEY (`payment_id`),
    KEY `FK_payment_reservation` (`reservation_id`),
    KEY `FK_payment_order` (`order_id`),
    CONSTRAINT `FK_payment_order` FOREIGN KEY (`order_id`) REFERENCES `order` (`order_id`),
    CONSTRAINT `FK_payment_reservation` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`reservation_id`)
);

-- 테이블 event 구조 내보내기
CREATE TABLE IF NOT EXISTS `event`
(
    `event_id`    BIGINT       NOT NULL AUTO_INCREMENT COMMENT '이벤트 ID',
    `event_code`  VARCHAR(7)   NOT NULL COMMENT '이벤트 분류 코드(참여형, 당첨형, SNS 공모전)',
    `event_title` VARCHAR(150) NOT NULL COMMENT '이벤트 제목',
    `event_desc`  VARCHAR(255) NOT NULL COMMENT '이벤트 내용',
    `start_date`  DATETIME     NOT NULL COMMENT '시작 기간',
    `end_date`    DATETIME     NOT NULL COMMENT '종료 기간',
    `status`      TINYINT      NOT NULL DEFAULT '0' COMMENT '이벤트 상태(0: 진행중, 1: 종료, 2: 취소)',
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (`event_id`),
    KEY `FK_event_common_code` (`event_code`),
    CONSTRAINT `FK_event_common_code` FOREIGN KEY (`event_code`) REFERENCES `common_code` (`code_id`)
);

-- 테이블 point 구조 내보내기
CREATE TABLE IF NOT EXISTS `point`
(
    `point_id` BIGINT      NOT NULL AUTO_INCREMENT COMMENT '포인트 ID',
    `user_id`  BIGINT      NOT NULL COMMENT '회원 ID',
    `value`    INT         NOT NULL DEFAULT '0',
    `card_num` VARCHAR(16) NOT NULL,
    PRIMARY KEY (`point_id`),
    KEY `FK_point_user` (`user_id`),
    CONSTRAINT `FK_point_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
);

-- 테이블 point_log 구조 내보내기
CREATE TABLE IF NOT EXISTS `point_log`
(
    `point_history_id` BIGINT   NOT NULL AUTO_INCREMENT COMMENT '포인트 히스토리 ID',
    `point_id`         BIGINT   NOT NULL COMMENT '포인트 ID, unique',
    `payment_id`       BIGINT   NOT NULL COMMENT '결제 ID,  unique',
    `change_amount`    INT      NOT NULL,
    `balance_after`    INT               DEFAULT NULL COMMENT '변경 포인트 계산 후 총 포인트',
    `created_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `status`           TINYINT  NOT NULL DEFAULT '0' COMMENT '0: 적립, 1: 차감, 2: 소멸',
    PRIMARY KEY (`point_history_id`),
    KEY `FK_point_log_point` (`point_id`),
    KEY `FK_point_log_payment` (`payment_id`),
    CONSTRAINT `FK_point_log_payment` FOREIGN KEY (`payment_id`) REFERENCES `payment` (`payment_id`),
    CONSTRAINT `FK_point_log_point` FOREIGN KEY (`point_id`) REFERENCES `point` (`point_id`)
);

-- seat
-- 테이블 seat 구조 내보내기
CREATE TABLE IF NOT EXISTS `seat`
(
    `seat_id`    BIGINT   NOT NULL AUTO_INCREMENT COMMENT '좌석 ID',
    `screen_id`  BIGINT   NOT NULL COMMENT '상영관 ID(unique)',
    `row_label`  CHAR(1)  NOT NULL COMMENT '행(unique)',
    `col_no`     CHAR(2)  NOT NULL COMMENT '열(unique)',
    `type`       TINYINT  NOT NULL DEFAULT '0' COMMENT '좌석 구분(0: 일반석, 1: 장애인석)',
    `is_delete`  TINYINT  NOT NULL DEFAULT '0' COMMENT '삭제 여부(0: 삭제안됨, 1: 삭제됨)',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (`seat_id`),
    KEY `FK_seat_screen` (`screen_id`),
    CONSTRAINT `FK_seat_screen` FOREIGN KEY (`screen_id`) REFERENCES `screen` (`screen_id`)
);

-- 테이블 coupon_detail 구조 내보내기
CREATE TABLE IF NOT EXISTS `coupon_detail`
(
    `user_coupon_id` BIGINT   NOT NULL AUTO_INCREMENT COMMENT '회원 쿠폰 ID',
    `user_id`        BIGINT   NOT NULL COMMENT '회원 ID',
    `coupon_id`      BIGINT   NOT NULL COMMENT '쿠폰 ID',
    `issue_date`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `use_at`         DATETIME          DEFAULT NULL COMMENT 'UPDATE NOW',
    `expired_date`   DATETIME          DEFAULT NULL COMMENT '계산필요',
    `status`         TINYINT  NOT NULL DEFAULT '0' COMMENT '0: 발급, 1: 사용, 2: 만료',
    PRIMARY KEY (`user_coupon_id`),
    KEY `FK_coupon_detail_user` (`user_id`),
    KEY `FK_coupon_detail_coupon` (`coupon_id`),
    CONSTRAINT `FK_coupon_detail_coupon` FOREIGN KEY (`coupon_id`) REFERENCES `coupon` (`coupon_id`),
    CONSTRAINT `FK_coupon_detail_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
);

-- 테이블 coupon_log 구조 내보내기
CREATE TABLE IF NOT EXISTS `coupon_log`
(
    `coupon_history` BIGINT   NOT NULL AUTO_INCREMENT COMMENT '쿠폰 히스토리 ID',
    `user_coupon_id` BIGINT   NOT NULL COMMENT '쿠폰 소유 ID',
    `payment_id`     BIGINT   NOT NULL COMMENT '결제 ID',
    `use_date`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`coupon_history`),
    KEY `FK_coupon_log_coupon_detail` (`user_coupon_id`),
    KEY `FK_coupon_log_payment` (`payment_id`),
    CONSTRAINT `FK_coupon_log_coupon_detail` FOREIGN KEY (`user_coupon_id`) REFERENCES `coupon_detail` (`user_coupon_id`),
    CONSTRAINT `FK_coupon_log_payment` FOREIGN KEY (`payment_id`) REFERENCES `payment` (`payment_id`)
);

-- 테이블 discount_policy 구조 내보내기
CREATE TABLE IF NOT EXISTS `discount_policy`
(
    `policy_id`          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '할인 정책 ID',
    `admin_id`           BIGINT      NOT NULL COMMENT '관리자 ID',
    `partner_id`         VARCHAR(7)  NOT NULL COMMENT '공통 코드(카드사)',
    `name`               VARCHAR(50) NOT NULL COMMENT '정책 이름',
    `type`               TINYINT     NOT NULL COMMENT '할인 구분',
    `discount_amount`    INT                  DEFAULT NULL COMMENT '할인 금액',
    `discount_percent`   INT                  DEFAULT NULL COMMENT '할인율',
    `min_price`          INT         NOT NULL COMMENT '적용 최소 금액',
    `max_benefit_amount` INT                  DEFAULT NULL COMMENT '최대 할인 금액',
    `start_date`         DATE        NOT NULL COMMENT '정책 시작일',
    `end_date`           DATE        NOT NULL COMMENT '정책 종료일',
    `created_at`         DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    PRIMARY KEY (`policy_id`),
    KEY `FK_discount_policy_admin` (`admin_id`),
    KEY `FK_discount_policy_common_code` (`partner_id`),
    CONSTRAINT `FK_discount_policy_admin` FOREIGN KEY (`admin_id`) REFERENCES `admin` (`admin_id`),
    CONSTRAINT `FK_discount_policy_common_code` FOREIGN KEY (`partner_id`) REFERENCES `common_code` (`code_id`)
);

-- 테이블 event_part 구조 내보내기
CREATE TABLE IF NOT EXISTS `event_part`
(
    `part_id`    BIGINT   NOT NULL AUTO_INCREMENT COMMENT '이벤트 참여 ID',
    `event_id`   BIGINT   NOT NULL COMMENT '이벤트 ID',
    `user_id`    BIGINT   NOT NULL COMMENT '회원 ID',
    `part_date`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '참여 일자',
    `status`     TINYINT  NOT NULL DEFAULT '0' COMMENT '참여 현황(0: 참여, 1: 당첨, 2: 취소)',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (`part_id`),
    KEY `FK_event_TO_event_part_1` (`event_id`),
    KEY `FK_user_TO_event_part_1` (`user_id`),
    CONSTRAINT `FK_event_TO_event_part_1` FOREIGN KEY (`event_id`) REFERENCES `event` (`event_id`),
    CONSTRAINT `FK_user_TO_event_part_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
);

-- 테이블 favorite 구조 내보내기
CREATE TABLE IF NOT EXISTS `favorite`
(
    `user_id`    BIGINT   NOT NULL COMMENT '회원 ID',
    `movie_id`   BIGINT   NOT NULL COMMENT '영화 ID',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`, `movie_id`) USING BTREE,
    KEY `FK_movie_TO_favorite_1` (`movie_id`),
    CONSTRAINT `FK_movie_TO_favorite_1` FOREIGN KEY (`movie_id`) REFERENCES `movie` (`movie_id`),
    CONSTRAINT `FK_user_TO_favorite_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
);

-- 테이블 membership_coupon_rule 구조 내보내기
CREATE TABLE IF NOT EXISTS `membership_coupon_rule`
(
    `membership_coupon_id` BIGINT     NOT NULL AUTO_INCREMENT COMMENT '맴버십 쿠폰 ID',
    `coupon_id`            BIGINT     NOT NULL COMMENT '쿠폰 ID',
    `membership_id`        INT        NOT NULL COMMENT '맴버십 ID',
    `issue_cycle`          TINYINT    NOT NULL DEFAULT '0' COMMENT '0: 매달, 1: 매년',
    `issue_day`            TINYINT    NOT NULL DEFAULT '1' COMMENT '1: 1일',
    `is_active`            TINYINT(1) NOT NULL DEFAULT '0' COMMENT '0: 사용, 1: 삭제',
    PRIMARY KEY (`membership_coupon_id`),
    KEY `FK_membership_coupon_rule_coupon` (`coupon_id`),
    KEY `FK_membership_coupon_rule_membership_tier` (`membership_id`),
    CONSTRAINT `FK_membership_coupon_rule_coupon` FOREIGN KEY (`coupon_id`) REFERENCES `coupon` (`coupon_id`),
    CONSTRAINT `FK_membership_coupon_rule_membership_tier` FOREIGN KEY (`membership_id`) REFERENCES `membership_tier` (`membership_id`)
);

-- 테이블 payment_discount 구조 내보내기
CREATE TABLE IF NOT EXISTS `payment_discount`
(
    `payment_discount_id` BIGINT     NOT NULL AUTO_INCREMENT COMMENT '결제 단위 할인 ID',
    `payment_id`          BIGINT     NOT NULL COMMENT '결제 ID',
    `benefit_code`        VARCHAR(7) NOT NULL COMMENT '카드',
    `policy_id`           BIGINT              DEFAULT NULL COMMENT '할인 정책 ID',
    `applied_amount`      INT        NOT NULL COMMENT '결제 단계에서 할인 된 금액',
    `created_at`          DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`payment_discount_id`),
    KEY `FK_payment_discount_payment` (`payment_id`),
    KEY `FK_payment_discount_common_code` (`benefit_code`),
    KEY `FK_payment_discount_discount_policy` (`policy_id`),
    CONSTRAINT `FK_payment_discount_common_code` FOREIGN KEY (`benefit_code`) REFERENCES `common_code` (`code_id`),
    CONSTRAINT `FK_payment_discount_discount_policy` FOREIGN KEY (`policy_id`) REFERENCES `discount_policy` (`policy_id`),
    CONSTRAINT `FK_payment_discount_payment` FOREIGN KEY (`payment_id`) REFERENCES `payment` (`payment_id`)
);

-- 테이블 reservation_count 구조 내보내기
CREATE TABLE IF NOT EXISTS `reservation_count`
(
    `reservation_id` BIGINT     NOT NULL COMMENT '예매 ID',
    `age_type`       VARCHAR(7) NOT NULL COMMENT '연령 분류 코드',
    `count`          INT        NOT NULL COMMENT '인원',
    `price`          INT        NOT NULL COMMENT '가격',
    PRIMARY KEY (`reservation_id`, `age_type`) USING BTREE,
    KEY `FK_common_code_TO_reservation_count_1` (`age_type`),
    CONSTRAINT `FK_common_code_TO_reservation_count_1` FOREIGN KEY (`age_type`) REFERENCES `common_code` (`code_id`),
    CONSTRAINT `FK_reservation_TO_reservation_count_1` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`reservation_id`)
);

-- 테이블 reservation_seat 구조 내보내기
CREATE TABLE IF NOT EXISTS `reservation_seat`
(
    `reservation_seat_id` BIGINT   NOT NULL AUTO_INCREMENT COMMENT '예매 좌석 ID',
    `schedule_id`         BIGINT   NOT NULL COMMENT '상영 일정 ID',
    `seat_id`             BIGINT   NOT NULL COMMENT '좌석 ID',
    `created_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    PRIMARY KEY (`reservation_seat_id`),
    KEY `FK_reservation_seat_screen_schedule` (`schedule_id`),
    KEY `FK_reservation_seat_seat` (`seat_id`),
    CONSTRAINT `FK_reservation_seat_screen_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `screen_schedule` (`schedule_id`),
    CONSTRAINT `FK_reservation_seat_seat` FOREIGN KEY (`seat_id`) REFERENCES `seat` (`seat_id`)
);

-- 테이블 reservation_seat_list 구조 내보내기
CREATE TABLE IF NOT EXISTS `reservation_seat_list`
(
    `reservation_id`      BIGINT NOT NULL COMMENT '예매 ID',
    `reservation_seat_id` BIGINT NOT NULL COMMENT '예매 좌석 ID',
    PRIMARY KEY (`reservation_id`, `reservation_seat_id`),
    KEY `FK_reservation_seat_TO_reservation_seat_list_1` (`reservation_seat_id`),
    CONSTRAINT `FK_reservation_seat_TO_reservation_seat_list_1` FOREIGN KEY (`reservation_seat_id`) REFERENCES `reservation_seat` (`reservation_seat_id`),
    CONSTRAINT `FK_reservation_TO_reservation_seat_list_1` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`reservation_id`)
);


-- review
-- 테이블 review 구조 내보내기
CREATE TABLE IF NOT EXISTS `review`
(
    `review_id`     BIGINT       NOT NULL AUTO_INCREMENT COMMENT '후기 ID',
    `movie_id`      BIGINT       NOT NULL COMMENT '영화 ID',
    `schedule_id`   BIGINT       NOT NULL COMMENT '상영 일정 ID',
    `user_id`       BIGINT       NOT NULL COMMENT '회원 ID',
    `review_rating` TINYINT      NOT NULL COMMENT '평점(0~10점)',
    `review_text`   VARCHAR(100) NOT NULL COMMENT '후기 내용',
    `is_delete`     TINYINT      NOT NULL DEFAULT '0' COMMENT '삭제 여부(0: 삭제안됨, 1: 삭제됨)',
    `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일자',
    PRIMARY KEY (`review_id`),
    KEY `FK_review_movie` (`movie_id`),
    KEY `FK_review_screen_schedule` (`schedule_id`),
    KEY `FK_review_user` (`user_id`),
    CONSTRAINT `FK_review_movie` FOREIGN KEY (`movie_id`) REFERENCES `movie` (`movie_id`),
    CONSTRAINT `FK_review_screen_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `screen_schedule` (`schedule_id`),
    CONSTRAINT `FK_review_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
);

-- 테이블 review_like 구조 내보내기
CREATE TABLE IF NOT EXISTS `review_like`
(
    `review_id`  BIGINT   NOT NULL COMMENT '후기 ID',
    `user_id`    BIGINT   NOT NULL COMMENT '회원 ID',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    PRIMARY KEY (`review_id`, `user_id`),
    KEY `FK_user_TO_review_like_1` (`user_id`),
    CONSTRAINT `FK_review_TO_review_like_1` FOREIGN KEY (`review_id`) REFERENCES `review` (`review_id`),
    CONSTRAINT `FK_user_TO_review_like_1` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
);

-- 테이블 ticket_discount 구조 내보내기
CREATE TABLE IF NOT EXISTS `ticket_discount`
(
    `ticket_discount_id`  BIGINT     NOT NULL AUTO_INCREMENT COMMENT '좌석 단위 할인 ID',
    `reservation_seat_id` BIGINT     NOT NULL COMMENT '예매 좌석',
    `benefit_code`        VARCHAR(7) NOT NULL COMMENT '포인트, 쿠폰, 교환권',
    `benefit_id`          BIGINT     NOT NULL COMMENT '종류에 맞는 pk값',
    `applied_amount`      INT        NOT NULL COMMENT '이 티켓에서 할인된 금액',
    `created_at`          DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`ticket_discount_id`),
    KEY `FK_ticket_discount_reservation_seat` (`reservation_seat_id`),
    KEY `FK_ticket_discount_common_code` (`benefit_code`),
    CONSTRAINT `FK_ticket_discount_common_code` FOREIGN KEY (`benefit_code`) REFERENCES `common_code` (`code_id`),
    CONSTRAINT `FK_ticket_discount_reservation_seat` FOREIGN KEY (`reservation_seat_id`) REFERENCES `reservation_seat` (`reservation_seat_id`)
);

-- 테이블 user_voucher 구조 내보내기
CREATE TABLE IF NOT EXISTS `user_voucher`
(
    `user_voucher_id` BIGINT   NOT NULL AUTO_INCREMENT COMMENT '유저 교환권 ID',
    `user_id`         BIGINT   NOT NULL COMMENT '회원 ID',
    `store_item_id`   BIGINT   NOT NULL COMMENT '스토어 상품 ID(교환권만, 쿠폰 X)',
    `issue_date`      DATETIME NOT NULL COMMENT '발급일자',
    `expire_date`     DATETIME          DEFAULT NULL COMMENT '만료일자',
    `status`          TINYINT  NOT NULL DEFAULT '0' COMMENT '상태(0: 발급, 1: 사용, 2: 만료, 3: 취소)',
    PRIMARY KEY (`user_voucher_id`),
    KEY `FK_user_voucher_user` (`user_id`),
    KEY `FK_user_voucher_store_item` (`store_item_id`),
    CONSTRAINT `FK_user_voucher_store_item` FOREIGN KEY (`store_item_id`) REFERENCES `store_item` (`store_item_id`),
    CONSTRAINT `FK_user_voucher_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`)
);

-- 테이블 voucher_log 구조 내보내기
CREATE TABLE IF NOT EXISTS `voucher_log`
(
    `voucher_log_id`  BIGINT   NOT NULL AUTO_INCREMENT COMMENT '내역 ID',
    `user_voucher_id` BIGINT   NOT NULL COMMENT '유저 교환권 ID',
    `status`          TINYINT  NOT NULL COMMENT '사용 분류(0: 발급, 1: 사용, 2: 만료, 3: 취소)',
    `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일자',
    PRIMARY KEY (`voucher_log_id`),
    KEY `FK_voucher_log_user_voucher` (`user_voucher_id`),
    CONSTRAINT `FK_voucher_log_user_voucher` FOREIGN KEY (`user_voucher_id`) REFERENCES `user_voucher` (`user_voucher_id`)
);

