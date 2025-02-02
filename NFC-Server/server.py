from flask import Flask, request, jsonify
import json

app = Flask(__name__)

# Load data from data.json
with open('data.json', 'r', encoding='utf-8') as file:
    data = json.load(file)

# Default Route
@app.route('/')
def home():
    return "NFC-CALS Server is Running!"

# GET Endpoint: Fetch all students
@app.route('/students', methods=['GET'])
def get_students():
    return jsonify(data['students'])

# POST Endpoint: Add a new student
@app.route('/students', methods=['POST'])
def add_student():
    new_student = request.json
    data['students'].append(new_student)
    with open('data.json', 'w', encoding='utf-8') as file:
        json.dump(data, file, ensure_ascii=False, indent=4)
    return jsonify({"message": "Student added successfully!"}), 201

# GET Endpoint: Fetch specific student by ID
@app.route('/students/<int:student_id>', methods=['GET'])
def get_student(student_id):
    student = next((s for s in data['students'] if s['id'] == student_id), None)
    if student:
        return jsonify(student)
    return jsonify({"error": "Student not found"}), 404

# GET Endpoint: Fetch all instructors
@app.route('/instructors', methods=['GET'])
def get_instructors():
    return jsonify(data['instructors'])

# POST Endpoint: Add a new instructor
@app.route('/instructors', methods=['POST'])
def add_instructor():
    new_instructor = request.json
    data['instructors'].append(new_instructor)
    with open('data.json', 'w', encoding='utf-8') as file:
        json.dump(data, file, ensure_ascii=False, indent=4)
    return jsonify({"message": "Instructor added successfully!"}), 201

# GET Endpoint: Fetch specific instructor by employee ID
@app.route('/instructors/<int:employee_id>', methods=['GET'])
def get_instructor(employee_id):
    instructor = next((i for i in data['instructors'] if i['employee_id'] == employee_id), None)
    if instructor:
        return jsonify(instructor)
    return jsonify({"error": "Instructor not found"}), 404

# GET Endpoint: Fetch all classes
@app.route('/classes', methods=['GET'])
def get_classes():
    return jsonify(data['classes'])

# POST Endpoint: Add a new class
@app.route('/classes', methods=['POST'])
def add_class():
    new_class = request.json
    data['classes'].append(new_class)
    with open('data.json', 'w', encoding='utf-8') as file:
        json.dump(data, file, ensure_ascii=False, indent=4)
    return jsonify({"message": "Class added successfully!"}), 201

# GET Endpoint: Fetch specific class by class number
@app.route('/classes/<string:class_number>', methods=['GET'])
def get_class(class_number):
    class_data = next((c for c in data['classes'] if c['class_number'] == class_number), None)
    if class_data:
        return jsonify(class_data)
    return jsonify({"error": "Class not found"}), 404

#  NEW: GET Endpoint - Fetch all courses
@app.route('/courses', methods=['GET'])
def get_courses():
    return jsonify(data['courses'])

#  NEW: POST Endpoint - Add a new course
@app.route('/courses', methods=['POST'])
def add_course():
    new_course = request.json
    data['courses'].append(new_course)
    with open('data.json', 'w', encoding='utf-8') as file:
        json.dump(data, file, ensure_ascii=False, indent=4)
    return jsonify({"message": "Course added successfully!"}), 201

#  NEW: GET Endpoint - Fetch a specific course by course code
@app.route('/courses/<string:course_code>', methods=['GET'])
def get_course(course_code):
    course = next((c for c in data['courses'] if c['course_code'] == course_code), None)
    if course:
        return jsonify(course)
    return jsonify({"error": "Course not found"}), 404

# Run the server
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

