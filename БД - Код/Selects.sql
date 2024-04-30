-- 1 Виведення усіх інспекторів --
SELECT last_name, first_name, middle_name, phone_number, inspector_id
FROM practical_exam_inspector
UNION
SELECT last_name, first_name, middle_name, phone_number, inspector_id
FROM theoretical_exam_inspector
ORDER BY last_name;

-- 2 Виведення імен тих, хто записаний на теоретичний екзамен 6 січня 24 року --
SELECT lte.exam_serial_number AS exam_number,
       lte.time_of_passing,
       a.last_name || ' ' || a.first_name || ' ' || a.middle_name AS applicant_name
FROM log_of_theoretical_exams lte
JOIN applicant a ON lte.applicant_id = a.applicant_id
WHERE lte.date_of_passing = '2024-01-06';

-- 3 Виведення інформації про право на отримання водійського посвідчення --
SELECT a.last_name || ' ' || a.first_name || ' ' || a.middle_name AS applicant_name,
       a.applicant_id,
       a.phone_number,
       (SELECT mc.ability_to_drive_marker 
       	FROM medical_certificates mc 
       	WHERE mc.person_id = a.applicant_id LIMIT 1
       ) AS ability_to_drive
FROM applicant a
ORDER BY applicant_name;

-- 4 Виводить ті теоретичні екзамени, на які не з'явилися кандидати --
SELECT lte.date_of_passing, lte.time_of_passing, a.last_name, a.first_name, a.middle_name
FROM log_of_theoretical_exams lte
JOIN applicant a ON lte.applicant_id = a.applicant_id
WHERE lte.date_of_passing < CURRENT_DATE
  AND lte.success_marker IS NULL;

-- 5 Виведення отриманих категорій --
SELECT d.last_name,
       d.first_name,
       d.drivers_license_number AS license_number,
       rc.category_of_transport AS category,
       rc.type_of_gearbox AS gearbox
FROM drivers_license d
INNER JOIN received_categories rc ON d.drivers_license_number = rc.drivers_license_number
ORDER BY d.last_name, rc.category_of_transport;

-- 6 Виведення середньої кількості помилок, які ставить інструктор --
SELECT pi.last_name || ' ' || pi.first_name AS inspector_name,
       ROUND(AVG(pe.amount_of_mistakes), 2) AS average_mistakes
FROM practical_exam_inspector pi
INNER JOIN log_of_practical_exams pe ON pi.inspector_id = pe.inspector_id
GROUP BY pi.inspector_id, pi.last_name, pi.first_name;

-- 7 Виведення запланованих практичних іспитів з виведенням категорії --
SELECT 
    lpe.date_of_passing,
    CONCAT(a.last_name, ' ', a.first_name) AS applicant_name,
    a.applicant_id,
    ( SELECT t.category_of_transport
      FROM transport t
      WHERE t.transport_id = lpe.transport_id
    ) AS category_of_transport
FROM applicant a
JOIN log_of_practical_exams lpe ON a.applicant_id = lpe.applicant_id
WHERE lpe.date_of_passing >= CURRENT_DATE AND lpe.amount_of_mistakes IS NULL
ORDER BY lpe.exam_serial_number;

-- 8 Виведення % незарахованих інспектором екзаменів --
SELECT CONCAT(pi.last_name, ' ', pi.first_name),
       COUNT(*) AS total_exams,
       SUM(CASE WHEN lpe.success_marker THEN 0 ELSE 1 END) AS unsuccessful,
       ROUND(SUM(CASE WHEN lpe.success_marker THEN 0 ELSE 1 END) * 100.0 / COUNT(*), 2) AS percentage_u
FROM practical_exam_inspector pi
JOIN log_of_practical_exams lpe ON pi.inspector_id = lpe.inspector_id
GROUP BY pi.inspector_id;

-- 9 Виведення студентів, що здали теоретичний екзамен --
SELECT CONCAT(a.last_name, ' ', a.first_name) AS applicant_name,
       lte.exam_grade
FROM applicant a
JOIN log_of_theoretical_exams lte ON a.applicant_id = lte.applicant_id
WHERE lte.exam_grade >= 18;

-- 10 Виведення загальної кількості проведених інспектором теоретичних іспитів --
SELECT ti.inspector_id,
       CONCAT(ti.last_name, ' ', ti.first_name) as inspector_name,
       COUNT(te.applicant_id) AS examined
FROM theoretical_exam_inspector ti
LEFT JOIN log_of_theoretical_exams te ON ti.inspector_id = te.inspector_id
GROUP BY ti.inspector_id;

-- 10 Виведення загальної кількості проведених інспектором практичних іспитів --
SELECT pi.inspector_id,
       CONCAT(pi.last_name, ' ', pi.first_name) as inspector_name,
       COUNT(pe.applicant_id) AS examined
FROM practical_exam_inspector pi
LEFT JOIN log_of_practical_exams pe ON pi.inspector_id = pe.inspector_id
GROUP BY pi.inspector_id;

-- 11 Виведення кількості транспорту на кожну категорію, які належать СЦ --
SELECT c.category_of_transport, COUNT(t.transport_id) AS total_count
FROM category_of_transport c
LEFT JOIN transport t ON c.category_of_transport = t.category_of_transport
WHERE t.affiliation_marker = TRUE
GROUP BY c.category_of_transport;

-- 11 Виведення кількості транспорту на кожну категорію --
SELECT c.category_of_transport, COUNT(t.transport_id) AS total_count
FROM category_of_transport c
LEFT JOIN transport t ON c.category_of_transport = t.category_of_transport
GROUP BY c.category_of_transport;

-- 12 Виведення тих, хто ліцензію ще не отримав --
SELECT a.applicant_id AS id,
       CONCAT(a.last_name, ' ', a.first_name, ' ', a.middle_name) AS name,
       CASE WHEN mc.ability_to_drive_marker = 't' THEN 'Керувати може'
            ELSE ''
       END AS ability_to_drive
FROM drivers_license d
RIGHT JOIN applicant a ON a.last_name = d.last_name AND a.first_name = d.first_name AND a.middle_name = d.middle_name
INNER JOIN medical_certificates mc ON a.applicant_id = mc.person_id
WHERE d.drivers_license_number IS NULL;

-- 13 Виведення даних про посвідчення, знаючи лише перші 3 символи номеру посвідчення --
SELECT a.applicant_id,
       CONCAT(a.last_name, ' ', a.first_name, ' ', a.middle_name) AS full_name,
       d.drivers_license_number
FROM applicant a
INNER JOIN drivers_license d ON a.last_name = d.last_name AND a.first_name = d.first_name AND a.middle_name = d.middle_name
WHERE d.drivers_license_number LIKE 'OCV%';

-- 14 Виведення тих екзаменаторів, у яких кількість прийнятих практичних іспитів більше за середню --
WITH SuccessfulExams AS (
    SELECT inspector_id, COUNT(*) AS successful_exams_count
    FROM log_of_practical_exams
    WHERE success_marker = TRUE
    GROUP BY inspector_id
), AverageSuccessfulExams AS (
    SELECT AVG(successful_exams_count) AS avg_successful_exams
    FROM SuccessfulExams
)
SELECT pi.last_name, pi.first_name, pi.middle_name, sec.successful_exams_count AS successful_exams, ROUND(ase.avg_successful_exams, 2) AS average
FROM practical_exam_inspector pi
JOIN SuccessfulExams sec ON pi.inspector_id = sec.inspector_id
CROSS JOIN AverageSuccessfulExams ase
WHERE sec.successful_exams_count > ase.avg_successful_exams;

-- 15 Виведення тих, кому в цьому році треба оновити посвідчення --
SELECT CONCAT(a.last_name, ' ', a.first_name, ' ', a.middle_name), a.phone_number, dl.expiration_date
FROM drivers_license dl
JOIN applicant a ON a.first_name = dl.first_name AND a.last_name = dl.last_name AND a.middle_name = dl.middle_name
WHERE EXTRACT(YEAR FROM dl.expiration_date) = EXTRACT(YEAR FROM CURRENT_DATE);

-- 16 Виведення тих інспекторів теоретичного іспиту, у яких є значний досвід (більше 50 прийнятих екзаменів) --
SELECT tei.last_name, tei.first_name, tei.middle_name, tei.inspector_id, exam_count.examined
FROM theoretical_exam_inspector tei
JOIN (
    SELECT inspector_id, COUNT(*) AS examined
    FROM log_of_theoretical_exams
    GROUP BY inspector_id
    HAVING COUNT(*) > 50
) AS exam_count ON tei.inspector_id = exam_count.inspector_id;

-- 17 Виведення тих, хто здавав на посвідчення на вантажівці --
CREATE TEMP TABLE temp_variables AS
SELECT 'Truck' AS type_of_transport;
SELECT a.last_name, a.first_name, a.middle_name, subquery.category_of_transport, tv.type_of_transport
FROM applicant a
JOIN (
    SELECT le.applicant_id, t.category_of_transport, t.purpose_of_transport
    FROM log_of_practical_exams le
    JOIN transport t ON le.transport_id = t.transport_id
) AS subquery ON a.applicant_id = subquery.applicant_id
JOIN temp_variables tv ON subquery.purpose_of_transport = tv.type_of_transport;
DROP TABLE temp_variables;

-- 18 Виведення усіх, хто має групу крові 2+ --
CREATE TEMP TABLE temp_blood_group (group_of_blood VARCHAR(2));
INSERT INTO temp_blood_group VALUES ('2+');
INSERT INTO temp_blood_group VALUES ('4-');
SELECT a.last_name, 
       a.first_name, 
       a.middle_name, 
       tbg.group_of_blood AS blood
FROM applicant a, temp_blood_group tbg
WHERE EXISTS ( SELECT 1
               FROM medical_certificates mc
               WHERE mc.person_id = a.applicant_id
                  AND tbg.group_of_blood = CONCAT(mc.group_of_blood, mc.rhesus_factor));
DROP TABLE temp_blood_group;

-- 19 Виведення машини, на якій проведено найбільше екзаменів --
SELECT t.*, COUNT(lpe.transport_id) AS total_exams
FROM transport t
LEFT JOIN log_of_practical_exams lpe ON t.transport_id = lpe.transport_id
GROUP BY t.transport_id
ORDER BY total_exams DESC
LIMIT 1;

-- 20 Виводить записи на практичний іспит, які так і не було проведено --
SELECT lpe.date_of_passing, lpe.time_of_passing, a.last_name, a.first_name, a.middle_name
FROM log_of_practical_exams lpe
JOIN applicant a ON lpe.applicant_id = a.applicant_id
WHERE lpe.date_of_passing < CURRENT_DATE
  AND lpe.success_marker IS NULL;