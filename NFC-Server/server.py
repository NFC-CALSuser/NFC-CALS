from flask import Flask, request, jsonify
import json

app = Flask(__name__)

# Load data from data.json
def load_data():
    with open('data.json', 'r', encoding='utf-8') as file:
        return json.load(file)

def save_data(data):
    with open('data.json', 'w', encoding='utf-8') as file:
        json.dump(data, file, ensure_ascii=False, indent=4)

data = load_data()

# Default Route
@app.route('/')
def home():
    return "NFC-CALS Server is Running!"

# Login Authentication Endpoint
@app.route('/login', methods=['POST'])
def login():
    request_data = request.json
    user_id = request_data.get("id")
    
    # Check if user is a student
    student = next((s for s in data['students'] if s['id'] == user_id), None)
    if student:
        return jsonify({"role": "student", "name": student['name']}), 200
    
    # Check if user is an instructor
    instructor = next((i for i in data['instructors'] if i['employee_id'] == user_id), None)
    if instructor:
        return jsonify({"role": "instructor", "name": instructor['name']}), 200
    
    return jsonify({"error": "User not found"}), 404

# Attendance Logging Endpoint
@app.route('/attendance', methods=['POST'])
def mark_attendance():
    request_data = request.json
    user_id = request_data.get("id")
    class_number = request_data.get("class_number")
    
    # Verify student
    student = next((s for s in data['students'] if s['id'] == user_id), None)
    if not student:
        return jsonify({"error": "Student not found"}), 404
    
    # Verify class exists
    class_exists = any(c['class_number'] == class_number for c in data['classes'])
    if not class_exists:
        return jsonify({"error": "Class not found"}), 404
    
    # Record attendance
    if "attendance" not in data:
        data["attendance"] = []
    
    data["attendance"].append({
        "student_id": user_id,
        "name": student['name'],
        "class_number": class_number,
        "timestamp": request_data.get("timestamp")
    })
    save_data(data)
    
    return jsonify({"message": "Attendance recorded successfully!"}), 201

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)


