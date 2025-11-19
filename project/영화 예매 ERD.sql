CREATE TABLE `coupon_detail`
(
    `user_coupon_id` BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '회원 쿠폰 ID',
    `user_id`        BIGINT   NOT NULL COMMENT '회원 ID, unique',
    `coupon_id`      BIGINT   NOT NULL COMMENT '쿠폰 ID, unique',
    `issue_date`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    `use_at`         DATETIME NULL COMMENT 'UPDATE NOW',
    `expired_date`   DATETIME NULL COMMENT '계산필요',
    `status`         TINYINT  NOT NULL DEFAULT 0 COMMENT '0: 발급, 1: 사용, 2: 만료'
);

CREATE TABLE `point_log`
(
    `point_history_id` BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '포인트 히스토리 ID',
    `point_id`         BIGINT   NOT NULL COMMENT '포인트 ID, unique',
    `payment_id`       BIGINT   NOT NULL COMMENT '결제 ID,  unique',
    `change_amount`    INT      NOT NULL,
    `balance_after`    INT      NULL COMMENT '변경 포인트 계산 후 총 포인트',
    `created_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    `status`           TINYINT  NOT NULL DEFAULT 0 COMMENT '0: 적립, 1: 차감, 2: 소멸'
);

CREATE TABLE `membership_coupon_rule`
(
    `membership_coupon_id` BIGINT     NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '맴버십 쿠폰 ID',
    `coupon_id`            BIGINT     NOT NULL COMMENT '쿠폰 ID',
    `membership_id`        INT        NOT NULL COMMENT '맴버십 ID',
    `issue_cycle`          TINYINT    NOT NULL DEFAULT 0 COMMENT '0: 매달, 1: 매년',
    `issue_day`            TINYINT    NOT NULL DEFAULT 1 COMMENT '1: 1일',
    `is_active`            TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0: 사용, 1: 삭제'
);

CREATE TABLE `non_user`
(
    `non_user_id`   BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '비회원 ID',
    `password`      VARCHAR(100) NOT NULL COMMENT 'hashcode',
    `name`          VARCHAR(10)  NOT NULL COMMENT 'GUEST_',
    `phone`         VARCHAR(13)  NOT NULL COMMENT '7일 후 null 처리',
    `birth`         VARCHAR(6)   NOT NULL COMMENT '주민등록번호 앞 6자리, 7일 후  null 처리',
    `is_anonymized` TINYINT      NOT NULL DEFAULT 0 COMMENT '0: 유지, 1: 삭제',
    `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    `deleted_at`    DATETIME     NULL COMMENT '삭제 update시'
);

CREATE TABLE `admin`
(
    `admin_id` BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '관리자 ID',
    `name`     VARCHAR(20) NOT NULL COMMENT '이름'
);

CREATE TABLE `payment`
(
    `payment_id`     BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '결제 ID',
    `reservation_id` BIGINT   NULL COMMENT '예매 ID',
    `order_id`       BIGINT   NULL COMMENT '주문 ID',
    `origin_amount`  INT      NOT NULL COMMENT '할인 전 금액(정가)',
    `discount_total` INT      NOT NULL DEFAULT 0 COMMENT '할인 된 금액 합계',
    `amount`         INT      NOT NULL COMMENT '실제 결제금액',
    `status`         TINYINT  NOT NULL DEFAULT 0 COMMENT '결제 상태 구분 (0: 결제대기, 1: 완료, 2: 취소, 3: 환불)',
    `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '결제 생성 일시 - 예매 시도 시점',
    `completed_at`   DATETIME NULL COMMENT '실제 결제 완료 시점',
    `updated_at`     DATETIME NULL     DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '상태 변경 시점',
    `canceled_at`    DATETIME NULL COMMENT '취소 환불 완료 시점'
);

CREATE TABLE `screen_time`
(
    `screen_time`  VARCHAR(7) NOT NULL COMMENT '상영 시간 분류 코드(조조, 일반, 심야)',
    `start_time`   TIME       NOT NULL COMMENT '시작 시간(09:00:00, 10:00:00, 23:00:00)',
    `end_time`     TIME       NOT NULL COMMENT '종료 시간(10:59:59, 22:59:59, 02:59:59)',
    `adjust_price` INT        NOT NULL COMMENT '가감 가격'
);

CREATE TABLE `reservation`
(
    `reservation_id` BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '예매 ID',
    `schedule_id`    BIGINT      NOT NULL COMMENT '상영 일정 ID',
    `user_id`        BIGINT      NULL COMMENT '회원 ID',
    `non_user_id`    BIGINT      NULL COMMENT '비회원 ID',
    `buyer_name`     VARCHAR(10) NOT NULL COMMENT 'user, non_user 이름',
    `buyer_phone`    VARCHAR(13) NOT NULL COMMENT 'user, non_user 전화번호',
    `buyer_birth`    VARCHAR(6)  NOT NULL COMMENT 'user, non_user 생년월일',
    `price`          INT         NOT NULL COMMENT '예매 가격',
    `status`         TINYINT     NOT NULL DEFAULT 0 COMMENT '예매 상태 구분(0: 결제중, 1: 완료, 2: 취소)',
    `created_at`     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `updated_at`     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '수정일자'
);

CREATE TABLE `coupon`
(
    `coupon_id`           BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '쿠폰 ID',
    `coupon_code`         VARCHAR(7)   NOT NULL COMMENT '쿠폰 분류 코드',
    `coupon_name`         VARCHAR(50)  NOT NULL,
    `comment`             VARCHAR(200) NOT NULL,
    `min_price`           INT          NULL     DEFAULT 0,
    `discount_amount`     INT          NULL COMMENT '할인금액이 값이 있을 시 할인율엔 값이 없어야 한다',
    `discount_rate`       TINYINT      NULL COMMENT '할인율에 값이 있을시 할인금액에는 값이 없어야 한다',
    `max_discount_amount` INT          NULL COMMENT '할인율에 값이 있을시 반드시 값이 있어야한다',
    `start_date`          DATETIME     NOT NULL,
    `end_date`            DATETIME     NULL,
    `valid_day`           INT          NOT NULL COMMENT '기본 일수 30',
    `is_active`           TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '0: 사용, 1: 미사용'
);

CREATE TABLE `reservation_seat_list`
(
    `reservation_id`      BIGINT NOT NULL COMMENT '예매 ID',
    `reservation_seat_id` BIGINT NOT NULL COMMENT '예매 좌석 ID'
);


CREATE TABLE `point`
(
    `point_id` BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '포인트 ID',
    `user_id`  BIGINT      NOT NULL COMMENT '회원 ID',
    `value`    INT         NOT NULL DEFAULT 0,
    `card_num` VARCHAR(16) NOT NULL
);

CREATE TABLE `favorite`
(
    `user_id`    BIGINT   NOT NULL COMMENT '회원 ID',
    `movie_id`   BIGINT   NOT NULL COMMENT '영화 ID',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE `common_code`
(
    `code_id`   VARCHAR(7)  NOT NULL PRIMARY KEY COMMENT '분류 코드 ID',
    `code_type` VARCHAR(3)  NULL COMMENT '대분류',
    `name`      VARCHAR(30) NOT NULL COMMENT '분류명'
);

CREATE TABLE `age_type`
(
    `age_type`     VARCHAR(7) NOT NULL COMMENT '연령 분류 코드(성인, 청소년, 경로, 우대)',
    `adjust_price` INT        NOT NULL COMMENT '가감 가격'
);

CREATE TABLE `screen_type`
(
    `screen_type` VARCHAR(7) NOT NULL COMMENT '상영관 분류 코드(2D, 4D, 리클라이너, 돌비)',
    `price`       INT        NOT NULL COMMENT '가격'
);


CREATE TABLE `employee`
(
    `employee_id` BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '직원 ID',
    `theater`     VARCHAR(7)  NOT NULL COMMENT '지점 분류 코드',
    `admin_id`    BIGINT      NOT NULL COMMENT '관리자 ID',
    `name`        VARCHAR(20) NOT NULL COMMENT '이름(unique)',
    `phone`       VARCHAR(13) NOT NULL COMMENT '전화번호(unique)',
    `type`        TINYINT     NOT NULL DEFAULT 0 COMMENT '구분(0: 일반, 1: 매니저)',
    `is_active`   TINYINT     NOT NULL DEFAULT 0 COMMENT '재직 여부(0: 재직중, 1: 퇴사)',
    `created_at`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `updated_at`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '수정일자'
);

CREATE TABLE `user`
(
    `user_id`          BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '회원 ID',
    `membership_id`    INT          NOT NULL COMMENT '맴버십 ID',
    `name`             VARCHAR(10)  NOT NULL,
    `email`            VARCHAR(100) NOT NULL,
    `password`         VARCHAR(255) NOT NULL COMMENT 'hashcode',
    `birth`            DATE         NOT NULL,
    `carrier_code`     VARCHAR(7)   NOT NULL COMMENT 'KT, SKT, LG',
    `phone`            VARCHAR(13)  NOT NULL,
    `created_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    `updated_at`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '기본 가입일 -> update시 변경',
    `is_delete`        TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '0: 가입, 1: 탈퇴',
    `grade_updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '맴버십 변경 월 저장'
);

CREATE TABLE `payment_discount`
(
    `payment_discount_id` BIGINT     NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '결제 단위 할인 ID',
    `payment_id`          BIGINT     NOT NULL COMMENT '결제 ID',
    `benefit_code`        VARCHAR(7) NOT NULL COMMENT '카드',
    `policy_id`           BIGINT     NULL COMMENT '할인 정책 ID',
    `applied_amount`      INT        NOT NULL COMMENT '결제 단계에서 할인 된 금액',
    `created_at`          DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE `store_item`
(
    `store_item_id`   BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '스토어 상품 ID',
    `store_item_code` VARCHAR(7)   NOT NULL COMMENT '상품 분류(영화 관람권, 팝콘/음료/굿즈 교환권, 할인 쿠폰)',
    `item_name`       VARCHAR(100) NOT NULL COMMENT '상품 이름',
    `item_desc`       VARCHAR(50)  NOT NULL COMMENT '상품 설명',
    `item_limit`      INT          NOT NULL DEFAULT 1 COMMENT '1회 최대 구매 가능 수량(기본 수량 1)',
    `price`           INT          NOT NULL COMMENT '가격',
    `valid_day`       INT          NOT NULL DEFAULT 90 COMMENT '교환권 사용 유효 기간(기본 일수 90)',
    `start_date`      DATE         NOT NULL COMMENT '판매 시작일',
    `end_date`        DATE         NOT NULL COMMENT '판매 종료일',
    `is_active`       TINYINT      NOT NULL DEFAULT 0 COMMENT '판매 여부(0: 판매중, 1: 판매 종료)',
    `payment_type`    TINYINT      NOT NULL DEFAULT 0 COMMENT '결제 방식(0: 현금, 1: 포인트)',
    `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '수정일자'
);

CREATE TABLE `order`
(
    `order_id`      BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '주문 ID',
    `user_id`       BIGINT   NOT NULL COMMENT '회원 ID',
    `store_item_id` BIGINT   NOT NULL COMMENT '스토어 상품 ID',
    `quantity`      INT      NOT NULL COMMENT '구매 수량',
    `unit_price`    INT      NOT NULL COMMENT '구매 금액',
    `price`         INT      NOT NULL COMMENT '총 구매 금액',
    `status`        TINYINT  NOT NULL DEFAULT 0 COMMENT '주문 상태(0: 주문 완료, 1: 주문 취소)',
    `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '수정일자'
);

CREATE TABLE `ticket_discount`
(
    `ticket_discount_id`  BIGINT     NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '좌석 단위 할인 ID',
    `reservation_seat_id` BIGINT     NOT NULL COMMENT '예매 좌석',
    `benefit_code`        VARCHAR(7) NOT NULL COMMENT '포인트, 쿠폰, 교환권',
    `benefit_id`          BIGINT     NOT NULL COMMENT '종류에 맞는 pk값',
    `applied_amount`      INT        NOT NULL COMMENT '이 티켓에서 할인된 금액',
    `created_at`          DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE `screen_schedule`
(
    `schedule_id`  BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '상영 일정 ID',
    `screen_id`    BIGINT   NOT NULL COMMENT '상영관 ID',
    `movie_id`     BIGINT   NOT NULL COMMENT '영화 ID',
    `employee_id`  BIGINT   NOT NULL COMMENT '직원(매니저) ID',
    `running_date` DATE     NOT NULL COMMENT '상영일',
    `start_time`   TIME     NOT NULL COMMENT '상영 시작 시간',
    `end_time`     TIME     NOT NULL COMMENT '상영 종료 시간',
    `price`        INT      NOT NULL COMMENT '가격',
    `is_delete`    TINYINT  NOT NULL DEFAULT 0 COMMENT '삭제 여부(0: 삭제안됨, 1: 삭제됨)',
    `created_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `updated_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '수정일자'
);

CREATE TABLE `membership_tier`
(
    `membership_id`     INT        NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '맴버십 ID',
    `membership_code`   VARCHAR(7) NOT NULL COMMENT 'basic, friend, vip, vvip, mvip',
    `promote_min_point` INT        NOT NULL DEFAULT 0 COMMENT '6000, 12000, 18000, 24000',
    `sort_order`        TINYINT    NOT NULL COMMENT '1,2,3,4,5',
    `is_active`         TINYINT    NOT NULL DEFAULT 0 COMMENT '0 : 미사용중 1 : 사용중'
);

CREATE TABLE `movie`
(
    `movie_id`       BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '영화 ID',
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
    `is_delete`      TINYINT      NOT NULL DEFAULT 0 COMMENT '삭제 여부(0: 삭제안됨, 1: 삭제됨)',
    `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '수정일자'
);

CREATE TABLE `coupon_log`
(
    `coupon_history` BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '쿠폰 히스토리 ID',
    `user_coupon_id` BIGINT   NOT NULL COMMENT '쿠폰 소유 ID, unique',
    `payment_id`     BIGINT   NOT NULL COMMENT '결제 ID,  unique',
    `use_date`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE `review_like`
(
    `review_id`  BIGINT   NOT NULL COMMENT '후기 ID',
    `user_id`    BIGINT   NOT NULL COMMENT '회원 ID',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자'
);


CREATE TABLE `event`
(
    `event_id`    BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '이벤트 ID',
    `event_code`  VARCHAR(7)   NOT NULL COMMENT '이벤트 분류 코드(참여형, 당첨형, SNS 공모전)',
    `event_title` VARCHAR(150) NOT NULL COMMENT '이벤트 제목',
    `event_desc`  VARCHAR(255) NOT NULL COMMENT '이벤트 내용',
    `start_date`  DATETIME     NOT NULL COMMENT '시작 기간',
    `end_date`    DATETIME     NOT NULL COMMENT '종료 기간',
    `status`      TINYINT      NOT NULL DEFAULT 0 COMMENT '이벤트 상태(0: 진행중, 1: 종료, 2: 취소)',
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '수정일자'
);

CREATE TABLE `voucher_log`
(
    `voucher_log_id`  BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '내역 ID',
    `user_voucher_id` BIGINT   NOT NULL COMMENT '유저 교환권 ID',
    `status`          TINYINT  NOT NULL COMMENT '사용 분류(0: 발급, 1: 사용, 2: 만료, 3: 취소)',
    `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자'
);


CREATE TABLE `reservation_seat`
(
    `reservation_seat_id` BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '예매 좌석 ID',
    `schedule_id`         BIGINT   NOT NULL COMMENT '상영 일정 ID',
    `seat_id`             BIGINT   NOT NULL COMMENT '좌석 ID',
    `created_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자'
);

CREATE TABLE `user_voucher`
(
    `user_voucher_id` BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '유저 교환권 ID',
    `user_id`         BIGINT   NOT NULL COMMENT '회원 ID',
    `store_item_id`   BIGINT   NOT NULL COMMENT '스토어 상품 ID(교환권만, 쿠폰 X)',
    `issue_date`      DATETIME NOT NULL COMMENT '발급일자',
    `expire_date`     DATETIME NULL COMMENT '만료일자',
    `status`          TINYINT  NOT NULL DEFAULT 0 COMMENT '상태(0: 발급, 1: 사용, 2: 만료, 3: 취소)'
);

CREATE TABLE `discount_policy`
(
    `policy_id`          BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '할인 정책 ID',
    `admin_id`           BIGINT      NOT NULL COMMENT '관리자 ID',
    `partner_id`         VARCHAR(7)  NOT NULL COMMENT '공통 코드(카드사)',
    `name`               VARCHAR(50) NOT NULL COMMENT '정책 이름',
    `type`               TINYINT     NOT NULL COMMENT '할인 구분',
    `discount_amount`    INT         NULL COMMENT '할인 금액',
    `discount_percent`   INT         NULL COMMENT '할인율',
    `min_price`          INT         NOT NULL COMMENT '적용 최소 금액',
    `max_benefit_amount` INT         NULL COMMENT '최대 할인 금액',
    `start_date`         DATE        NOT NULL COMMENT '정책 시작일',
    `end_date`           DATE        NOT NULL COMMENT '정책 종료일',
    `created_at`         DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자'
);

CREATE TABLE `seat`
(
    `seat_id`    BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '좌석 ID',
    `screen_id`  BIGINT   NOT NULL COMMENT '상영관 ID(unique)',
    `row_label`  CHAR(1)  NOT NULL COMMENT '행(unique)',
    `col_no`     CHAR(2)  NOT NULL COMMENT '열(unique)',
    `type`       TINYINT  NOT NULL DEFAULT 0 COMMENT '좌석 구분(0: 일반석, 1: 장애인석)',
    `is_delete`  TINYINT  NOT NULL DEFAULT 0 COMMENT '삭제 여부(0: 삭제안됨, 1: 삭제됨)',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '수정일자'
);

CREATE TABLE `event_part`
(
    `part_id`    BIGINT   NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '이벤트 참여 ID',
    `event_id`   BIGINT   NOT NULL COMMENT '이벤트 ID',
    `user_id`    BIGINT   NOT NULL COMMENT '회원 ID',
    `part_date`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '참여 일자',
    `status`     TINYINT  NOT NULL DEFAULT 0 COMMENT '참여 현황(0: 참여, 1: 당첨, 2: 취소)',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '수정일자'
);

CREATE TABLE `store_coupon`
(
    `store_item_id` BIGINT NOT NULL COMMENT '스토어 상품 ID',
    `coupon_id`     BIGINT NOT NULL COMMENT '쿠폰 ID'
);

CREATE TABLE `screen`
(
    `screen_id`   BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '상영관 ID',
    `theater`     VARCHAR(7)  NOT NULL COMMENT '지점 분류 코드',
    `screen_type` VARCHAR(7)  NOT NULL COMMENT '상영관 분류 코드',
    `name`        VARCHAR(20) NOT NULL COMMENT '이름',
    `is_delete`   TINYINT     NOT NULL DEFAULT 0 COMMENT '삭제 여부(0: 삭제안됨, 1: 삭제됨)',
    `created_at`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `updated_at`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '수정일자'
);

CREATE TABLE `reservation_count`
(
    `reservation_id` BIGINT     NOT NULL PRIMARY KEY COMMENT '예매 ID',
    `age_type`       VARCHAR(7) NOT NULL COMMENT '연령 분류 코드',
    `count`          INT        NOT NULL COMMENT '인원',
    `price`          INT        NOT NULL COMMENT '가격'
);

CREATE TABLE `user_payment_method`
(
    `user_payment_id` BIGINT      NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '유저 등록 결제 수단 ID',
    `user_id`         BIGINT      NOT NULL COMMENT '회원 ID',
    `card_number`     VARCHAR(40) NULL COMMENT '(마스킹 된) 카드 번호',
    `is_active`       TINYINT     NOT NULL DEFAULT 0 COMMENT '활성화 여부(0: 활성화, 1: 비활성화)',
    `created_at`      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `deleted_at`      DATETIME    NULL COMMENT '비활성화된 일자'
);

CREATE TABLE `review`
(
    `review_id`     BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '후기 ID',
    `movie_id`      BIGINT       NOT NULL COMMENT '영화 ID',
    `schedule_id`   BIGINT       NOT NULL COMMENT '상영 일정 ID',
    `user_id`       BIGINT       NOT NULL COMMENT '회원 ID',
    `review_rating` TINYINT      NOT NULL COMMENT '평점(0~10점)',
    `review_text`   VARCHAR(100) NOT NULL COMMENT '후기 내용',
    `is_delete`     TINYINT      NOT NULL DEFAULT 0 COMMENT '삭제 여부(0: 삭제안됨, 1: 삭제됨)',
    `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT '생성일자',
    `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP() COMMENT '수정일자'
);

ALTER TABLE `screen_time`
    ADD CONSTRAINT `FK_common_code_TO_screen_time_1` FOREIGN KEY (
                                                                  `screen_time`
        )
        REFERENCES `common_code` (
                                  `code_id`
            );

ALTER TABLE `reservation_seat_list`
    ADD CONSTRAINT `FK_reservation_TO_reservation_seat_list_1` FOREIGN KEY (
                                                                            `reservation_id`
        )
        REFERENCES `reservation` (
                                  `reservation_id`
            );

ALTER TABLE `reservation_seat_list`
    ADD CONSTRAINT `FK_reservation_seat_TO_reservation_seat_list_1` FOREIGN KEY (
                                                                                 `reservation_seat_id`
        )
        REFERENCES `reservation_seat` (
                                       `reservation_seat_id`
            );

ALTER TABLE `favorite`
    ADD CONSTRAINT `FK_user_TO_favorite_1` FOREIGN KEY (
                                                        `user_id`
        )
        REFERENCES `user` (
                           `user_id`
            );

ALTER TABLE `favorite`
    ADD CONSTRAINT `FK_movie_TO_favorite_1` FOREIGN KEY (
                                                         `movie_id`
        )
        REFERENCES `movie` (
                            `movie_id`
            );

ALTER TABLE `age_type`
    ADD CONSTRAINT `FK_common_code_TO_age_type_1` FOREIGN KEY (
                                                               `age_type`
        )
        REFERENCES `common_code` (
                                  `code_id`
            );

ALTER TABLE `screen_type`
    ADD CONSTRAINT `FK_common_code_TO_screen_type_1` FOREIGN KEY (
                                                                  `screen_type`
        )
        REFERENCES `common_code` (
                                  `code_id`
            );

ALTER TABLE `review_like`
    ADD CONSTRAINT `FK_review_TO_review_like_1` FOREIGN KEY (
                                                             `review_id`
        )
        REFERENCES `review` (
                             `review_id`
            );

ALTER TABLE `review_like`
    ADD CONSTRAINT `FK_user_TO_review_like_1` FOREIGN KEY (
                                                           `user_id`
        )
        REFERENCES `user` (
                           `user_id`
            );

ALTER TABLE `event_part`
    ADD CONSTRAINT `FK_event_TO_event_part_1` FOREIGN KEY (
                                                           `event_id`
        )
        REFERENCES `event` (
                            `event_id`
            );

ALTER TABLE `event_part`
    ADD CONSTRAINT `FK_user_TO_event_part_1` FOREIGN KEY (
                                                          `user_id`
        )
        REFERENCES `user` (
                           `user_id`
            );

ALTER TABLE `store_coupon`
    ADD CONSTRAINT `FK_store_item_TO_store_coupon_1` FOREIGN KEY (
                                                                  `store_item_id`
        )
        REFERENCES `store_item` (
                                 `store_item_id`
            );

ALTER TABLE `store_coupon`
    ADD CONSTRAINT `FK_coupon_TO_store_coupon_1` FOREIGN KEY (
                                                              `coupon_id`
        )
        REFERENCES `coupon` (
                             `coupon_id`
            );

ALTER TABLE `reservation_count`
    ADD CONSTRAINT `FK_reservation_TO_reservation_count_1` FOREIGN KEY (
                                                                        `reservation_id`
        )
        REFERENCES `reservation` (
                                  `reservation_id`
            );

ALTER TABLE `reservation_count`
    ADD CONSTRAINT `FK_common_code_TO_reservation_count_1` FOREIGN KEY (
                                                                        `age_type`
        )
        REFERENCES `common_code` (
                                  `code_id`
            );

