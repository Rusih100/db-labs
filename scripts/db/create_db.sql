START TRANSACTION;

# ТАБЛИЦЫ

-- Таблица: Учебные группы
CREATE TABLE IF NOT EXISTS study_groups (
    study_group_id  INT             PRIMARY KEY AUTO_INCREMENT,
    group_code      VARCHAR(50)     NOT NULL,
    course          TINYINT         NOT NULL,
    year            SMALLINT        NOT NULL,

    _created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    _updated_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CHECK (course BETWEEN 1 AND 6),
    CHECK (year BETWEEN 2000 AND 2100)
);

-- Таблица: Студенты
CREATE TABLE IF NOT EXISTS students (
    student_id      INT             PRIMARY KEY AUTO_INCREMENT,
    student_name    VARCHAR(50)     NOT NULL,
    gender          VARCHAR(1)      NOT NULL,
    birth_date      DATE            NOT NULL,
    admission_date  DATE            NOT NULL,
    address         VARCHAR(512),
    study_group_id  INT             NOT NULL,

    _created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    _updated_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CHECK (gender IN ('m', 'f')),

    FOREIGN KEY (study_group_id) REFERENCES study_groups (study_group_id) ON DELETE CASCADE
);

-- Таблица: Дисциплины
CREATE TABLE IF NOT EXISTS disciplines (
    discipline_id   INT             PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    hours_amount    SMALLINT        NOT NULL,

    _created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    _updated_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CHECK (hours_amount > 0)
);

-- Таблица: Оценки
CREATE TABLE IF NOT EXISTS grades (
    grade_id        INT            PRIMARY KEY AUTO_INCREMENT,
    grade           TINYINT        NOT NULL,
    semester        TINYINT        NOT NULL,
    student_id      INT            NOT NULL,
    discipline_id   INT            NOT NULL,

    _created_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    _updated_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CHECK (grade BETWEEN 1 AND 5),
    CHECK (semester BETWEEN 1 AND 12),

    FOREIGN KEY (student_id) REFERENCES students (student_id) ON DELETE CASCADE,
    FOREIGN KEY (discipline_id) REFERENCES disciplines (discipline_id) ON DELETE CASCADE,

    INDEX (student_id)
);

-- Таблица для хранения средних оценок
CREATE TABLE IF NOT EXISTS average_grades (
    student_id      INT            PRIMARY KEY,
    grade           FLOAT,

    _created_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    _updated_at     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CHECK (grade BETWEEN 1 AND 5),

    FOREIGN KEY (student_id) REFERENCES students (student_id) ON DELETE CASCADE
);


# ТРИГЕРЫ

-- Тригер на добавление ученика в таблицу средних оценок
CREATE TRIGGER IF NOT EXISTS insert_student_to_average_grades
AFTER INSERT ON students
FOR EACH ROW
BEGIN
    INSERT INTO average_grades(student_id)
    VALUES (NEW.student_id);
END;

-- Тригер на обновление средних оценок при вставке в grades
CREATE TRIGGER IF NOT EXISTS calculate_average_grades_on_insert
AFTER INSERT ON grades
FOR EACH ROW
BEGIN
    UPDATE average_grades AS ag
        SET grade = (
            SELECT
                ROUND(AVG(g.grade), 3)
            FROM grades AS g
            WHERE g.student_id = NEW.student_id
        )
    WHERE ag.student_id = NEW.student_id;
END;

-- Тригер на обновление средних оценок при обновлении grades
CREATE TRIGGER IF NOT EXISTS calculate_average_grades_on_update
AFTER UPDATE ON grades
FOR EACH ROW
BEGIN
    UPDATE average_grades AS ag
        SET grade = (
            SELECT
                ROUND(AVG(g.grade), 3)
            FROM grades AS g
            WHERE g.student_id = NEW.student_id
        )
    WHERE ag.student_id = NEW.student_id;
END;


# ПРЕДСТАВЛЕНИЯ

-- Студенты на стипендию
CREATE OR REPLACE VIEW student_grants AS
    SELECT
        g.student_id AS student_id,
        s.student_name AS student_name,
        s.gender AS gender,
        s.birth_date AS birth_date,
        s.admission_date AS admission_date,
        s.address AS address,
        s.study_group_id AS study_group_id
    FROM
        grades AS g
        JOIN students AS s
            ON g.student_id = s.student_id
    GROUP BY
        student_id
    HAVING MIN(g.grade) > 3;


# ПРОЦЕДУРЫ

# БАЗОВЫЕ ПРОЦЕДУРЫ ГЕНЕРАЦИИ СЛУЧАЙНЫХ ДАННЫХ

-- Случайное целое число в пределах
CREATE FUNCTION IF NOT EXISTS RAND_INT(start_value INT, end_value INT)
    RETURNS INT
BEGIN
    DECLARE num INT;
    SET num = ROUND(
        RAND() * (end_value - start_value) + start_value
    );
    RETURN num;
END;

-- Случайная согласная
CREATE FUNCTION IF NOT EXISTS RAND_CONSONANT() RETURNS VARCHAR(1)
BEGIN
    DECLARE all_consonants VARCHAR(21) DEFAULT 'бвгджзйклмнпрстфхцчшщ';
    DECLARE consonant VARCHAR(1);
    SET consonant = SUBSTRING(
        all_consonants,
        RAND_INT(1, 21),
        1
    );
    RETURN consonant;
END;

-- Случайная гласная
CREATE FUNCTION IF NOT EXISTS RAND_VOWEL() RETURNS VARCHAR(1)
BEGIN
    DECLARE all_vowels VARCHAR(9) DEFAULT 'аеиоуыэюя';
    DECLARE vowel CHAR;
    SET vowel = SUBSTRING(
        all_vowels,
        RAND_INT(1, 9),
        1
    );
    RETURN vowel;
END;

-- Случайное слово
CREATE FUNCTION IF NOT EXISTS RAND_WORD(length INT) RETURNS TEXT
BEGIN
    DECLARE word TEXT DEFAULT '';
    DECLARE i INT DEFAULT 0;
    DECLARE is_consonant BOOLEAN DEFAULT true;
    WHILE i < length DO
        SET word = CONCAT(
            word,
            IF(
                is_consonant,
                RAND_CONSONANT(),
                RAND_VOWEL()
            )
        );
        IF (i = 0) THEN
            SET word = UPPER(word);
        END IF;

        SET is_consonant = NOT is_consonant;
        SET i = i + 1;
    END WHILE;
    RETURN word;
END;

# ПРОЦЕДУРЫ ГЕНЕРАЦИИ СЛУЧАЙНЫХ ДАННЫХ СО ВСТАВКОЙ В ТАБЛИЦУ

-- Генерация студентов. привязанных к учебным группам
CREATE PROCEDURE IF NOT EXISTS GENERATE_STUDENTS_BY_STUDY_GROUPS(
    IN _study_group_id INT,
    IN rows_number_min INT,
    IN rows_number_max INT,
    IN students_limit INT
)
BEGIN
    DECLARE i INT;
    DECLARE row_count INT;

    SET i = (SELECT COUNT(student_id) FROM students) + 1;
    SET row_count = i + RAND_INT(rows_number_min, rows_number_max);

    WHILE (i < row_count AND i < students_limit) DO
        INSERT INTO
            students(student_name, gender, birth_date, admission_date, address, study_group_id)
        SELECT
            CONCAT(
                RAND_WORD(RAND_INT(10, 40)), ' ',
                RAND_WORD(1), '.',
                RAND_WORD(1), '.'
            ) AS student_name,
            IF (RAND_INT(0, 1) = 1, 'm', 'f') AS gender,
            STR_TO_DATE(
                CONCAT(
                    RAND_INT(1, 28), '-',
                    RAND_INT(1, 12), '-',
                    sg.year - sg.course - 17
                ), '%d-%m-%Y'
            ) AS birth_date,
            STR_TO_DATE(
                CONCAT(
                    '01-09-', sg.year - sg.course + 1
                ), '%d-%m-%Y'
            ) AS admission_date,
             RAND_WORD(RAND_INT(30, 90)) AS address,
             _study_group_id AS study_group_id
        FROM
            study_groups AS sg
        WHERE sg.study_group_id = _study_group_id;
        SET i = i + 1;
    END WHILE;
END;

-- Генерация учебных групп и студентов
CREATE PROCEDURE IF NOT EXISTS GENERATE_STUDY_GROUPS_AND_STUDENTS(
    IN rows_number_min INT,
    IN rows_number_max INT,
    IN study_groups_limit INT,
    IN students_limit INT
)
BEGIN
    DECLARE i INT;
    DECLARE row_count INT;
    DECLARE id INT;

    SET i = (SELECT COUNT(study_group_id) FROM study_groups) + 1;
    SET row_count = i + RAND_INT(rows_number_min, rows_number_max);

    WHILE (i < row_count AND i < study_groups_limit) DO
        -- Генерируем случайную учебную группу
        INSERT INTO study_groups(group_code, course, year)
        SELECT
            CONCAT(
                UPPER(RAND_WORD(4)),
                '-',
                RAND_INT(100, 900)
            ) AS group_code,
            RAND_INT(1, 6) AS course,
           2023 AS year;

        -- Получаем id вставленной записи и для нее генерируем студентов
        SET id = (SELECT MAX(study_group_id) FROM study_groups);
        CALL GENERATE_STUDENTS_BY_STUDY_GROUPS(
            id, rows_number_min, rows_number_max, students_limit
         );
        SET i = i + 1;
    END WHILE;
END;

-- Генерация оценок, привязанных к дисциплине
CREATE PROCEDURE IF NOT EXISTS GENERATE_GRADES(IN _discipline_id INT)
BEGIN
    INSERT INTO grades(grade, semester, student_id, discipline_id)
    SELECT
        RAND_INT(2, 5) AS grade,
        (sg.course * 2) AS semester,
        s.student_id AS student_id,
        _discipline_id AS discipline_id
    FROM
        students AS s
        JOIN study_groups AS sg USING (study_group_id);
END;

-- Генерация дисциплин и оценок
CREATE PROCEDURE IF NOT EXISTS GENERATE_DISCIPLINES_AND_GRADES(
    IN rows_number_min INT,
    IN rows_number_max INT,
    IN disciplines_limit INT
)
BEGIN
    DECLARE i INT;
    DECLARE row_count INT;
    DECLARE id INT;

    SET i = (SELECT COUNT(discipline_id) FROM disciplines) + 1;
    SET row_count = i + RAND_INT(rows_number_min, rows_number_max);

    WHILE (i < row_count AND i < disciplines_limit) DO
        -- Генерируем случайную дисциплину
        INSERT INTO disciplines(name, hours_amount)
        SELECT
            RAND_WORD(RAND_INT(30, 90)) AS name,
            RAND_INT(30, 300) AS hours_amount;

        -- Добавляем оценки по данной дисциплине всем студентам
        SET id = (SELECT MAX(discipline_id) FROM disciplines);
        CALL GENERATE_GRADES(id);
        SET i = i + 1;
    END WHILE;
END;

-- Общая процедура генерации данных в таблицу
CREATE PROCEDURE IF NOT EXISTS GENERATE_DATA(
    IN rows_number_min INT,
    IN rows_number_max INT,
    IN study_groups_limit INT,
    IN students_limit INT,
    IN disciplines_limit INT
)
BEGIN
    CALL GENERATE_STUDY_GROUPS_AND_STUDENTS(
        rows_number_min, rows_number_max, study_groups_limit, students_limit
    );
    CALL GENERATE_DISCIPLINES_AND_GRADES(
        rows_number_min, rows_number_max, disciplines_limit
    );
END;

# ПРОЦЕДУРЫ ОБНОВЛЕНИЯ ДАННЫХ

-- Обновление случайного процента от всех данных
CREATE PROCEDURE IF NOT EXISTS UPDATE_DATA(
    IN percent FLOAT
)
BEGIN
    UPDATE study_groups
        SET group_code = CONCAT(group_code, '-', 2313)
    WHERE RAND() <= percent;

    UPDATE students
        SET address = NULL
    WHERE RAND() <= percent;

    UPDATE disciplines
        SET hours_amount = hours_amount * 2
    WHERE RAND() <= percent;

    UPDATE grades
        SET grade = 5
    WHERE RAND() <= percent;
END;

# ИНФОРМАЦИОННЫЕ ПРОЦЕДУРЫ

-- Процедура для получения количества всех записей и количества обновленных записей во всех таблицах
CREATE PROCEDURE IF NOT EXISTS GET_TABLES_COUNT()
BEGIN
    -- Переменные для курсора (Для того чтобы-читать таблицу построчно)
    DECLARE done INT DEFAULT FALSE;
    DECLARE table_name_cursor VARCHAR(512) DEFAULT FALSE;

    -- Курсор по именам существующих таблиц в схеме
    DECLARE tables_cursor CURSOR FOR
        SELECT t.TABLE_NAME
        FROM information_schema.TABLES AS t
        WHERE
            t.TABLE_SCHEMA = 'mysql_labs' AND
            t.TABLE_TYPE = 'BASE TABLE';

    -- Обработка ошибок курсора
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Временная таблица
    CREATE TEMPORARY TABLE IF NOT EXISTS tables_count(
        table_name          VARCHAR(512) NOT NULL,
        rows_count          INT          NOT NULL,
        updated_rows_count  INT          NOT NULL
    );

    -- Основа динамического запроса
    SET @dynamic_query = 'INSERT INTO tables_count(table_name, rows_count, updated_rows_count) ';
    SET @is_first = TRUE;

    -- Цикл чтения
    OPEN tables_cursor;
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

COMMIT;
