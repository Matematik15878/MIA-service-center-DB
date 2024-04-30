-- 1 Виводить отримані категорії --
CREATE OR REPLACE FUNCTION get_license_categories()
RETURNS TABLE (full_name TEXT, categories TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT dl.last_name || ' ' || dl.first_name || ' ' || dl.middle_name AS full_name,
           STRING_AGG(rc.category_of_transport, ', ') AS categories
    FROM drivers_license dl
    LEFT JOIN received_categories rc ON dl.drivers_license_number = rc.drivers_license_number
    GROUP BY dl.last_name, dl.first_name, dl.middle_name
    ORDER BY dl.last_name, dl.first_name, dl.middle_name;
END;
$$;
-- Виведення категорій
SELECT * FROM get_license_categories();
-- Видалення функції
DROP FUNCTION get_license_categories;

-- 2 Додання водійського посвідчення і отриманої категорії --
CREATE OR REPLACE PROCEDURE add_license_and_category(
    in_drivers_license_number VARCHAR(9),
    in_applicant_id VARCHAR(10),
    in_obtaining_date DATE,
    in_validity_years INTEGER,
    in_category_of_transport VARCHAR(2),
    in_type_of_gearbox varchar(2))
AS $$ DECLARE v_expiration_date DATE;
BEGIN
    v_expiration_date := in_obtaining_date + INTERVAL '1 YEAR' * in_validity_years;
    INSERT INTO drivers_license (drivers_license_number, last_name, first_name, middle_name, obtaining_date, expiration_date)
    SELECT in_drivers_license_number,
           a.last_name,
           a.first_name,
           a.middle_name,
           in_obtaining_date,
           v_expiration_date
    FROM applicant a
    WHERE a.applicant_id = in_applicant_id
    ON CONFLICT (drivers_license_number) DO NOTHING;
    INSERT INTO received_categories (category_of_transport, drivers_license_number, type_of_gearbox)
    VALUES (in_category_of_transport, in_drivers_license_number, in_type_of_gearbox)
    ON CONFLICT (category_of_transport, drivers_license_number) DO NOTHING;
END;
$$ LANGUAGE plpgsql;
-- Видалення процедури
DROP PROCEDURE add_license_and_category;
-- Приклад роботи
SELECT * FROM get_license_categories();
DELETE FROM drivers_license WHERE drivers_license_number = 'IEC746207';
SELECT * FROM get_license_categories();
CALL add_license_and_category('IEC746207', '1Q6LHSY9F6', '2023-10-16', 30, 'A', 'MT');
CALL add_license_and_category('IEC746207', '1Q6LHSY9F6', '2024-01-03', 30, 'B', 'AT');
SELECT * FROM get_license_categories();
CALL add_license_and_category('IEC746207', '1Q6LHSY9F6', '2024-01-03', 30, 'T', 'AT');

-- 3 Виводить людей, які здали хоча б n іспитів --
CREATE OR REPLACE FUNCTION get_applicants_with_n_successful_exams(n INTEGER) 
RETURNS TABLE (
    ID VARCHAR(10),
    full_name TEXT, 
    successful_exams INTEGER
)
AS $$
BEGIN 
    RETURN QUERY
    SELECT a.applicant_id AS ID,
       CONCAT(a.last_name, ' ', a.first_name, ' ', a.middle_name) AS full_name,
       CAST(ij.successful_exam_count AS INTEGER) AS successful_exams
    FROM applicant a
    INNER JOIN (
        SELECT pe.applicant_id, COUNT(pe.exam_serial_number) AS successful_exam_count
        FROM log_of_practical_exams pe
        WHERE pe.success_marker = TRUE
        GROUP BY pe.applicant_id
        HAVING COUNT(pe.exam_serial_number) >= n
    ) AS ij ON a.applicant_id = ij.applicant_id;
END;
$$ LANGUAGE plpgsql;
-- Виведення результату
SELECT * FROM get_applicants_with_n_successful_exams(2);
-- Видалення функції
DROP FUNCTION get_applicants_with_n_successful_exams;

-- 4 Перевіряє, чи вільний інспектор практичного іспиту в заданий час --
CREATE OR REPLACE FUNCTION is_practical_inspector_available(p_inspector_id VARCHAR(4), p_exam_date DATE, p_exam_time TIME)
RETURNS BOOLEAN AS $$
DECLARE temp_start_time TIME;
        temp_end_time TIME;
        marker BOOLEAN;
BEGIN
    temp_start_time := p_exam_time - INTERVAL '20 minutes';
    temp_end_time := p_exam_time + INTERVAL '20 minutes';
    SELECT EXISTS (
        SELECT 1
            FROM log_of_practical_exams lpe
            WHERE lpe.date_of_passing = p_exam_date 
                AND lpe.time_of_passing BETWEEN temp_start_time AND temp_end_time
                AND lpe.inspector_id = p_inspector_id
    ) INTO marker;
    RETURN NOT marker;
END;
$$ LANGUAGE plpgsql;
-- Перевірка, чи зайнятий інспектор 6 січня о 16:25 
SELECT is_practical_inspector_available('34CD', '2024-01-06', '16:25');
-- Перевірка, чи зайнятий інспектор 6 січня о 16:10 
SELECT is_practical_inspector_available('34CD', '2024-01-06', '16:10');
-- Видалення функції 
DROP FUNCTION is_practical_inspector_available;

-- 5 Перевіряє, чи є вільні місця для здачі теоретичного іспиту в заданий час --
CREATE OR REPLACE FUNCTION is_theoretical_inspector_available(p_exam_date DATE, p_exam_time TIME)
RETURNS BOOLEAN AS $$
DECLARE temp_start_time TIME;
        temp_end_time TIME;
        amount INTEGER;
BEGIN
    temp_start_time := p_exam_time - INTERVAL '20 minutes';
    temp_end_time := p_exam_time + INTERVAL '20 minutes';
    SELECT COUNT(*)
    INTO amount
    FROM log_of_theoretical_exams lte
    WHERE lte.date_of_passing = p_exam_date 
        AND lte.time_of_passing BETWEEN temp_start_time AND temp_end_time;
    RETURN amount < 21;
END;
$$ LANGUAGE plpgsql;
-- Перевірка, чи зайнятий інспектор 6 січня о 16:25 
SELECT is_theoretical_inspector_available('2023-08-10', '13:25');
-- Видалення функції 
DROP FUNCTION is_theoretical_inspector_available;

-- 6 Перевіряє, чи вільний транспорт практичного іспиту в заданий час --
CREATE OR REPLACE FUNCTION is_transport_available(p_transport_id VARCHAR(4), p_exam_date DATE, p_exam_time TIME)
RETURNS BOOLEAN AS $$
DECLARE temp_start_time TIME;
        temp_end_time TIME;
        marker BOOLEAN;
BEGIN
    temp_start_time := p_exam_time - INTERVAL '20 minutes';
    temp_end_time := p_exam_time + INTERVAL '20 minutes';
    SELECT EXISTS (
        SELECT 1
            FROM log_of_practical_exams lpe
            WHERE lpe.date_of_passing = p_exam_date 
                AND lpe.time_of_passing BETWEEN temp_start_time AND temp_end_time
                AND lpe.transport_id = p_transport_id
    ) INTO marker;
    RETURN NOT marker;
END;
$$ LANGUAGE plpgsql;
-- Перевірка, чи зайнятий транспорт 6 січня о 16:25 
SELECT is_transport_available('Q7R8', '2024-01-06', '16:25');
-- Перевірка, чи зайнятий транспорт 6 січня о 16:10 
SELECT is_transport_available('Q7R8', '2024-01-06', '16:10');
-- Видалення функції 
DROP FUNCTION is_transport_available;

-- 7 Вставка практичного іспиту--
CREATE OR REPLACE PROCEDURE insert_practical_exam(
    p_date DATE, 
    p_time TIME, 
    p_transport_id VARCHAR(4), 
    p_inspector_id VARCHAR(4), 
    p_applicant_id VARCHAR(10))
AS $$ DECLARE v_category_of_transport VARCHAR(2);
BEGIN
    IF NOT is_practical_inspector_available(p_inspector_id, p_date, p_time) THEN 
        RAISE EXCEPTION 'This inspector is not available!';
    ELSIF NOT is_transport_available(p_transport_id, p_date, p_time) THEN
        RAISE EXCEPTION 'This trasport is not available!';
    ELSE SELECT category_of_transport INTO v_category_of_transport FROM transport WHERE transport_id = p_transport_id;
         INSERT INTO log_of_practical_exams (date_of_passing, time_of_passing, transport_id, inspector_id, applicant_id, success_marker, amount_of_mistakes, category_of_transport)
         VALUES (p_date, p_time, p_transport_id, p_inspector_id, p_applicant_id, NULL, NULL, v_category_of_transport);
         RAISE NOTICE 'Inserted!';
    END IF;
END;
$$ LANGUAGE plpgsql;
-- Вставка практичного іспиту, коли зайнятий інспектор
CALL insert_practical_exam('2024-01-06', '16:10', 'Q7R8', '34CD', 'VXQ9CD0AE1');
-- Вставка практичного іспиту, коли зайнята машина
CALL insert_practical_exam('2024-01-02', '13:05', 'Q7R8', '34CD', 'VXQ9CD0AE1');
-- Вставка практичного іспиту, коли кандидат не здав теорію
CALL insert_practical_exam('2024-01-06', '17:00', 'Q7R8', '34CD', '2REUWXLKQF');
-- Вставка практичного іспиту, коли всі умови виконано
CALL insert_practical_exam('2024-01-06', '17:00', 'Q7R8', '34CD', 'VXQ9CD0AE1');
-- Виведення результату
SELECT * FROM log_of_practical_exams;

-- 8 Вставка тоеретичного іспиту--
CREATE OR REPLACE PROCEDURE insert_theoretical_exam(
    p_date DATE, 
    p_time TIME, 
    p_inspector_id VARCHAR(4), 
    p_applicant_id VARCHAR(10))
AS $$ DECLARE v_category_of_transport VARCHAR(2);
BEGIN
    IF NOT is_theoretical_inspector_available(p_date, p_time) THEN 
        RAISE EXCEPTION 'Too many appointments at this time! Choose another.';
    ELSE INSERT INTO log_of_theoretical_exams (date_of_passing, time_of_passing, applicant_id, inspector_id, success_marker, exam_grade)
         VALUES (p_date, p_time, p_inspector_id, p_applicant_id, NULL, NULL);
         RAISE NOTICE 'Inserted!';
    END IF;
END;
$$ LANGUAGE plpgsql;
-- Вставка практичного іспиту, коли кандидат не має права водити авто
CALL insert_theoretical_exam('2024-01-06', '17:00', '2REUWXLKQF', 'EF56');
-- Вставка практичного іспиту, коли всі умови виконано
CALL insert_theoretical_exam('2024-01-06', '17:00', 'ZY099QM7M6', 'EF56');
-- Виведення результату
SELECT * FROM log_of_theoretical_exams;

-- 9 Процедура видалення посвідчення, якщо людина не може більше керувати ТЗ --
CREATE OR REPLACE PROCEDURE update_ability_to_drive(p_person_id VARCHAR(10), p_new_marker BOOLEAN)
AS $$ DECLARE
    old_marker BOOLEAN;
    v_last_name VARCHAR(50);
    v_first_name VARCHAR(50);
    v_middle_name VARCHAR(50);
    v_drivers_license_number VARCHAR(9);
BEGIN
    SELECT ability_to_drive_marker FROM medical_certificates WHERE person_id = p_person_id INTO old_marker;
    IF old_marker = p_new_marker THEN RAISE NOTICE 'Ability to drive was not changed';
    ELSE UPDATE medical_certificates
         SET ability_to_drive_marker = p_new_marker
         WHERE person_id = p_person_id;
         IF p_new_marker = false THEN
            -- Отримуємо ПІБ та номер посвідчення
            SELECT last_name, first_name, middle_name 
            INTO v_last_name, v_first_name, v_middle_name 
            FROM applicant 
            WHERE applicant_id = p_person_id;
            SELECT drivers_license_number 
            INTO v_drivers_license_number 
            FROM drivers_license 
            WHERE last_name = v_last_name 
              AND first_name = v_first_name 
              AND middle_name = v_middle_name;
            -- Видаляємо водійське посвічення
            IF v_drivers_license_number IS NOT NULL THEN
                DELETE FROM drivers_license WHERE drivers_license_number = v_drivers_license_number;
                DELETE FROM log_of_practical_exams WHERE applicant_id = p_person_id;
                DELETE FROM log_of_theoretical_exams WHERE applicant_id = p_person_id;
            END IF;
            UPDATE applicant SET amount_of_attempts = 0 WHERE applicant_id = p_person_id;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;
-- Демонстрація роботи
SELECT * FROM applicant WHERE applicant_id = '1JLNREGYNG';
SELECT * FROM medical_certificates WHERE person_id = '1JLNREGYNG';
SELECT * FROM drivers_license WHERE last_name = 'Ivachenko' AND first_name = 'Denis' AND middle_name = 'Mikolayovich';
SELECT * FROM received_categories WHERE drivers_license_number = 'KRK967838';
-- Виклик процедури
CALL update_ability_to_drive('1JLNREGYNG', FALSE);
-- Перевірка видалення записів
SELECT * FROM log_of_practical_exams WHERE applicant_id = '1JLNREGYNG';
SELECT * FROM log_of_theoretical_exams WHERE applicant_id = '1JLNREGYNG';

-- 10 Процедура виведення кількості записів практичних та теоретичних іспитів за сьогодні --
CREATE OR REPLACE PROCEDURE report_exams_today()
AS $$ DECLARE
    practical_exam_count INTEGER;
    theoretical_exam_count INTEGER;
BEGIN
    -- Підраховуємо практичні іспити
    SELECT COUNT(*)
    INTO practical_exam_count
    FROM log_of_practical_exams
    WHERE date_of_passing = CURRENT_DATE;
    -- Підраховуємо теоретичні іспити
    SELECT COUNT(*)
    INTO theoretical_exam_count
    FROM log_of_theoretical_exams
    WHERE date_of_passing = CURRENT_DATE;
    -- Виводимо результати
    RAISE NOTICE 'Practical exams today: %', practical_exam_count;
    RAISE NOTICE 'Theoretical exams today: %', theoretical_exam_count;
END;
$$ LANGUAGE plpgsql;
-- Виклик процедури
CALL report_exams_today();

-- 11 Видалення непроведених практичних екзаменів --
CREATE OR REPLACE PROCEDURE delete_unconducted_practical_exams()
AS $$
BEGIN
    DELETE FROM log_of_practical_exams
    WHERE success_marker IS NULL AND date_of_passing < CURRENT_DATE;
    RAISE NOTICE 'Unconducted practical exams have been deleted';
END;
$$ LANGUAGE plpgsql;
-- Демонстрація роботи
SELECT * FROM log_of_practical_exams;
CALL delete_unconducted_practical_exams();

-- 12 Видалення непроведених теоретичних екзаменів --
CREATE OR REPLACE PROCEDURE delete_unconducted_theoretical_exams()
AS $$
BEGIN
    DELETE FROM log_of_theoretical_exams
    WHERE success_marker IS NULL AND date_of_passing < CURRENT_DATE;
    RAISE NOTICE 'Unconducted theoretical exams have been deleted';
END;
$$ LANGUAGE plpgsql;
-- Демонстрація роботи
SELECT * FROM log_of_theoretical_exams;
CALL delete_unconducted_theoretical_exams();