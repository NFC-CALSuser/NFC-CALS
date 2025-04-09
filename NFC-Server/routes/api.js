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

// Get specific attendance record
router.get('/attendance/:id', (req, res) => {
  try {
    const { id } = req.params;
    const data = DataHandler.readData('attendance') || [];
    const record = data.find(r => r.id === id);
    
    if (record) {
      res.json(record);
    } else {
      res.status(404).json({ success: false, message: 'Record not found' });
    }
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
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
    const { status } = req.body;
    
    // 1. Get all required data
    const attendanceData = DataHandler.readData('attendance');
    let instructorViewData = DataHandler.readData('instructor_view');
    let studentsViewData = DataHandler.readData('students_view');
    
    // 2. Get the latest attendance record
    const record = attendanceData.find(r => r.id === id);
    if (!record || status !== 'ended') {
      return res.status(404).json({ message: 'Record not found or not ending' });
    }

    // 3. Extract data from record
    const courseId = record.course_id;
    const instructorId = record.instructor_id;
    const presentStudents = record.students_ids || [];
    
    // 4. Format date exactly like mark_absent.txt does
    const attendanceDate = record.date.split(' ')[0];
    const recordDate = new Date(attendanceDate);
    const formattedDate = `${String(recordDate.getDate()).padStart(2, '0')}-${String(recordDate.getMonth() + 1).padStart(2, '0')}-${recordDate.getFullYear()}`;

    // 5. Get enrolled students from instructor view
    const enrolledStudents = Object.keys(instructorViewData[instructorId].courses[courseId].students);
    const absentStudents = [];

    // 6. Update instructor view first
    enrolledStudents.forEach(studentId => {
      if (!presentStudents.includes(studentId)) {
        const student = instructorViewData[instructorId].courses[courseId].students[studentId];
        
        // Update percentage as mark_absent.txt does
        const currentPercentage = parseInt(student.current_percentage.replace('%', ''));
        const newPercentage = currentPercentage + 3;
        student.current_percentage = `${newPercentage}%`;
        
        // Add absence date exactly like mark_absent.txt
        if (!student.absence_dates) {
          student.absence_dates = [formattedDate];
        } else if (!student.absence_dates.includes(formattedDate)) {
          student.absence_dates.push(formattedDate);
        }
        
        absentStudents.push(studentId);
        console.log(`Marked student ${studentId} absent in instructor view`);
      }
    });

    // 7. Update students view exactly like mark_absent.txt
    studentsViewData.read_only.forEach(student => {
      if (!absentStudents.includes(student.student_id)) return;
      
      const course = student.courses.find(c => c.course === courseId);
      if (course) {
        const currentPercentage = parseInt(course.current_percentage.replace('%', ''));
        const newPercentage = currentPercentage + 3;
        course.current_percentage = `${newPercentage}%`;
        
        if (!course.absence_dates) {
          course.absence_dates = [formattedDate];
        } else if (!course.absence_dates.includes(formattedDate)) {
          course.absence_dates.push(formattedDate);
        }
        console.log(`Marked student ${student.student_id} absent in students view`);
      }
    });

    // 8. Save all updates
    record.status = 'ended';
    DataHandler.writeData('attendance', attendanceData);
    DataHandler.writeData('instructor_view', instructorViewData);
    DataHandler.writeData('students_view', studentsViewData);

    // 9. Return summary like mark_absent.txt
    res.json({
      success: true,
      summary: {
        totalEnrolled: enrolledStudents.length,
        presentCount: presentStudents.length,
        presentStudents: presentStudents,
        absentCount: absentStudents.length,
        absentStudents: absentStudents
      }
    });

  } catch (error) {
    console.error('Error processing session end:', error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// Update attendance route with validation
router.post('/attendance', [
  sanitizeInput,
  validateAttendanceData,
], async (req, res) => {
  try {
    const { id, course_id, classroom, date, instructor_id } = req.body;
    
    // Validate input types
    if (!id || typeof id !== 'string') {
      return res.status(400).json({ error: 'Invalid ID format' });
    }
    
    // Validate course_id format
    if (!(/^[A-Z]{3,4}\d{3}$/.test(course_id))) {
      return res.status(400).json({ error: 'Invalid course ID format' });
    }

    // Validate classroom format
    if (!(/^[A-Z]-\d{3}$/.test(classroom))) {
      return res.status(400).json({ error: 'Invalid classroom format' });
    }

    // Process validated data
    const result = await DataHandler.createAttendanceRecord({
      id,
      course_id,
      classroom,
      date,
      instructor_id,
      students_ids: []
    });

    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
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
