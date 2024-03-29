START TRANSACTION;

DROP TABLE IF EXISTS average_grades;
DROP TABLE IF EXISTS grades;
DROP TABLE IF EXISTS disciplines;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS study_groups;

DROP TRIGGER IF EXISTS insert_student_to_average_grades;
DROP TRIGGER IF EXISTS calculate_average_grades_on_insert;
DROP TRIGGER IF EXISTS calculate_average_grades_on_update;

DROP VIEW IF EXISTS student_grants;
DROP VIEW IF EXISTS disciplines_report;

DROP FUNCTION IF EXISTS RAND_INT;
DROP FUNCTION IF EXISTS RAND_CONSONANT;
DROP FUNCTION IF EXISTS RAND_VOWEL;
DROP FUNCTION IF EXISTS RAND_WORD;

DROP PROCEDURE IF EXISTS GENERATE_STUDY_GROUPS_AND_STUDENTS;
DROP PROCEDURE IF EXISTS GENERATE_STUDENTS_BY_STUDY_GROUPS;
DROP PROCEDURE IF EXISTS GENERATE_DISCIPLINES_AND_GRADES;
DROP PROCEDURE IF EXISTS GENERATE_GRADES;
DROP PROCEDURE IF EXISTS GENERATE_DATA;

DROP PROCEDURE IF EXISTS UPDATE_DATA;

DROP PROCEDURE IF EXISTS GET_TABLES_COUNT;

DROP PROCEDURE IF EXISTS REPORT_STUDY_GRANTS_BY_GROUP;
DROP PROCEDURE IF EXISTS REPORT_DISCIPLINE;

COMMIT;