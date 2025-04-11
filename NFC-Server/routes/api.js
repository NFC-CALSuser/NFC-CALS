const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const DataHandler = require('../utils/dataHandler');
const sanitizeInput = require('../middleware/sanitize');

// Create different rate limiters for different endpoints
const attendanceLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 30, // 30 requests per minute for attendance operations
  message: 'Too many attendance requests, please try again after a minute'
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 login attempts per 15 minutes
  message: 'Too many login attempts, please try again after 15 minutes'
});

const generalLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100, // 100 requests per minute for general operations
  message: 'Too many requests, please try again after a minute'
});

// Apply rate limiting to specific routes
router.use('/attendance', attendanceLimiter);
router.use('/student/login', authLimiter);
router.use('/instructor/login', authLimiter);
router.use('/', generalLimiter);

// Apply sanitization to all routes
router.use(sanitizeInput);

// Student routes
router.get('/students', (req, res) => {
  const students = DataHandler.getStudents();
  res.json(students);
});

router.post('/student/login', authLimiter, (req, res) => {
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

// Update attendance record
router.put('/attendance/:id', (req, res) => {
  try {
    const { id } = req.params;
    const { students_ids } = req.body;
    
    const data = DataHandler.readData('attendance') || [];
    const index = data.findIndex(record => record.id === id);
    
    if (index !== -1) {
      data[index].students_ids = students_ids;
      if (DataHandler.writeData('attendance', data)) {
        res.json({ success: true, message: 'Attendance record updated' });
      } else {
        throw new Error('Failed to update attendance record');
      }
    } else {
      res.status(404).json({ success: false, message: 'Record not found' });
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get specific attendance record with error handling
router.get('/attendance/:id', (req, res) => {
  try {
    const { id } = req.params;
    console.log(`Fetching attendance record: ${id}`);
    
    const data = DataHandler.readData('attendance') || [];
    const record = data.find(r => r.id === id);
    
    if (record) {
      console.log('Record found:', record);
      res.json(record);
    } else {
      console.log('Record not found');
      res.status(404).json({ 
        success: false, 
        message: 'Record not found',
        requestedId: id 
      });
    }
  } catch (error) {
    console.error('Error fetching attendance record:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message,
      requestedId: req.params.id 
    });
  }
});

// Get all attendance records
router.get('/attendance', (req, res) => {
  try {
    const data = DataHandler.readData('attendance') || [];
    res.json(data);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Update attendance record (PATCH)
router.patch('/attendance/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { encrypted_data, students_ids } = req.body;
    
    const data = DataHandler.readData('attendance') || [];
    const index = data.findIndex(record => record.id === id);
    
    if (index !== -1) {
      // Store encrypted student IDs
      data[index].encrypted_data = encrypted_data;
      data[index].students_ids = students_ids; // Already encrypted IDs
      
      if (DataHandler.writeData('attendance', data)) {
        res.json({ success: true, message: 'Attendance record updated' });
      } else {
        throw new Error('Failed to update attendance record');
      }
    } else {
      res.status(404).json({ success: false, message: 'Record not found' });
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Update attendance route with validation
router.post('/attendance', async (req, res) => {
  try {
    const { id, encrypted_data, status } = req.body;
    
    const newRecord = {
      id,
      encrypted_data,
      status,
      students_ids: []
    };

    const data = DataHandler.readData('attendance') || [];
    data.push(newRecord);

    if (DataHandler.writeData('attendance', data)) {
      res.json({ success: true, message: 'Attendance record created' });
    } else {
      throw new Error('Failed to create attendance record');
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Instructor routes
router.get('/instructors', (req, res) => {
  const instructors = DataHandler.getInstructors();
  res.json(instructors);
});

router.post('/instructor/login', authLimiter, (req, res) => {
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
