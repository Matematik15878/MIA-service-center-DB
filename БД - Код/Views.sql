-- 1 Представлення, яке містить у собі практичні іспити, що заплановані на сьогоднішній день --
CREATE OR REPLACE VIEW practical_exams_today AS
SELECT
    pe.exam_serial_number,
    pe.time_of_passing,
    a.last_name || ' ' || a.first_name || ' ' || a.middle_name AS full_name,
    pe.applicant_id,
    pe.transport_id,
    pe.inspector_id,
    pe.success_marker,
    pe.category_of_transport
FROM (SELECT * FROM log_of_practical_exams WHERE date_of_passing = CURRENT_DATE) pe
JOIN applicant a ON pe.applicant_id = a.applicant_id;
-- Відкриття та видалення представлення
SELECT * FROM practical_exams_today;
DROP VIEW IF EXISTS practical_exams_today;

-- 2 Представлення, яке містить у собі теоретичні іспити, що заплановані на сьогоднішній день --
CREATE OR REPLACE VIEW theoretical_exams_today AS
SELECT te.exam_serial_number,
       te.time_of_passing,
       a.last_name || ' ' || a.first_name || ' ' || a.middle_name AS full_name,
       te.applicant_id,
       te.inspector_id,
       te.success_marker,
       te.exam_grade
FROM log_of_theoretical_exams te
JOIN applicant a ON te.applicant_id = a.applicant_id
WHERE te.date_of_passing = CURRENT_DATE
ORDER BY te.exam_serial_number;
-- Відкриття та видалення представлення
SELECT * FROM theoretical_exams_today;
DROP VIEW IF EXISTS theoretical_exams_today;

-- 3 Представлення, що містить у собі всі отримані категорії за ліцензіями --
CREATE OR REPLACE VIEW drivers_categories AS
SELECT dl.drivers_license_number,
       dl.last_name || ' ' || dl.first_name || ' ' || dl.middle_name AS full_name,
       rc.category_of_transport,
       rc.type_of_gearbox,
       dl.obtaining_date,
       dl.expiration_date
FROM received_categories rc LEFT JOIN drivers_license dl ON rc.drivers_license_number = dl.drivers_license_number
ORDER BY drivers_license_number;
-- Відкриття та видалення представлення
SELECT * FROM drivers_categories;
DROP VIEW IF EXISTS drivers_categories;

-- 4 Представлення, що містить у собі ліцензії, які треба оновити --
CREATE OR REPLACE VIEW expired_drivers_licenses AS
SELECT dl.drivers_license_number,
       a.last_name || ' ' || a.first_name || ' ' || a.middle_name AS full_name,
       dl.expiration_date
FROM drivers_license dl
JOIN applicant a ON dl.last_name = a.last_name
                 AND dl.first_name = a.first_name
                 AND dl.middle_name = a.middle_name
WHERE dl.expiration_date < CURRENT_DATE;
-- Відкриття та видалення представлення
SELECT * FROM expired_drivers_licenses;
DROP VIEW IF EXISTS expired_drivers_licenses;

-- 5 Представлення тих кандидатів, які не здали практичний іспит, але готові до нього --
CREATE OR REPLACE VIEW applicants_ready_for_practical_exam AS
SELECT a.applicant_id,
       a.last_name || ' ' || a.first_name || ' ' || a.middle_name AS full_name,
       a.phone_number,
       a.amount_of_attempts
FROM applicant a
WHERE a.applicant_id IN (
        SELECT te.applicant_id
        FROM log_of_theoretical_exams te
        WHERE te.success_marker = TRUE
      )
      AND a.applicant_id NOT IN (
        SELECT pe.applicant_id
        FROM log_of_practical_exams pe
        WHERE pe.success_marker = TRUE
);
-- Відкриття та видалення представлення
SELECT * FROM applicants_ready_for_practical_exam;
DROP VIEW IF EXISTS applicants_ready_for_practical_exam;