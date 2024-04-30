-- Експорт даних із БД у файли у папку C:/files/ --
COPY type_of_transport TO 'C:/files/type_of_transport.csv' WITH CSV HEADER;
COPY category_of_transport TO 'C:/files/category_of_transport.csv' WITH CSV HEADER;
COPY transport TO 'C:/files/transport.csv' WITH CSV HEADER;
COPY practical_exam_inspector TO 'C:/files/practical_exam_inspector.csv' WITH CSV HEADER;
COPY theoretical_exam_inspector TO 'C:/files/theoretical_exam_inspector.csv' WITH CSV HEADER;
COPY applicant TO 'C:/files/applicant.csv' WITH CSV HEADER;
COPY log_of_practical_exams (date_of_passing, time_of_passing, transport_id, inspector_id, applicant_id, success_marker, amount_of_mistakes, category_of_transport) 
     TO 'C:/files/log_of_practical_exams.csv' WITH CSV HEADER;
COPY log_of_theoretical_exams (date_of_passing, time_of_passing, applicant_id, inspector_id, success_marker, exam_grade) 
     TO 'C:/files/log_of_theoretical_exams.csv' WITH CSV HEADER;
COPY medical_certificates TO 'C:/files/medical_certificates.csv' WITH CSV HEADER;
COPY drivers_license TO 'C:/files/drivers_license.csv' WITH CSV HEADER;
COPY received_categories TO 'C:/files/received_categories.csv' WITH CSV HEADER;