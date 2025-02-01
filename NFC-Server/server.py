from flask import Flask, request, jsonify
import json

app = Flask(__name__)

# Load data from data.json
with open('data.json', 'r', encoding='utf-8') as file:
    data = json.load(file)

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

# Run the server
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
