START TRANSACTION;

DROP TABLE IF EXISTS average_grades;
DROP TABLE IF EXISTS grades;
DROP TABLE IF EXISTS disciplines;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS study_groups;

DROP TRIGGER IF EXISTS insert_student_to_average_grades;
DROP TRIGGER IF EXISTS calculate_average_grades_on_insert;
DROP TRIGGER IF EXISTS calculate_average_grades_on_update;

COMMIT;