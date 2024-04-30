-- Шаблони для вставки елементів у таблиці --
INSERT INTO type_of_transport (type_of_transport) 
VALUES ('');

INSERT INTO category_of_transport (category_of_transport) 
VALUES ('');

INSERT INTO transport (license_plate_number, purpose_of_transport, category_of_transport, year_of_manufacture, transport_id, affiliation_marker, type_of_gearbox) 
VALUES ('', '', '', '', '', '', '');

INSERT INTO practical_exam_inspector (last_name, first_name, middle_name, phone_number, inspector_id) 
VALUES ('', '', '', '', '');

INSERT INTO theoretical_exam_inspector (last_name, first_name, middle_name, phone_number, inspector_id) 
VALUES ('', '', '', '', '');

INSERT INTO applicant (last_name, first_name, middle_name, phone_number, applicant_id, amount_of_attempts) 
VALUES ('', '', '', '', '', '');

INSERT INTO log_of_practical_exams (date_of_passing, time_of_passing, transport_id, inspector_id, applicant_id, success_marker, amount_of_mistakes, category_of_transport) 
VALUES ('', '', '', '', '', NULL, NULL, '');

INSERT INTO log_of_theoretical_exams (date_of_passing, time_of_passing, applicant_id, inspector_id, success_marker, exam_grade) 
VALUES ('', '', '', '', NULL, NULL);

INSERT INTO medical_certificates (certificate_number, group_of_blood, rhesus_factor, person_id, ability_to_drive_marker) 
VALUES ('', '', '', '', '');

INSERT INTO drivers_license (drivers_license_number, last_name, first_name, middle_name, obtaining_date, expiration_date)
VALUES ('', '', '', '', '', ''),

INSERT INTO received_categories (category_of_transport, drivers_license_number, type_of_gearbox) 
VALUES ('', '', '');