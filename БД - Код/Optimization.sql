-- Створення індексів --
CREATE INDEX idx_practical_exam_inspector_id ON practical_exam_inspector(inspector_id);
CREATE INDEX idx_theoretical_exam_inspector_id ON theoretical_exam_inspector(inspector_id);
CREATE INDEX idx_applicant_id ON applicant(applicant_id);
CREATE INDEX idx_transport_id ON transport(transport_id);
CREATE INDEX idx_log_practical_exam_serial_number ON log_of_practical_exams(exam_serial_number);
CREATE INDEX idx_log_theoretical_exam_serial_number ON log_of_theoretical_exams(exam_serial_number);
CREATE INDEX idx_medical_certificate_number ON medical_certificates(certificate_number);
CREATE INDEX idx_drivers_license_number ON drivers_license(drivers_license_number);

-- Видалення індексів --
DROP INDEX idx_practical_exam_inspector_id;
DROP INDEX idx_theoretical_exam_inspector_id;
DROP INDEX idx_applicant_id;
DROP INDEX idx_transport_id;
DROP INDEX idx_log_practical_exam_serial_number;
DROP INDEX idx_log_theoretical_exam_serial_number;
DROP INDEX idx_medical_certificate_number;
DROP INDEX idx_drivers_license_number;