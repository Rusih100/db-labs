-- Процент обновляемых данных
SET @percent = 0.3;

START TRANSACTION;

UPDATE study_groups
    SET group_code = CONCAT(group_code, '-', 2313)
WHERE RAND() <= @percent;

UPDATE students
    SET address = NULL
WHERE RAND() <= @percent;

UPDATE disciplines
    SET hours_amount = hours_amount * 2
WHERE RAND() <= @percent;

UPDATE grades
    SET grade = 5
WHERE RAND() <= @percent;

COMMIT;