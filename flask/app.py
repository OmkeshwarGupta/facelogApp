from flask import Flask, request, jsonify, send_file
import cv2
import numpy as np
import firebase_admin
from firebase_admin import credentials, db
from datetime import datetime
import pickle
import face_recognition
import base64
from flask_cors import CORS
import pandas as pd
from io import BytesIO


app = Flask(__name__)
CORS(app)

# Initialize Firebase app (replace with your Firebase credentials)
cred = credentials.Certificate("./serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://facelog-c5d65-default-rtdb.firebaseio.com/'
})

# Load the trained face recognition model (replace with your model)
file = open('EncodeFile.p', 'rb')
encodeListKnownWithId = pickle.load(file)
file.close()
encodeListKnown, studentId = encodeListKnownWithId

# Function to mark attendance for detected students
def mark_attendance(student_id, teacher_id):
    now = datetime.now()
    date_time = now.strftime("%Y-%m-%d %H:%M:%S")
    ref = db.reference('/attendance/' + teacher_id + '/' + student_id)
    student_attendance = ref.get()
    if student_attendance is None:
        # Initialize an empty list if no attendance records exist
        student_attendance = []
    else:
        # Convert to list if not already
        student_attendance = list(student_attendance)
        # Check if there are previous attendance entries
        if len(student_attendance) > 0:
            # Update the status of the last attendance entry to "Present"
            student_attendance[-1]['status'] = 'Present'
    ref.set(student_attendance)  # Set the updated list back to the database

def mark_absent(subject_id):
    now = datetime.now()
    date_time = now.strftime("%Y-%m-%d %H:%M:%S")

    # Iterate through all student IDs associated with the provided teacher ID
    for student_id in studentId:
        ref = db.reference('/attendance/' + subject_id + '/' + student_id)
        student_attendance = ref.get()
        if student_attendance is None:
            student_attendance = []  # Initialize an empty list if no attendance records exist
        else:
            student_attendance = list(student_attendance)  # Convert to list if not already
        student_attendance.append({'date_time': date_time, 'status': 'Absent'})  # Mark as absent
        ref.set(student_attendance)  # Set the updated list back to the database

# Function to detect and recognize faces in an image
def detect_and_recognize_faces(img, teacher_id):
    facesCurFrame = face_recognition.face_locations(img)
    encodeCurFrame = face_recognition.face_encodings(img, facesCurFrame)
    present_students = 0  # Initialize present students count
    for encodeFace, faceLoc in zip(encodeCurFrame, facesCurFrame):
        match = False
        matches = face_recognition.compare_faces(encodeListKnown, encodeFace)
        faceDis = face_recognition.face_distance(encodeListKnown, encodeFace)
        matchIndex = np.argmin(faceDis)
        if matches[matchIndex] and faceDis[matchIndex] < 0.5:
            y1, x2, y2, x1 = faceLoc
            img = cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 0), 2)
            img = cv2.rectangle(img, (x1, y2), (x2, y2), (0, 255, 0), cv2.FILLED)
            cv2.putText(img, studentId[matchIndex], (x1 - 30, y2 + 15), cv2.FONT_HERSHEY_COMPLEX, 0.5,
                        (0, 0, 255), 1)
            id = studentId[matchIndex]
            mark_attendance(id, teacher_id)
            present_students += 1  # Increment present students count
            match = True
        else:
            y1, x2, y2, x1 = faceLoc
            img = cv2.rectangle(img, (x1, y1), (x2, y2), (255, 0, 0), 2)
            img = cv2.rectangle(img, (x1, y2), (x2, y2), (255, 0, 0), cv2.FILLED)
            cv2.putText(img, 'Unknown', (x2 - 60, y1 - 6), cv2.FONT_HERSHEY_COMPLEX, 0.5, (0, 0, 0), 1)

    return img, present_students

@app.route('/attendance', methods=['GET', 'POST'])
def capture_and_mark_attendance():
    if 'image' not in request.files:
        return jsonify({'error': 'No image sent!'}), 400

    if 'teacher_id' not in request.form:
        return jsonify({'error': 'Teacher ID not provided!'}), 400

    image_file = request.files['image']
    teacher_id = request.form['teacher_id']

    nparr = np.frombuffer(image_file.read(), np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if frame is None:
        return jsonify({'error': 'Failed to decode image!'}), 400

    # Detect and recognize faces in the image, and mark attendance
    frame, present_students = detect_and_recognize_faces(frame, teacher_id)

    # Count the number of absent students
    total_students = len(studentId)
    absent_students = total_students - present_students

    ret, buffer = cv2.imencode('.jpg', frame)
    img_str = buffer.tobytes()
    img_base64 = base64.b64encode(img_str).decode('utf-8')

    return jsonify({'image': 'data:image/jpeg;base64,' + img_base64,
                    'present_students': present_students,
                    'absent_students': absent_students}), 200

@app.route('/new_class', methods=['GET','POST'])
def mark_all_absent():
    if 'subject_id' not in request.form:
        return jsonify({'error': 'Subject ID not provided!'}), 400

    subject_id = request.form['subject_id']

    # Mark absent for all students in the database
    mark_absent(subject_id)

    return jsonify({'message': 'New Class Added'}), 200

@app.route('/download_attendance', methods=['GET', 'POST'])
def download_attendance():
    if request.method == 'GET':
        teacher_id = request.args.get('teacher_id')
    elif request.method == 'POST':
        if 'teacher_id' not in request.form:
            return jsonify({'error': 'Teacher ID not provided!'}), 400
        teacher_id = request.form['teacher_id']
    else:
        return jsonify({'error': 'Unsupported method!'}), 405

    if not teacher_id:
        return jsonify({'error': 'Teacher ID not provided!'}), 400

    # Fetch attendance data from Firebase
    ref = db.reference('/attendance/' + teacher_id)
    attendance_data = ref.get()

    if attendance_data is None:
        return jsonify({'error': 'No attendance data found for this teacher ID!'}), 404

    # Convert attendance data to a pandas DataFrame
    rows = []
    for student_id, attendance_records in attendance_data.items():
        student_name = student_id  # Assuming student ID is their name
        for record in attendance_records:
            date_time = datetime.strptime(record['date_time'], "%Y-%m-%d %H:%M:%S")
            date = date_time.strftime("%d/%m/%y")
            status = record['status']
            rows.append({'Student Name': student_name, 'Date': date, 'Status': status})

    df = pd.DataFrame(rows)

    # Pivot the DataFrame to get desired format
    df_pivot = df.pivot_table(index='Student Name', columns='Date', values='Status', aggfunc='first')

    # Sort columns (dates) in ascending order
    df_pivot = df_pivot.reindex(sorted(df_pivot.columns, key=lambda x: datetime.strptime(x, "%d/%m/%y")), axis=1)

    # Export DataFrame to Excel
    excel_file = BytesIO()
    df_pivot.to_excel(excel_file, index=True)
    excel_file.seek(0)

    return send_file(excel_file, mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                     as_attachment=True, download_name='attendance_data.xlsx')

if __name__ == '__main__':
    app.run(debug=True)
