START TRANSACTION;
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE study_groups;
TRUNCATE TABLE students;
TRUNCATE TABLE grades;
TRUNCATE TABLE disciplines;

ALTER TABLE study_groups AUTO_INCREMENT = 0;
ALTER TABLE students AUTO_INCREMENT = 0;
ALTER TABLE grades AUTO_INCREMENT = 0;
ALTER TABLE disciplines AUTO_INCREMENT = 0;

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;