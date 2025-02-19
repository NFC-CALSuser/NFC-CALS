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
    return students.find(s => s.id === parseInt(id));
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
    const students = this.getStudents();
    const studentIndex = students.findIndex(s => s.id === parseInt(studentId));
    
    if (studentIndex !== -1) {
      if (!students[studentIndex].attendance) {
        students[studentIndex].attendance = [];
      }
      students[studentIndex].attendance.push(attendanceData);
      return this.updateStudents(students);
    }
    return false;
  }
}

module.exports = DataHandler;
