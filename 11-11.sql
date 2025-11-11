CREATE TABLE 개인고객2
(
    고객번호   BIGINT PRIMARY KEY,
    주민등록번호 VARCHAR(14) NOT NULL UNIQUE,
    생년월일   DATE,
    성별     VARCHAR(1) CHECK (성별 IN ('F', 'M')),
    결혼여부   VARCHAR(1) CHECK (결혼여부 IN ('O', 'X'))
);

CREATE TABLE 법인고객2
(
    고객번호   BIGINT PRIMARY KEY,
    법인등록번호 VARCHAR(14) NOT NULL UNIQUE,
    대표자명   VARCHAR(5),
    설립일자   DATE
);

CREATE TABLE 고객2
(
    고객번호   BIGINT PRIMARY KEY,
    고객명    VARCHAR(5) NOT NULL,
    고객구분코드 VARCHAR(2) NOT NULL
);

/* 개인고객 insert 트리거
   trigger는 특정 테이블에 이벤트(insert, update, delete)가 발생되었을 때 처리하고 싶은 업무를 작성한다
   기존 트리거가 있다면 삭제하고 없으면 에러가 터지지 않도록 한다
 */
DROP TRIGGER IF EXISTS tg_insert_개인고객_고객번호2;
DELIMITER $$ -- ;세미콜론의 역할을 $$ 로 변경하겠다

CREATE TRIGGER tg_insert_개인고객_고객번호2 -- create trigger 트리거 이름
    BEFORE INSERT
    ON 개인고객2 -- 시점(before,after), 이벤트 그리고 대상 테이블
    FOR EACH ROW -- 각각의 row마다 실행
BEGIN -- 시작
    DECLARE num INT; -- 변수 선언
    SET num = 0;
    -- 초기화 (값 대입)

    /*
     NEW.고객번호 : 개인고객2 테이블에 insert되려고 하는 새로운 고객번호
     새로운 고객번호가 법인고객2 테이블에 있다면 num변수에 1이 저장이 되고 없다면 num변수에 0이 저장
     */
    SELECT COUNT(1) INTO num FROM 법인고객2 WHERE 고객번호 = NEW.고객번호;

    IF num != 0 THEN -- num값이 0이 아니라는 것은 법인고객2 테이블에 개인고객2에 insert하려는 고객번호가 있다는 뜻
    -- 에러 메세지가 뜨면서 개인고객2 테이블에 insert가 취소
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '법인 고객2에 존재하는 중복된 고객번호입니다.';
    END IF;

END;
$$ -- 끝
DELIMITER ; -- 다시 $$ 에서 ; 세미콜론으로 변경한다

# 개인고객 update 트리거

DROP TRIGGER IF EXISTS tg_update_개인고객_고객번호2;
DELIMITER $$

CREATE TRIGGER tg_update_개인고객_고객번호2
    BEFORE UPDATE
    ON 개인고객2
    FOR EACH ROW
BEGIN
    DECLARE num INT;
    SET num = 0;

    SELECT COUNT(1) INTO num FROM 법인고객2 WHERE 고객번호 = NEW.고객번호;

    IF num != 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '법인 고객2에 존재하는 중복된 고객번호입니다.';
    END IF;

END;
$$
DELIMITER ;

# 법인고객 insert 트리거

DROP TRIGGER IF EXISTS tg_insert_법인고객_고객번호2;
DELIMITER $$

CREATE TRIGGER tg_insert_법인고객_고객번호2
    BEFORE INSERT
    ON 법인고객2
    FOR EACH ROW
BEGIN
    DECLARE num INT;
    SET num = 0;

    SELECT COUNT(1) INTO num FROM 개인고객2 WHERE 고객번호 = NEW.고객번호;

    IF num != 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '개인 고객2에 존재하는 중복된 고객번호입니다.';
    END IF;

END;
$$
DELIMITER ;

# 법인고객 update 트리거

DROP TRIGGER IF EXISTS tg_update_법인고객_고객번호2;
DELIMITER $$

CREATE TRIGGER tg_update_법인고객_고객번호2
    BEFORE UPDATE
    ON 법인고객2
    FOR EACH ROW
BEGIN
    DECLARE num INT;
    SET num = 0;

    SELECT COUNT(1) INTO num FROM 개인고객2 WHERE 고객번호 = NEW.고객번호;

    IF num != 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '개인 고객2에 존재하는 중복된 고객번호입니다.';
    END IF;

END;
$$
DELIMITER ;


INSERT INTO 개인고객2
SET 고객번호   = 1
  , 주민등록번호 = '901010-1770001';

INSERT INTO 고객2
SET 고객번호   = 1
  , 고객명    = '개인고객1'
  , 고객구분코드 = '개인';

INSERT INTO 법인고객2
SET 고객번호   = 2
  , 법인등록번호 = '130111-0006246';

INSERT INTO 고객2
SET 고객번호   = 2
  , 고객명    = '삼성전자'
  , 고객구분코드 = '법인';

INSERT INTO 개인고객2
SET 고객번호   = 2
  , 주민등록번호 = '901011-1770002';

UPDATE 개인고객2
SET 고객번호 = 2
WHERE 고객번호 = 1;

INSERT INTO 법인고객2
SET 고객번호   = 1
  , 법인등록번호 = '130111-0006247';

UPDATE 법인고객2
SET 고객번호 = 1
WHERE 고객번호 = 2;

INSERT INTO 개인고객2
SET 고객번호   = 3
  , 주민등록번호 = '901010-1770002';

INSERT INTO 고객2
SET 고객번호   = 3
  , 고객명    = '개인고객2'
  , 고객구분코드 = '개인';