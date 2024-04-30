-- Імпорт даних у БД із файлів у папці C:/files/ --
COPY type_of_transport FROM 'C:/files/type_of_transport.csv' WITH CSV HEADER;
COPY category_of_transport FROM 'C:/files/category_of_transport.csv' WITH CSV HEADER;
COPY transport FROM 'C:/files/transport.csv' WITH CSV HEADER;
COPY practical_exam_inspector FROM 'C:/files/practical_exam_inspector.csv' WITH CSV HEADER;
COPY theoretical_exam_inspector FROM 'C:/files/theoretical_exam_inspector.csv' WITH CSV HEADER;
COPY applicant FROM 'C:/files/applicant.csv' WITH CSV HEADER;
COPY medical_certificates FROM 'C:/files/medical_certificates.csv' WITH CSV HEADER;
COPY log_of_theoretical_exams (date_of_passing, time_of_passing, applicant_id, inspector_id, success_marker, exam_grade) 
     FROM 'C:/files/log_of_theoretical_exams.csv' WITH CSV HEADER;
COPY log_of_practical_exams (date_of_passing, time_of_passing, transport_id, inspector_id, applicant_id, success_marker, amount_of_mistakes, category_of_transport) 
     FROM 'C:/files/log_of_practical_exams.csv' WITH CSV HEADER;
COPY drivers_license FROM 'C:/files/drivers_license.csv' WITH CSV HEADER;
COPY received_categories FROM 'C:/files/received_categories.csv' WITH CSV HEADER;