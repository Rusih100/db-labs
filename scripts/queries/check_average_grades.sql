SELECT
    IF(
        COUNT(*) = COUNT(
            IF(ABS(eg.grade - g.grade) < 0.0001, 1, NULL)
        ),
        'Все записи верны',
        'Не все записи верны'
    ) AS 'Результат проверки'
FROM
    average_grades AS g
    LEFT JOIN (
        SELECT
            student_id,
            ROUND(AVG(grade), 3) AS grade
        FROM grades
        GROUP BY student_id
    ) AS eg
        ON g.student_id = eg.student_id;
