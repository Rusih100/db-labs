##### Cекция настроек #####

-- Пределы количества генерируемых записей
SET @rows_number_min = 10;
SET @rows_number_max = 25;

-- Максимальное число записей
SET @study_groups_limit = 10;
SET @disciplines_limit = 10;
SET @students_limit = 1000;

-- Даты
SET @current_year = 2023;

-- Оценки
SET @grade_min = 3;
SET @grade_max = 5;

###########################


START TRANSACTION;

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

-- Генерация студентов. привязанных к учебным группам
CREATE PROCEDURE IF NOT EXISTS GENERATE_STUDENTS_BY_STUDY_GROUPS(IN _study_group_id INT)
BEGIN
    DECLARE i INT;
    DECLARE row_count INT;

    SET i = (SELECT COUNT(student_id) FROM students) + 1;
    SET row_count = i + RAND_INT(@rows_number_min, @rows_number_max);

    WHILE (i < row_count AND i < @students_limit) DO
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
CREATE PROCEDURE IF NOT EXISTS GENERATE_STUDY_GROUPS_AND_STUDENTS()
BEGIN
    DECLARE i INT;
    DECLARE row_count INT;
    DECLARE id INT;

    SET i = (SELECT COUNT(study_group_id) FROM study_groups) + 1;
    SET row_count = i + RAND_INT(@rows_number_min, @rows_number_max);

    WHILE (i < row_count AND i < @study_groups_limit) DO
        -- Генерируем случайную учебную группу
        INSERT INTO study_groups(group_code, course, year)
        SELECT
            CONCAT(
                UPPER(RAND_WORD(4)),
                '-',
                RAND_INT(100, 900)
            ) AS group_code,
            RAND_INT(1, 6) AS course,
           @current_year AS year;

        -- Получаем id вставленной записи и для нее генерируем студентов
        SET id = (SELECT MAX(study_group_id) FROM study_groups);
        CALL GENERATE_STUDENTS_BY_STUDY_GROUPS(id);

        SET i = i + 1;
    END WHILE;
END;

-- Генерация оценок, привязанных к дисциплине
CREATE PROCEDURE IF NOT EXISTS GENERATE_GRADES(IN _discipline_id INT)
BEGIN
    INSERT INTO grades(grade, semester, student_id, discipline_id)
    SELECT
        RAND_INT(@grade_min, @grade_max) AS grade,
        (sg.course * 2) AS semester,
        s.student_id AS student_id,
        _discipline_id AS discipline_id
    FROM
        students AS s
        JOIN study_groups AS sg USING (study_group_id);
END;

-- Генерация дисциплин и оценок
CREATE PROCEDURE IF NOT EXISTS GENERATE_DISCIPLINES_AND_GRADES()
BEGIN
    DECLARE i INT;
    DECLARE row_count INT;
    DECLARE id INT;

    SET i = (SELECT COUNT(discipline_id) FROM disciplines) + 1;
    SET row_count = i + RAND_INT(@rows_number_min, @rows_number_max);

    WHILE (i < row_count AND i < @disciplines_limit) DO
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


CALL GENERATE_STUDY_GROUPS_AND_STUDENTS();
CALL GENERATE_DISCIPLINES_AND_GRADES();

DROP FUNCTION IF EXISTS RAND_INT;
DROP FUNCTION IF EXISTS RAND_CONSONANT;
DROP FUNCTION IF EXISTS RAND_VOWEL;
DROP FUNCTION IF EXISTS RAND_WORD;

DROP PROCEDURE IF EXISTS GENERATE_STUDY_GROUPS_AND_STUDENTS;
DROP PROCEDURE IF EXISTS GENERATE_STUDENTS_BY_STUDY_GROUPS;
DROP PROCEDURE IF EXISTS GENERATE_DISCIPLINES_AND_GRADES;
DROP PROCEDURE IF EXISTS GENERATE_GRADES;

COMMIT;