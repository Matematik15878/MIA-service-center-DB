-- Функція для тригера на вставку елемента в log_of_practical_exams --
CREATE OR REPLACE FUNCTION check_theoretical_exam_success()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM log_of_theoretical_exams
        WHERE applicant_id = NEW.applicant_id AND success_marker = TRUE
    ) 
    THEN RAISE EXCEPTION 'Applicant has not passed the theoretical exam! The insertion was aborted!';
    ELSE RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
-- 1 Тригер, що спрацьовує при вставці того кандидата, який не склав теоретичний іспит -- 
CREATE OR REPLACE TRIGGER check_theoretical_exam_trigger
BEFORE INSERT ON log_of_practical_exams
FOR EACH ROW
EXECUTE FUNCTION check_theoretical_exam_success();
-- Вставка кандидата, що не склав теоретичний іспит
INSERT INTO log_of_practical_exams (date_of_passing, time_of_passing, transport_id, inspector_id, applicant_id, success_marker, amount_of_mistakes, category_of_transport) 
VALUES ('2023-12-30', '12:00', 'BC45', 'UVWX', 'JBCFPPE6NC', NULL, NULL, 'B');
-- Вставка кандидата, що склав теоретичний іспит
INSERT INTO log_of_practical_exams (date_of_passing, time_of_passing, transport_id, inspector_id, applicant_id, success_marker, amount_of_mistakes, category_of_transport) 
VALUES ('2023-12-30', '12:00', 'BC45', 'UVWX', '1Q6LHSY9F6', NULL, NULL, 'B');
-- Видалення тригера та функції
DROP TRIGGER IF EXISTS check_theoretical_exam_trigger ON log_of_practical_exams;
DROP FUNCTION IF EXISTS check_theoretical_exam_success();

-- Функція для тригера на вставку елемента в log_of_theoretical_exams --
CREATE OR REPLACE FUNCTION check_ability_to_drive()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM medical_certificates
        WHERE person_id = NEW.applicant_id AND ability_to_drive_marker = TRUE
    ) 
    THEN RAISE EXCEPTION 'Applicant cannot drive a vehicle or does not have a medical certificate! The insertion was aborted!';
    ELSE RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
-- 2 Тригер, що спрацьовує при вставці того кандидата, який не має медичної можливості керувати ТЗ -- 
CREATE OR REPLACE TRIGGER check_ability_to_drive_trigger
BEFORE INSERT ON log_of_theoretical_exams
FOR EACH ROW
EXECUTE FUNCTION check_ability_to_drive();
-- Вставка кандидата, що не має права на керування ТЗ
INSERT INTO log_of_theoretical_exams (date_of_passing, time_of_passing, applicant_id, inspector_id, success_marker, exam_grade) 
VALUES ('2024-01-20', '12:00', 'JBCFPPE6NC', 'LK91', NULL, NULL);
-- Вставка кандидата, що має право на керування ТЗ
INSERT INTO log_of_theoretical_exams (date_of_passing, time_of_passing, applicant_id, inspector_id, success_marker, exam_grade) 
VALUES ('2024-01-20', '12:00', 'Q1A04JFGAH', 'LK91', NULL, NULL);
-- Видалення тригера та функції
DROP TRIGGER IF EXISTS check_ability_to_drive_trigger ON log_of_theoretical_exams;
DROP FUNCTION IF EXISTS check_ability_to_drive();

-- Функція для тригеру підрахунку кількості спроб здати практичний іспит --
CREATE OR REPLACE FUNCTION update_amount_of_attempts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE applicant
        SET amount_of_attempts = amount_of_attempts + 1
        WHERE applicant_id = NEW.applicant_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE applicant
        SET amount_of_attempts = amount_of_attempts - 1
        WHERE applicant_id = OLD.applicant_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- 3 Тригер для підрахунку кількості спроб здати практичний іспит при вставці і видаленні
CREATE OR REPLACE TRIGGER update_amount_of_attempts_trigger
AFTER INSERT OR DELETE ON log_of_practical_exams
FOR EACH ROW
EXECUTE FUNCTION update_amount_of_attempts();
-- Демонстрація роботи
SELECT applicant_id, amount_of_attempts FROM applicant WHERE applicant_id = '40F9ZS4KTI';
DELETE FROM log_of_practical_exams WHERE date_of_passing = '2024-01-06' AND applicant_id = '40F9ZS4KTI';
SELECT applicant_id, amount_of_attempts FROM applicant WHERE applicant_id = '40F9ZS4KTI';
INSERT INTO log_of_practical_exams (date_of_passing, time_of_passing, transport_id, inspector_id, applicant_id, success_marker, amount_of_mistakes, category_of_transport) 
VALUES ('2024-01-06', '16:00', 'Q7R8', '34CD', '40F9ZS4KTI', NULL, NULL, 'C1');
SELECT applicant_id, amount_of_attempts FROM applicant WHERE applicant_id = '40F9ZS4KTI';
-- Видалення тригера та функції
DROP TRIGGER IF EXISTS update_amount_of_attempts_trigger ON log_of_practical_exams;
DROP FUNCTION IF EXISTS update_amount_of_attempts();

-- Функція для тригера на вставку елемента в drivers_license --
CREATE OR REPLACE FUNCTION check_practical_exam_success()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM log_of_practical_exams pe
        JOIN applicant a ON pe.applicant_id = a.applicant_id
        WHERE a.last_name = NEW.last_name
          AND a.first_name = NEW.first_name
          AND a.middle_name = NEW.middle_name
          AND pe.success_marker = TRUE
    ) 
    THEN RAISE EXCEPTION 'Applicant has not passed the practical exam! The insertion was aborted!';
    ELSE RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
-- 4 Тригер, що спрацьовує при вставці того кандидата, який не склав теоретичний іспит 
CREATE OR REPLACE TRIGGER check_practical_exam_trigger
BEFORE INSERT ON drivers_license
FOR EACH ROW
EXECUTE FUNCTION check_practical_exam_success();
-- Вставка ліцензії тієї людини, яка не здала практичний іспит
INSERT INTO drivers_license (drivers_license_number, last_name, first_name, middle_name, obtaining_date, expiration_date)
VALUES ('RTY128716', 'Hrytsenko', 'Daria', 'Mykolaivna', '2023-12-30', '2053-12-30');
-- Вставка ліцензії тієї людини, яка іспит здала
DELETE FROM drivers_license WHERE drivers_license_number = 'DEO607623';
INSERT INTO drivers_license (drivers_license_number, last_name, first_name, middle_name, obtaining_date, expiration_date)
VALUES ('DEO607623', 'Hrytsenko', 'Nataliia', 'Pavlivna', '2023-10-12', '2053-10-12');
INSERT INTO received_categories (category_of_transport, drivers_license_number, type_of_gearbox) 
VALUES ('B', 'DEO607623', 'AT');
-- Видалення тригера та функції
DROP TRIGGER IF EXISTS check_practical_exam_trigger ON drivers_license;
DROP FUNCTION IF EXISTS check_practical_exam_success();

-- Функція перевірки, чи отримав таку категорії кандидат --
CREATE OR REPLACE FUNCTION check_received_categories()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM log_of_practical_exams pe
        JOIN applicant a ON pe.applicant_id = a.applicant_id
        JOIN transport t ON pe.transport_id = t.transport_id
        WHERE a.last_name = (SELECT last_name FROM drivers_license WHERE drivers_license_number = NEW.drivers_license_number)
          AND a.first_name = (SELECT first_name FROM drivers_license WHERE drivers_license_number = NEW.drivers_license_number)
          AND a.middle_name = (SELECT middle_name FROM drivers_license WHERE drivers_license_number = NEW.drivers_license_number)
          AND pe.success_marker = TRUE
          AND pe.category_of_transport = NEW.category_of_transport
          AND ((NEW.type_of_gearbox IS NULL AND t.type_of_gearbox IS NULL) OR
               (NEW.type_of_gearbox IS NOT NULL AND NEW.type_of_gearbox = t.type_of_gearbox))
    ) THEN RAISE EXCEPTION 'The candidate did not pass the practical exam with the specified category and gearbox type!';
    ELSE RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;
-- 5 Тригер на вставку категорії та типу коробки передач
CREATE OR REPLACE TRIGGER check_received_categories_trigger
BEFORE INSERT ON received_categories
FOR EACH ROW
EXECUTE FUNCTION check_received_categories();
-- Перевірка, вставка не отриманої категорії
INSERT INTO received_categories (category_of_transport, drivers_license_number, type_of_gearbox) 
VALUES ('T', 'DEO607623', 'MT');
-- Видалення тригера та функції
DROP TRIGGER IF EXISTS check_received_categories_trigger ON received_categories;
DROP FUNCTION IF EXISTS check_received_categories();

-- Функція тригера для видалення водійського посвідчення --
CREATE OR REPLACE FUNCTION delete_drivers_license() RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM received_categories 
    WHERE drivers_license_number = OLD.drivers_license_number;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
-- 6 Тригер для видалення водійського посвідчення
CREATE OR REPLACE TRIGGER before_delete_drivers_license
BEFORE DELETE ON drivers_license
FOR EACH ROW 
EXECUTE FUNCTION delete_drivers_license();
-- Видалення водійського посвідчення
SELECT * FROM received_categories WHERE drivers_license_number = 'DEO607623';
DELETE FROM drivers_license WHERE drivers_license_number = 'DEO607623';
SELECT * FROM received_categories WHERE drivers_license_number = 'DEO607623';
-- Вставка видаленого посвідчення
INSERT INTO drivers_license (drivers_license_number, last_name, first_name, middle_name, obtaining_date, expiration_date)
VALUES ('DEO607623', 'Hrytsenko', 'Nataliia', 'Pavlivna', '2023-10-12', '2053-10-12');
INSERT INTO received_categories (category_of_transport, drivers_license_number, type_of_gearbox) 
VALUES ('B', 'DEO607623', 'MT');
-- Видалення тригера та функції
DROP TRIGGER IF EXISTS before_delete_drivers_license ON drivers_license;
DROP FUNCTION IF EXISTS delete_drivers_license();

-- Функція тригеру на встановлення оцінки практичного іспиту --
CREATE OR REPLACE FUNCTION check_practical_exam_mistakes()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.amount_of_mistakes is NULL AND NEW.success_marker IS NOT NULL THEN
    	RAISE NOTICE 'The number of mistakes is NULL, so the success marker is set to NULL.';
        NEW.success_marker = NULL;
    ELSIF NEW.amount_of_mistakes < 3 AND NEW.success_marker IS NOT TRUE THEN
        IF NEW.success_marker IS NOT TRUE THEN
            NEW.success_marker := TRUE;
            RAISE NOTICE 'Success marker set to TRUE due to less than 2 mistakes';
        END IF;
    ELSIF NEW.amount_of_mistakes >= 3 AND NEW.success_marker IS NOT FALSE THEN
        IF NEW.success_marker IS NOT FALSE THEN
            NEW.success_marker := FALSE;
            RAISE NOTICE 'Success marker set to FALSE due to more than 2 mistakes';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- 7 Тригер на встановлення оцінки практичного іспиту
CREATE OR REPLACE TRIGGER update_practical_exam_success_marker
BEFORE INSERT OR UPDATE ON log_of_practical_exams
FOR EACH ROW
EXECUTE FUNCTION check_practical_exam_mistakes();
-- Зміни запису на практичний іспит
UPDATE log_of_practical_exams
SET success_marker = FALSE
WHERE date_of_passing = '2024-01-03' AND applicant_id = 'ZY099QM7M6';
-- Зміни запису на практичний іспит
UPDATE log_of_practical_exams
SET amount_of_mistakes = 3, success_marker = TRUE
WHERE date_of_passing = '2024-01-03' AND applicant_id = 'ZY099QM7M6';
-- Виведення записів на практичний іспит
SELECT * FROM log_of_practical_exams;
-- Видалення тригера та функції
DROP TRIGGER IF EXISTS update_practical_exam_success_marker ON log_of_practical_exams;
DROP FUNCTION IF EXISTS check_practical_exam_mistakes();

-- Функція тригеру на встановлення оцінки теоретичного іспиту --
CREATE OR REPLACE FUNCTION check_theoretical_exam_grade()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.exam_grade is NULL AND NEW.success_marker IS NOT NULL THEN
    	RAISE NOTICE 'The number of mistakes is NULL, so the success marker is set to NULL.';
        NEW.success_marker = NULL;
    ELSIF NEW.exam_grade >= 18 AND NEW.success_marker IS NOT TRUE THEN
        IF NEW.success_marker IS NOT TRUE THEN
            NEW.success_marker := TRUE;
            RAISE NOTICE 'Success marker set to TRUE due to more than 17 correct answers';
        END IF;
    ELSIF NEW.exam_grade < 18 AND NEW.success_marker IS NOT FALSE THEN
        IF NEW.success_marker IS NOT FALSE THEN
            NEW.success_marker := FALSE;
            RAISE NOTICE 'Success marker set to FALSE due to less than 18 correct answers';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- 8 Тригер на встановлення оцінки теоретичного іспиту
CREATE OR REPLACE TRIGGER update_theoretical_exam_success_marker
BEFORE INSERT OR UPDATE ON log_of_theoretical_exams
FOR EACH ROW
EXECUTE FUNCTION check_theoretical_exam_grade();
-- Зміни запису на практичний іспит
UPDATE log_of_theoretical_exams
SET success_marker = FALSE
WHERE date_of_passing = '2024-01-06' AND applicant_id = 'Q1A04JFGAH';
-- Зміни запису на практичний іспит
UPDATE log_of_theoretical_exams
SET exam_grade = 17, success_marker = TRUE
WHERE date_of_passing = '2024-01-06' AND applicant_id = 'Q1A04JFGAH';
-- Виведення записів на практичний іспит
SELECT * FROM log_of_theoretical_exams;
-- Видалення тригера та функції
DROP TRIGGER IF EXISTS update_theoretical_exam_success_marker ON log_of_theoretical_exams;
DROP FUNCTION IF EXISTS check_theoretical_exam_grade();