SHOW VARIABLES LIKE 'event_scheduler';

CREATE TABLE test_delete
(
    id         INT PRIMARY KEY AUTO_INCREMENT,
    msg        VARCHAR(50),
    created_at DATETIME DEFAULT NOW()
);

INSERT INTO test_delete (msg)
VALUES ('테스트 데이터');

# 1분뒤 row 삭제용
CREATE EVENT delete_test_rows
    ON SCHEDULE EVERY 1 MINUTE
    DO
    DELETE
    FROM test_delete
    WHERE created_at < NOW() - INTERVAL 1 MINUTE;


SELECT *
FROM test_delete;

