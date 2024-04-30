-- Створення ролей --
CREATE ROLE document_exam_manager;
CREATE ROLE chief_manager;
CREATE ROLE applicant;
CREATE ROLE inspector;

-- Головний менеджер --
GRANT SELECT ON ALL TABLES IN SCHEMA public TO chief_manager;
GRANT INSERT, DELETE ON practical_exam_inspector, theoretical_exam_inspector TO chief_manager;
GRANT INSERT, DELETE ON transport, type_of_transport, category_of_transport TO chief_manager;
GRANT UPDATE (phone_number) ON practical_exam_inspector, theoretical_exam_inspector TO chief_manager;

-- Менеджер іспитів і документів --
GRANT SELECT ON ALL TABLES IN SCHEMA public TO document_exam_manager;
GRANT INSERT, DELETE ON medical_certificates TO document_exam_manager;
GRANT INSERT, DELETE ON log_of_practical_exams, log_of_theoretical_exams TO document_exam_manager;
GRANT INSERT, DELETE ON received_categories TO document_exam_manager;
GRANT INSERT, DELETE ON drivers_license TO document_exam_manager;
GRANT INSERT, DELETE ON applicant TO document_exam_manager;
GRANT USAGE, SELECT ON SEQUENCE log_of_practical_exams_exam_serial_number_seq TO document_exam_manager;
GRANT USAGE, SELECT ON SEQUENCE log_of_theoretical_exams_exam_serial_number_seq TO document_exam_manager;
GRANT UPDATE (amount_of_mistakes, success_marker) ON log_of_practical_exams TO document_exam_manager;
GRANT UPDATE (phone_number, amount_of_attempts) ON applicant TO document_exam_manager;
GRANT UPDATE (exam_grade, success_marker) ON log_of_theoretical_exams TO document_exam_manager;
GRANT UPDATE (ability_to_drive_marker) ON medical_certificates TO document_exam_manager;

-- Кандидат на посвідчення --
GRANT SELECT ON log_of_practical_exams TO applicant;
GRANT SELECT ON log_of_theoretical_exams TO applicant;
GRANT SELECT ON practical_exam_inspector TO applicant;
GRANT SELECT ON theoretical_exam_inspector TO applicant;
GRANT SELECT ON transport TO applicant;
GRANT SELECT ON applicant TO applicant;

-- Інструктор --
GRANT applicant TO inspector;
GRANT SELECT ON received_categories TO inspector;
GRANT SELECT ON drivers_license TO inspector;

-- Створення користувачів --
CREATE USER chief_manager_user WITH PASSWORD 'admin';
GRANT chief_manager TO chief_manager_user;
CREATE USER document_exam_manager_user WITH PASSWORD 'password';
GRANT document_exam_manager TO document_exam_manager_user;
CREATE USER inspector_user WITH PASSWORD '244466666';
GRANT inspector TO inspector_user;
CREATE USER applicant_user WITH PASSWORD '987654321';
GRANT applicant TO applicant_user;

-- Дані про ролі --
SELECT grantor, grantee, table_name, privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'document_manager';

-- Видалення ролей і юзерів --
DROP ROLE IF EXISTS document_exam_manager;
DROP ROLE IF EXISTS chief_manager;
DROP ROLE IF EXISTS exam_manager;
DROP ROLE IF EXISTS applicant;
DROP ROLE IF EXISTS inspector;

DROP USER IF EXISTS document_exam_manager_user;
DROP USER IF EXISTS chief_manager_user;
DROP USER IF EXISTS exam_manager_user;
DROP USER IF EXISTS applicant_user;
DROP USER IF EXISTS inspector_user;