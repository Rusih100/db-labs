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


COMMIT;
