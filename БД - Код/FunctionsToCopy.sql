-- Функції суцільним текстом --
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
CREATE OR REPLACE PROCEDURE delete_unconducted_practical_exams()
AS $$
BEGIN
    DELETE FROM log_of_practical_exams
    WHERE success_marker IS NULL AND date_of_passing < CURRENT_DATE;
    RAISE NOTICE 'Unconducted practical exams have been deleted';
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE PROCEDURE delete_unconducted_theoretical_exams()
AS $$
BEGIN
    DELETE FROM log_of_theoretical_exams
    WHERE success_marker IS NULL AND date_of_passing < CURRENT_DATE;
    RAISE NOTICE 'Unconducted theoretical exams have been deleted';
END;
$$ LANGUAGE plpgsql;