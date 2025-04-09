const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '..', 'data');

class DataHandler {
  static readData(fileName) {
    const filePath = path.join(DATA_DIR, `${fileName}.json`);
    try {
      const data = fs.readFileSync(filePath, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      console.error(`Error reading ${fileName}.json:`, error);
      return null;
    }
  }

  static writeData(fileName, data) {
    const filePath = path.join(DATA_DIR, `${fileName}.json`);
    try {
      fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
      return true;
    } catch (error) {
      console.error(`Error writing ${fileName}.json:`, error);
      return false;
    }
  }

  static getStudents() {
    const data = this.readData('students');
    return data ? data.students : [];
  }

  static getInstructors() {
    const data = this.readData('instructors');
    return data ? data.instructors : [];
  }

  static getCourses() {
    const data = this.readData('courses');
    return data ? data.courses : [];
  }

  static getClasses() {
    const data = this.readData('classes');
    return data ? data.classes : [];
  }

  // Add methods for updating each entity
  static updateStudents(students) {
    return this.writeData('students', { students });
  }

  static updateInstructors(instructors) {
    return this.writeData('instructors', { instructors });
  }

  static updateCourses(courses) {
    return this.writeData('courses', { courses });
  }

  static updateClasses(classes) {
    return this.writeData('classes', { classes });
  }

  static findStudentById(id) {
    const students = this.getStudents();
    // Use type checking and sanitization
    const sanitizedId = parseInt(id, 10);
    if (isNaN(sanitizedId)) {
      throw new Error('Invalid student ID format');
    }
    return students.find(s => s.id === sanitizedId);
  }

  static findStudentByNfcId(nfcId) {
    const students = this.getStudents();
    return students.find(s => s.nfc_id === parseInt(nfcId));
  }

  static findInstructorById(id) {
    const instructors = this.getInstructors();
    return instructors.find(i => i.id === id);
  }

  static findInstructorByNfcId(nfcId) {
    const instructors = this.getInstructors();
    return instructors.find(i => i.nfc_id === parseInt(nfcId));
  }

  static updateStudentAttendance(studentId, attendanceData) {
    // Validate and sanitize input
    if (!this.isValidAttendanceData(attendanceData)) {
      throw new Error('Invalid attendance data format');
    }

    const students = this.getStudents();
    const sanitizedId = parseInt(studentId, 10);
    const studentIndex = students.findIndex(s => s.id === sanitizedId);
    
    if (studentIndex === -1) return false;

    if (!students[studentIndex].attendance) {
      students[studentIndex].attendance = [];
    }
    students[studentIndex].attendance.push(attendanceData);
    return this.updateStudents(students);
  }

  static isValidAttendanceData(data) {
    return (
      data &&
      typeof data === 'object' &&
      typeof data.record_id === 'string' &&
      typeof data.course_id === 'string' &&
      typeof data.date === 'string' &&
      Array.isArray(data.students_ids)
    );
  }

  static async executeMarkAbsenceScript(sessionId) {
    const { exec } = require('child_process');
    const path = require('path');
    const scriptPath = path.join(__dirname, '..', '..', 'scripts', 'mark_end_session.ps1');

    return new Promise((resolve, reject) => {
      exec(`powershell -File "${scriptPath}" ${sessionId}`, (error, stdout, stderr) => {
        if (error) {
          console.error(`Error executing script: ${error}`);
          reject(error);
          return;
        }
        console.log(`Script output: ${stdout}`);
        resolve(stdout);
      });
    });
  }
}

module.exports = DataHandler;
