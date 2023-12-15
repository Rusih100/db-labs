START TRANSACTION;

CREATE PROCEDURE IF NOT EXISTS GET_TABLES_COUNT()
BEGIN
    -- Переменные для курсора (Для того чтобы-читать таблицу построчно)
    DECLARE done INT DEFAULT FALSE;
    DECLARE table_name_cursor VARCHAR(512) DEFAULT FALSE;
    -- Курсор по именам существующих таблиц в схеме
    DECLARE tables_cursor CURSOR FOR
        SELECT t.TABLE_NAME
        FROM information_schema.TABLES AS t
        WHERE t.TABLE_SCHEMA = 'mysql_labs';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN tables_cursor;

    -- Временная таблица
    CREATE TEMPORARY TABLE IF NOT EXISTS tables_count(
        table_name          VARCHAR(512) NOT NULL,
        rows_count          INT          NOT NULL,
        updated_rows_count  INT          NOT NULL
    );

    -- Динамический запрос
    SET @dynamic_query = 'INSERT INTO tables_count(table_name, rows_count, updated_rows_count) ';
    SET @is_first = TRUE;

    -- Цикл чтения
    tables_loop: LOOP
        FETCH tables_cursor INTO table_name_cursor;
        IF done THEN
            LEAVE tables_loop;
        END IF;

        IF NOT @is_first THEN
            SET @dynamic_query = CONCAT(
                @dynamic_query, 'UNION '
            );
        ELSE
            SET @is_first = FALSE;
        END IF;

        SET @dynamic_query = CONCAT(
            @dynamic_query,
            '',
            'SELECT \'', table_name_cursor, '\', COUNT(*), COUNT(CASE WHEN _created_at <> _updated_at THEN 1 ELSE NULL END) ',
            'FROM ', table_name_cursor, ' '
        );
    END LOOP;
    CLOSE tables_cursor;
    SELECT @dynamic_query;
    PREPARE stmt FROM @dynamic_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT * FROM tables_count;
    DROP TABLE IF EXISTS TABLES_COUNT;
END;

-- Сам запрос
CALL GET_TABLES_COUNT();

DROP PROCEDURE IF EXISTS GET_TABLES_COUNT;

COMMIT;
