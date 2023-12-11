START TRANSACTION;

-- Таблица: Студенты
CREATE TABLE IF NOT EXISTS students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    student_name VARCHAR(50) NOT NULL,
    gender VARCHAR(1) NOT NULL,
    birth_date DATE NOT NULL,
    admission_date DATE NOT NULL,
    address VARCHAR(512),
    study_group_id INT NOT NULL
);

-- Таблица: Учебные группы
CREATE TABLE IF NOT EXISTS study_groups (
    study_group_id INT PRIMARY KEY AUTO_INCREMENT,
    group_code VARCHAR(50) NOT NULL,
    course TINYINT NOT NULL,
    year SMALLINT NOT NULL
);

-- Таблица: Дисциплины
CREATE TABLE IF NOT EXISTS disciplines (
    discipline_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    hours_amount SMALLINT NOT NULL
);

-- Таблица: Оценки
CREATE TABLE IF NOT EXISTS grades (
    grade_id INT PRIMARY KEY AUTO_INCREMENT,
    grade TINYINT NOT NULL,
    semester TINYINT NOT NULL,
    student_id INT NOT NULL,
    discipline_id INT NOT NULL
);

-- Ограничения
ALTER TABLE students
    ADD CHECK (gender IN ('m', 'f'));

ALTER TABLE study_groups
    ADD CHECK (course BETWEEN 1 AND 6);

ALTER TABLE study_groups
    ADD CHECK (year BETWEEN 2000 AND 2100);

ALTER TABLE disciplines
    ADD CHECK (hours_amount > 0);

ALTER TABLE grades
    ADD CHECK (grade BETWEEN 1 AND 5);

ALTER TABLE grades
    ADD CHECK (semester BETWEEN 1 AND 12);


-- Внешние ключи
ALTER TABLE students
    ADD FOREIGN KEY (study_group_id) REFERENCES study_groups (study_group_id)
    ON DELETE CASCADE;

ALTER TABLE grades
    ADD FOREIGN KEY (student_id) REFERENCES students (student_id)
    ON DELETE CASCADE;

ALTER TABLE grades
    ADD FOREIGN KEY (discipline_id) REFERENCES disciplines (discipline_id)
    ON DELETE CASCADE;

COMMIT;
