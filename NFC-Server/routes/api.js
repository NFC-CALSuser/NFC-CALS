const express = require('express');
const router = express.Router();
const DataHandler = require('../utils/dataHandler');

// Student routes
router.get('/students', (req, res) => {
  const students = DataHandler.getStudents();
  res.json(students);
});

router.post('/student/login', (req, res) => {
  const { id, password } = req.body;
  const students = DataHandler.getStudents();
  const student = students.find(s => s.id === parseInt(id) && s.password === password);
  
  if (student) {
    res.json({ success: true, student });
  } else {
    res.status(401).json({ success: false, message: 'Invalid credentials' });
  }
});

router.post('/student/attendance', (req, res) => {
  const { studentId, nfcId, timestamp } = req.body;
  const students = DataHandler.getStudents();
  const student = students.find(s => s.id === parseInt(studentId));
  
  if (student) {
    if (!student.attendance) student.attendance = [];
    student.attendance.push({ nfcId, timestamp });
    DataHandler.updateStudents(students);
    res.json({ success: true });
  } else {
    res.status(404).json({ success: false, message: 'Student not found' });
  }
});

// Instructor routes
router.get('/instructors', (req, res) => {
  const instructors = DataHandler.getInstructors();
  res.json(instructors);
});

router.post('/instructor/login', (req, res) => {
  const { id, password } = req.body;
  const instructors = DataHandler.getInstructors();
  const instructor = instructors.find(i => i.id === id && i.password === password);
  
  if (instructor) {
    res.json({ success: true, instructor });
  } else {
    res.status(401).json({ success: false, message: 'Invalid credentials' });
  }
});

// Course routes
router.get('/courses', (req, res) => {
  const courses = DataHandler.getCourses();
  res.json(courses);
});

// Class routes
router.get('/classes', (req, res) => {
  const classes = DataHandler.getClasses();
  res.json(classes);
});

module.exports = router;
