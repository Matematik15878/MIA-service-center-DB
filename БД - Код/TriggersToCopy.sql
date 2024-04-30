-- Тригери суцільним текстом --
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
-- 2 Тригер, що спрацьовує при вставці того кандидата, який не склав теоретичний іспит -- 
CREATE OR REPLACE TRIGGER check_ability_to_drive_trigger
BEFORE INSERT ON log_of_theoretical_exams
FOR EACH ROW
EXECUTE FUNCTION check_ability_to_drive();

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
