-- Створення і відкриття бази даних "Сервісний центр МВС" --
CREATE DATABASE service_center_mia;
-- Перехід до бази даних --
\c service_center_mia

-- Створення таблиць для транспорту сервісного центру --
CREATE TABLE type_of_transport (
	type_of_transport VARCHAR(50) PRIMARY KEY NOT NULL
);

CREATE TABLE category_of_transport (
	category_of_transport VARCHAR(2) PRIMARY KEY NOT NULL
);

CREATE TABLE transport (
	license_plate_number VARCHAR(8),
	purpose_of_transport VARCHAR(50) REFERENCES type_of_transport (type_of_transport) ON DELETE CASCADE NOT NULL,
	category_of_transport VARCHAR(3) REFERENCES category_of_transport (category_of_transport) ON DELETE CASCADE NOT NULL,
	year_of_manufacture VARCHAR(4) NOT NULL,
	transport_id VARCHAR(4) PRIMARY KEY NOT NULL,
	affiliation_marker BOOLEAN NOT NULL,
	type_of_gearbox varchar(2)
);

-- Створення таблиць людей-учасників процесу отримання водійських посвічень -- 
CREATE TABLE practical_exam_inspector (
	last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(16) NOT NULL,
    inspector_id VARCHAR(4) PRIMARY KEY NOT NULL
);

CREATE TABLE theoretical_exam_inspector (
	last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(16) NOT NULL,
    inspector_id VARCHAR(4) PRIMARY KEY NOT NULL
);

CREATE TABLE applicant (
	last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(16) NOT NULL,
    applicant_id VARCHAR(10) PRIMARY KEY NOT NULL,
    amount_of_attempts INTEGER NOT NULL
);

-- Створення таблиць обліку іспитів --
CREATE TABLE log_of_practical_exams (
	date_of_passing DATE CHECK (date_of_passing >= '1900-12-24') NOT NULL,
	time_of_passing TIME NOT NULL,
	transport_id VARCHAR(4) REFERENCES transport (transport_id) ON DELETE CASCADE NOT NULL,
	inspector_id VARCHAR(4) REFERENCES practical_exam_inspector (inspector_id) ON DELETE CASCADE NOT NULL,
	applicant_id VARCHAR(10) REFERENCES applicant (applicant_id) ON DELETE CASCADE NOT NULL,
	success_marker BOOLEAN,
	amount_of_mistakes SMALLINT,
	exam_serial_number SERIAL PRIMARY KEY NOT NULL,
	category_of_transport VARCHAR(3) REFERENCES category_of_transport (category_of_transport) ON DELETE CASCADE NOT NULL
);

CREATE TABLE log_of_theoretical_exams (
	date_of_passing DATE CHECK (date_of_passing >= '1900-12-24') NOT NULL,
	time_of_passing TIME NOT NULL,
	applicant_id VARCHAR(10) REFERENCES applicant (applicant_id) ON DELETE CASCADE NOT NULL,
	inspector_id VARCHAR(4) REFERENCES theoretical_exam_inspector (inspector_id) ON DELETE CASCADE NOT NULL,
	success_marker BOOLEAN,
	exam_grade SMALLINT,
	exam_serial_number SERIAL PRIMARY KEY NOT NULL
);

-- Створення таблиць обліку документів -- 
CREATE TABLE medical_certificates (
	certificate_number VARCHAR(6) PRIMARY KEY NOT NULL,
	group_of_blood INTEGER NOT NULL,
	rhesus_factor VARCHAR(1) NOT NULL,
	person_id VARCHAR(10) REFERENCES applicant(applicant_id) ON DELETE CASCADE NOT NULL UNIQUE,
	ability_to_drive_marker BOOLEAN NOT NULL
);

CREATE TABLE drivers_license (
	drivers_license_number VARCHAR(9) PRIMARY KEY NOT NULL,
	last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50) NOT NULL,
	obtaining_date DATE CHECK (obtaining_date >= '1900-12-24') NOT NULL,
	expiration_date DATE CHECK (expiration_date >= '1900-12-24') NOT NULL
);

CREATE TABLE received_categories (
	category_of_transport VARCHAR(2) REFERENCES category_of_transport (category_of_transport) NOT NULL,
	drivers_license_number VARCHAR(9) REFERENCES drivers_license (drivers_license_number) NOT NULL,
	type_of_gearbox varchar(2),
	CONSTRAINT uq_recieved_categorie UNIQUE (category_of_transport, drivers_license_number)
);

-- Видалення бази даних --
DROP DATABASE service_center_mia;