INSERT INTO membership_tier
    (membership_code, promote_min_point, sort_order)
VALUES ('00701', 0, 1),
       ('00702', 6000, 2),
       ('00703', 12000, 3),
       ('00704', 18000, 4),
       ('00705', 24000, 5);

INSERT INTO coupon
(coupon_code, coupon_name, comment, min_price, discount_type, discount_value,
 max_discount_amount, valid_day, fixed_expire_date)
VALUES ('01002', '신규가입 3천원 할인', '신규 회원 대상 1회 발급 쿠폰',
        8000, 1, 3000, NULL, 30, NULL),
       ('01003', '생일 기념 5천원 할인', '생일 당월 1회 사용 가능',
        12000, 1, 5000, NULL, 30, NULL),
       ('01004', 'Friends 등급 월간 할인 쿠폰', 'Friends등급 월간 할인 쿠폰',
        10000, 1, 3000, NULL, 30, NULL),
       ('01004', 'VIP 등급 월간 할인 쿠폰', 'VIP등급 월간 할인 쿠폰',
        10000, 1, 3000, NULL, 30, NULL),
       ('01004', 'VVIP 등급 월간 할인 쿠폰', 'VVIP등급 월간 할인 쿠폰',
        10000, 1, 4000, NULL, 30, NULL),
       ('01004', 'MVIP 등급 월간 할인 쿠폰', 'MVIP등급 월간 할인 쿠폰',
        10000, 1, 5000, NULL, 30, NULL),
       ('01001', '수요일 20% 할인 쿠폰', '매주 수요일 영화 관람 20% 할인',
        0, 0, 20, 4000, 5, NULL),
       ('01003', '블랙프라이데이 30% 할인', '11월 1일~11월 28일 한정 할인',
        0, 0, 0, 10000, 30, '2025-11-28');

INSERT INTO membership_coupon_rule
    (coupon_id, membership_id)
VALUES (3, 2),
       (4, 3),
       (5, 4),
       (6, 5);

INSERT INTO screen_type
    (screen_type, price)
VALUES ('00101', 15000),
       ('00102', 19000),
       ('00103', 15000),
       ('00104', 20000);

INSERT INTO screen_time
    (screen_time, start_time, end_time, adjust_price)
VALUES ('00301', '06:00:00', '10:59:59', 4000),
       ('00302', '11:00:00', '22:59:59', 0),
       ('00303', '23:00:00', '02:59:59', 4000);

INSERT INTO screen_type
    (screen_type, price)
VALUES ('00201', 0),
       ('00202', 3000),
       ('00203', 7000),
       ('00204', 7000);

INSERT INTO admin
    (name)
VALUES ('김나현'),
       ('김주현'),
       ('서하빈'),
       ('윤소연');








